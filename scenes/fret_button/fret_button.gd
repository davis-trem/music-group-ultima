extends Node3D

@onready var model: Node3D = $Model
@onready var mesh_instance_3d_2: MeshInstance3D = $Model/MeshInstance3D2

@export var lane_index: int
@export_color_no_alpha var button_color: Color

var note_in_range: Note

func  _ready() -> void:
	var material: StandardMaterial3D = mesh_instance_3d_2.get_active_material(0)
	material.albedo_color = button_color


func _input(event: InputEvent) -> void:
	var action := 'fret_button_{0}'.format([lane_index + 1])
	if event.is_action_pressed(action):
		var tween := create_tween()
		tween.tween_property(
			model,
			'position',
			Vector3(model.position.x, -0.06, model.position.z),
			0.1
		)
		
		if note_in_range and not note_in_range.note_played:
			note_in_range.note_played = true
			GameStats.update_player_rating(note_in_range.player, 1)
		
	if event.is_action_released(action):
		var tween := create_tween()
		tween.tween_property(
			model,
			'position',
			Vector3(model.position.x, 0, model.position.z),
			0.1
		)


func _on_area_3d_area_entered(area: Area3D) -> void:
	var parent = area.get_parent_node_3d()
	if is_instance_of(parent, Note) and lane_index == parent.lane_index:
		note_in_range = parent


func _on_area_3d_area_exited(area: Area3D) -> void:
	var parent = area.get_parent_node_3d()
	if is_instance_of(parent, Note) and lane_index == parent.lane_index:
		if note_in_range == parent:
			note_in_range = null
