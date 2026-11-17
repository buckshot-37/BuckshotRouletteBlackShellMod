class_name ShellClass extends Node

@export var isLive : bool
@export var mat_live : StandardMaterial3D
@export var mat_blank : StandardMaterial3D
@export var mesh : MeshInstance3D

# BLACK SHELL MOD: third shell type, drawn with a runtime darkened duplicate
# of the live shell material (no texture / asset is modified).
var isBlack : bool = false
var mat_black : StandardMaterial3D

func _ready():
	pass

func _process(delta):
	pass

func GetBlackMaterial() -> StandardMaterial3D:
	if (mat_black == null):
		if (mat_live != null):
			mat_black = mat_live.duplicate() as StandardMaterial3D
		else:
			mat_black = StandardMaterial3D.new()
		mat_black.albedo_color = Color(0.02, 0.02, 0.02)
		mat_black.emission_enabled = false
	return mat_black

func ApplyStatus():
	if (isBlack):
		mesh.set_surface_override_material(1, GetBlackMaterial())
	elif (isLive):
		mesh.set_surface_override_material(1, mat_live)
	else:
		mesh.set_surface_override_material(1, mat_blank)
	pass
