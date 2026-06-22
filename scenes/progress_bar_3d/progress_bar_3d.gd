extends Node3D
class_name ProgressBar3D

@onready var fill_mesh: MeshInstance3D = $FillMesh
@onready var outline_mesh: MeshInstance3D = $FillMesh/OutlineMesh

@export var min_value := 0.0
@export var max_value := 100.0
@export var value := 0.0: set = _set_value
@export var fill_color: Color = Color(0.0, 0.8, 1.0)

signal bar_filled


func _set_value(val: float) -> void:
	value = clamp(val, min_value, max_value)
	if fill_mesh:
		_update_fill_color(value)


func _update_fill_color(val: float) -> void:
	fill_mesh.set_instance_shader_parameter('min_value', min_value)
	fill_mesh.set_instance_shader_parameter('max_value', max_value)
	fill_mesh.set_instance_shader_parameter('fill_color', fill_color)
	fill_mesh.set_instance_shader_parameter('value', val)
	
	var outline_material = outline_mesh.get_active_material(0) as StandardMaterial3D
	if val == max_value:
		outline_material.albedo_color = fill_color
		bar_filled.emit()
	else:
		outline_material.albedo_color = Color.WHITE
