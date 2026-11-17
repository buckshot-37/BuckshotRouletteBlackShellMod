# Buckshot Roulette - Black Shell Mod installer / uninstaller
# Patches the Godot 4.1 PCK embedded in "Buckshot Roulette.exe":
#   * a script that fits into its original slot is overwritten in place
#   * a bigger script is appended to the end of the exe and its PCK
#     file-table entry (offset/size/md5) is repointed
# Nothing is moved, and the uninstaller restores the original table entries.

param(
    [Parameter(Mandatory = $true)][ValidateSet("patch", "uninstall", "find")][string]$Action,
    [string]$ExePath = "",
    [string]$Manifest = ""
)

$ErrorActionPreference = "Stop"

# md5 of the untouched 1.0.0 / v2.2.0.6 scripts; used to detect a different game build
$OriginalMd5 = @{
    "res://scripts/ShellSpawner.gd"        = "70742d6e12216bd647b90a13cea26281"
    "res://scripts/ShotgunShooting.gd"     = "de5cfa5ffa83e009b4e697a2ca9423dd"
    "res://scripts/DealerIntelligence.gd"  = "8b0cff33d674117a2c1652fb2dff0aa2"
    "res://scripts/ShellBranch.gd"         = "ae0d863f31d03c0eec02b065a85c8615"
    "res://scripts/ShellEjectManager.gd"   = "f929c6a3bc6ea21fd92f2f6667ee802e"
    "res://scripts/ShellExamine.gd"        = "c9a41cf784cdb51f3eeebf841eda9d69"
    "res://scripts/ItemInteraction.gd"     = "f2ef3c93a14d9bd2bac0ec7d7b55a952"
}

function Find-GameExe {
    $rel = "steamapps\common\Buckshot Roulette\Buckshot Roulette_windows\Buckshot Roulette.exe"
    $libraries = @()
    $steam = $null
    foreach ($key in @("HKCU:\Software\Valve\Steam", "HKLM:\SOFTWARE\WOW6432Node\Valve\Steam", "HKLM:\SOFTWARE\Valve\Steam")) {
        try {
            $k = Get-ItemProperty -Path $key -ErrorAction Stop
            if ($k.SteamPath) { $steam = $k.SteamPath } elseif ($k.InstallPath) { $steam = $k.InstallPath }
            if ($steam) { break }
        } catch { }
    }
    if ($steam) {
        $steam = $steam -replace "/", "\"
        $libraries += $steam
        $vdf = Join-Path $steam "steamapps\libraryfolders.vdf"
        if (Test-Path $vdf) {
            $txt = Get-Content -Path $vdf -Raw
            foreach ($m in [regex]::Matches($txt, '"path"\s*"([^"]+)"')) {
                $p = $m.Groups[1].Value -replace "\\\\", "\"
                if ($p -and ($libraries -notcontains $p)) { $libraries += $p }
            }
        }
    }
    foreach ($lib in $libraries) {
        $candidate = Join-Path $lib $rel
        if (Test-Path -LiteralPath $candidate) { return (Resolve-Path -LiteralPath $candidate).Path }
    }
    foreach ($drive in @("C:", "D:", "E:", "F:", "G:")) {
        foreach ($sub in @("\Steam", "\Program Files (x86)\Steam", "\SteamLibrary", "\Games\Steam")) {
            $candidate = "$drive$sub\$rel"
            if (Test-Path -LiteralPath $candidate) { return (Resolve-Path -LiteralPath $candidate).Path }
        }
    }
    return $null
}

