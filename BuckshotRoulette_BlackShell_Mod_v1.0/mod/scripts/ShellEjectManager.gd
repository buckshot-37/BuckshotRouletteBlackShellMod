class_name ShellEjectManager extends Node

@export var mesh : MeshInstance3D
@export var shellSpawner : ShellSpawner
@export var mat_blank : StandardMaterial3D
@export var mat_live : StandardMaterial3D
@export var mat_brass : StandardMaterial3D
@export var animator : AnimationPlayer
@export var animator_fader : AnimationPlayer
@export var isDealerSide : bool
@export var smoke : SmokeController
@export var ai : DealerIntelligence

var hasFaded = false
var mat_black : StandardMaterial3D

func _ready():
	mesh.set_surface_override_material(0, mat_brass)
	if (GlobalVariables.colorblind): mat_live.albedo_color = GlobalVariables.colorblind_color_live; mat_blank.albedo_color = GlobalVariables.colorblind_color_blank
	else: mat_live.albedo_color = GlobalVariables.default_color_live; mat_blank.albedo_color = GlobalVariables.default_color_blank

# BLACK SHELL MOD: pick the right shell material for the ejected shell.
func GetCurrentShellMaterial() -> StandardMaterial3D:
	var shellState = shellSpawner.sequenceArray[0]
	if (shellState == "live"): return mat_live
	if (shellState == "black"):
		if (mat_black == null):
			mat_black = mat_live.duplicate() as StandardMaterial3D
			mat_black.albedo_color = Color(0.02, 0.02, 0.02)
			mat_black.emission_enabled = false
		return mat_black
	return mat_blank

func EjectShell():
	shellSpawner.roundManager.playerData.stat_shellsEjected += 1
	animator_fader.play("RESET")
	mesh.set_surface_override_material(1, GetCurrentShellMaterial())
	mesh.visible = true
	if(!isDealerSide): animator.play("ejecting shell_player1")
	else: animator.play("eject shell")
	if (shellSpawner.sequenceArray[0] != "blank"):
		smoke.SpawnSmoke("chamber")
	shellSpawner.sequenceArray.remove_at(0)
	ai.sequenceArray_knownShell.remove_at(0)
	hasFaded = false
	pass

func BeerEjection_player():
	shellSpawner.roundManager.playerData.stat_shellsEjected += 1
	animator_fader.play("RESET")
	mesh.set_surface_override_material(1, GetCurrentShellMaterial())
	mesh.visible = true
	animator.play("ejecting shell_player1")
	shellSpawner.sequenceArray.remove_at(0)
	ai.sequenceArray_knownShell.remove_at(0)
	hasFaded = false
	pass

func BeerEjection_dealer():
	shellSpawner.roundManager.playerData.stat_shellsEjected += 1
	animator_fader.play("RESET")
	mesh.set_surface_override_material(1, GetCurrentShellMaterial())
	mesh.visible = true
	animator.play("eject shell beer")
	shellSpawner.sequenceArray.remove_at(0)
	ai.sequenceArray_knownShell.remove_at(0)
	hasFaded = false
	pass

func DeathEjection():
	animator_fader.play("RESET")
	mesh.set_surface_override_material(1, GetCurrentShellMaterial())
	mesh.visible = true
	if(!isDealerSide): animator.play("ejecting shell_player1")
	else: animator.play("eject shell")
	if (shellSpawner.sequenceArray[0] != "blank"):
		smoke.SpawnSmoke("chamber")
	shellSpawner.sequenceArray.remove_at(0)
	ai.sequenceArray_knownShell.remove_at(0)
	hasFaded = false
	pass

func FadeOutShell():
	if(!hasFaded):
		animator_fader.play("fade out shell")
		hasFaded = true