function Resolve-ExePath([string]$p) {
    if ([string]::IsNullOrWhiteSpace($p)) {
        $found = Find-GameExe
        if (-not $found) { throw "Could not locate the game automatically. Drag the folder that contains 'Buckshot Roulette.exe' onto install.bat, or pass it as an argument." }
        return $found
    }
    $p = $p.Trim('"')
    if (Test-Path -LiteralPath $p -PathType Container) {
        foreach ($sub in @("Buckshot Roulette.exe", "Buckshot Roulette_windows\Buckshot Roulette.exe")) {
            $c = Join-Path $p $sub
            if (Test-Path -LiteralPath $c) { return (Resolve-Path -LiteralPath $c).Path }
        }
        throw "No 'Buckshot Roulette.exe' inside: $p"
    }
    if (Test-Path -LiteralPath $p -PathType Leaf) { return (Resolve-Path -LiteralPath $p).Path }
    throw "Path not found: $p"
}

function Read-Table($br, [long]$pckOff) {
    $br.BaseStream.Position = $pckOff
    $magic = $br.ReadBytes(4)
    if ([System.Text.Encoding]::ASCII.GetString($magic) -ne "GDPC") { throw "PCK magic not found." }
    $ver = $br.ReadUInt32(); $null = $br.ReadUInt32(); $null = $br.ReadUInt32(); $null = $br.ReadUInt32()
    $flags = $br.ReadUInt32()
    $fileBase = $br.ReadUInt64()
    $null = $br.ReadBytes(64)
    $count = $br.ReadUInt32()
    $entries = @{}
    for ($i = 0; $i -lt $count; $i++) {
        $len = $br.ReadUInt32()
        $raw = $br.ReadBytes($len)
        $path = [System.Text.Encoding]::UTF8.GetString($raw)
        $z = $path.IndexOf([char]0)
        if ($z -ge 0) { $path = $path.Substring(0, $z) }
        $recOff = $br.BaseStream.Position
        $off = $br.ReadUInt64()
        $size = $br.ReadUInt64()
        $md5Pos = $br.BaseStream.Position
        $md5Bytes = $br.ReadBytes(16)
        $entryFlags = $br.ReadUInt32()
        $entries[$path] = [pscustomobject]@{
            Offset = $off; Size = $size; RecOff = $recOff; Md5Pos = $md5Pos; Flags = $entryFlags
            Md5 = (([BitConverter]::ToString($md5Bytes)) -replace "-", "").ToLower()
        }
    }
    return [pscustomobject]@{ FileBase = $fileBase; Count = $count; Entries = $entries; PckOff = $pckOff }
}

function Find-PckOffset($br) {
    $br.BaseStream.Position = 0x3C
    $pe = $br.ReadUInt32()
    $br.BaseStream.Position = $pe
    $sig = $br.ReadBytes(4)
    if ([System.Text.Encoding]::ASCII.GetString($sig) -ne "PE`0`0") { throw "Not a PE executable." }
    $br.BaseStream.Position = $pe + 6
    $nsec = $br.ReadUInt16()
    $br.BaseStream.Position = $pe + 20
    $opt = $br.ReadUInt16()
    $br.BaseStream.Position = $pe + 24 + $opt
    for ($i = 0; $i -lt $nsec; $i++) {
        $h = $br.ReadBytes(40)
        $name = [System.Text.Encoding]::ASCII.GetString($h, 0, 8).TrimEnd([char]0)
        if ($name -eq "pck") { return [long][BitConverter]::ToUInt32($h, 20) }
    }
    throw "PE section 'pck' not found - unsupported game build."
}

function Get-Md5Hex($data) {
    $md5 = [System.Security.Cryptography.MD5]::Create()
    return (([BitConverter]::ToString($md5.ComputeHash($data))) -replace "-", "").ToLower()
}

$root = Split-Path -Parent $MyInvocation.MyCommand.Path

if ($Action -eq "find") {
    $found = Find-GameExe
    if ($found) { Write-Host $found; exit 0 } else { Write-Host "not found"; exit 1 }
}

if ($Action -eq "patch") {
    $exe = Resolve-ExePath $ExePath
    Write-Host "Game exe: $exe"
    $scriptDir = Join-Path $root "mod\scripts"
    if (-not (Test-Path $scriptDir)) { throw "mod\scripts not found next to the installer." }
    if ([string]::IsNullOrEmpty($Manifest)) { $Manifest = Join-Path $root "install_backup.json" }

    if (Get-Process -Name "Buckshot Roulette" -ErrorAction SilentlyContinue) {
        throw "The game is running. Close it completely, then run the installer again."
    }

    try {
        $fs = [System.IO.File]::Open($exe, [System.IO.FileMode]::Open, [System.IO.FileAccess]::ReadWrite, [System.IO.FileShare]::Read)
    } catch {
        throw "Cannot write to the game executable - it is most likely still running. Close the game completely and try again."
    }
    $br = New-Object System.IO.BinaryReader($fs)
    $bw = New-Object System.IO.BinaryWriter($fs)
    try {
        $pckOff = Find-PckOffset $br
        $table = Read-Table $br $pckOff
        $fileBase = [long]$table.FileBase

        # ---- classify every target against the untouch, the mod, or something unknown ----
        $plan = @()
        $already = 0
        $unknown = @()
        foreach ($f in (Get-ChildItem $scriptDir -Filter *.gd | Sort-Object Name)) {
            $res = "res://scripts/" + $f.Name
            if (-not $table.Entries.ContainsKey($res)) { throw "PCK entry not found: $res" }
            $e = $table.Entries[$res]
            $data = [System.IO.File]::ReadAllBytes($f.FullName)
            $modMd5 = Get-Md5Hex $data
            $expected = $OriginalMd5[$res]
            if ($e.Md5 -eq $modMd5) {
                $already++
                continue
            }
            if ($expected -and $e.Md5 -ne $expected) {
                $unknown += ("{0} (found md5 {1}, expected {2})" -f $f.Name, $e.Md5, $expected)
                continue
            }
            $plan += [pscustomobject]@{ File = $f; Res = $res; Entry = $e; Data = $data; Md5 = $modMd5 }
        }
        if ($unknown.Count -gt 0) {
            throw ("These game scripts are from a different game version:`n  " + ($unknown -join "`n  ") + "`n`nThis mod was built for Buckshot Roulette v2.2.0.6 / build 16736575. Update or reinstall the game, then try again.")
        }
        if ($plan.Count -eq 0) {
            Write-Host "Mod is already installed - nothing to do."
            exit 0
        }

        $fs.Position = $fs.Length
        $appendPos = $fs.Length
        $originalSize = $appendPos
        $backup = [pscustomobject]@{ exe = $exe; original_size = $originalSize; files = @() }
        $files = @()

        foreach ($item in $plan) {
            $e = $item.Entry
            $data = $item.Data
            $newOffForRecord = [uint64]$e.Offset
            if ($data.Length -le $e.Size) {
                $fs.Position = $fileBase + [long]$e.Offset
                $fs.Write($data, 0, $data.Length)
                $fs.Position = [long]$e.RecOff + 8
                $bw.Write([uint64]$data.Length)
                $fs.Position = [long]$e.Md5Pos
                $fs.Write([byte[]](0..15 | ForEach-Object { [Convert]::ToByte($item.Md5.Substring($_ * 2, 2), 16) }), 0, 16)
                Write-Host ("  {0,-26} in-place  {1} bytes" -f $item.File.Name, $data.Length)
            } else {
                $newOff = [uint64]($appendPos - $fileBase)
                $newOffForRecord = $newOff
                $fs.Position = $appendPos
                $fs.Write($data, 0, $data.Length)
                $pad = (4 - ($data.Length % 4)) % 4
                if ($pad -gt 0) { $fs.Write((New-Object byte[] $pad), 0, $pad) }
                $appendPos += $data.Length + $pad
                $fs.Position = [long]$e.RecOff
                $bw.Write($newOff)
                $bw.Write([uint64]$data.Length)
                $fs.Position = [long]$e.Md5Pos
                $fs.Write([byte[]](0..15 | ForEach-Object { [Convert]::ToByte($item.Md5.Substring($_ * 2, 2), 16) }), 0, 16)
                Write-Host ("  {0,-26} appended  {1} bytes (was {2})" -f $item.File.Name, $data.Length, $e.Size)
            }
            $files += [pscustomobject]@{
                path = $item.Res
                off = $e.Offset; size = $e.Size; md5 = $e.Md5
                md5_pos = $e.Md5Pos; rec_off = $e.RecOff
                new_off = $newOffForRecord; new_size = [uint64]$data.Length; new_md5 = $item.Md5
            }
        }
        $fs.Flush($true)

        # ---- read the table back and confirm every entry now points at the mod ----
        $table2 = Read-Table $br $pckOff
        $bad = 0
        foreach ($item in $plan) {
            $e2 = $table2.Entries[$item.Res]
            $fs.Position = $fileBase + [long]$e2.Offset
            $check = $br.ReadBytes([int]$e2.Size)
            if ((Get-Md5Hex $check) -ne $item.Md5) { $bad++ }
        }
        if ($bad -gt 0) { throw "Verification failed for $bad file(s); run uninstall.bat or verify game files in Steam." }

        $backup.files = $files
        $backup | ConvertTo-Json -Depth 5 | Set-Content -Path $Manifest -Encoding UTF8
        Write-Host ""
        Write-Host ("Installed {0} script(s). Executable grew by {1} bytes. Verified OK." -f $plan.Count, ($appendPos - $originalSize))
        if ($already -gt 0) { Write-Host ("({0} script(s) were already patched.)" -f $already) }
    } finally {
        $bw.Dispose(); $br.Dispose(); $fs.Dispose()
    }
}
elseif ($Action -eq "uninstall") {
    $exe = Resolve-ExePath $ExePath
    if ([string]::IsNullOrEmpty($Manifest) -or -not (Test-Path $Manifest)) {
        throw "Backup manifest not found. Use Steam 'Verify integrity of game files' instead."
    }
    if (Get-Process -Name "Buckshot Roulette" -ErrorAction SilentlyContinue) {
        throw "The game is running. Close it completely, then run the uninstaller again."
    }
    $b = Get-Content $Manifest -Raw | ConvertFrom-Json
    try {
        $fs = [System.IO.File]::Open($exe, [System.IO.FileMode]::Open, [System.IO.FileAccess]::ReadWrite, [System.IO.FileShare]::Read)
    } catch {
        throw "Cannot write to the game executable - it is most likely still running. Close the game completely and try again."
    }
    $br = New-Object System.IO.BinaryReader($fs)
    $bw = New-Object System.IO.BinaryWriter($fs)
    try {
        # safety: only restore if the slots still hold exactly what the installer wrote
        $pckOff = Find-PckOffset $br
        $table = Read-Table $br $pckOff
        $mismatch = @()
        foreach ($item in $b.files) {
            if (-not $table.Entries.ContainsKey([string]$item.path)) { $mismatch += $item.path; continue }
            $cur = $table.Entries[[string]$item.path]
            if ($null -eq $item.new_md5) { continue }
            if ($cur.Md5 -ne [string]$item.new_md5) { $mismatch += $item.path }
        }
        if ($mismatch.Count -gt 0) {
            throw ("The game files do not match this installation record:`n  " + ($mismatch -join "`n  ") + "`n`nNothing was changed. The game was probably updated/reinstalled - just run install.bat again, or use Steam 'Verify integrity of game files'.")
        }
        foreach ($item in $b.files) {
            $fs.Position = [long]$item.rec_off
            $bw.Write([uint64]$item.off)
            $bw.Write([uint64]$item.size)
            $fs.Position = [long]$item.md5_pos
            $hex = [string]$item.md5
            $bytes = New-Object byte[] 16
            for ($k = 0; $k -lt 16; $k++) { $bytes[$k] = [Convert]::ToByte($hex.Substring($k * 2, 2), 16) }
            $fs.Write($bytes, 0, 16)
        }
        $fs.Flush($true)
        Write-Host ("Restored {0} PCK entr(ies)." -f $b.files.Count)
    } finally {
        $bw.Dispose(); $br.Dispose(); $fs.Dispose()
    }
}

