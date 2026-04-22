extends Node3D

@onready var model: Node3D = $Model
@onready var mesh_instance_3d_2: MeshInstance3D = $Model/MeshInstance3D2

@export var lane_index: int
@export_color_no_alpha var button_color: Color

var note_in_range: Note
var button_is_disabled := false: set = _set_button_is_disabled

func  _ready() -> void:
	var material: StandardMaterial3D = mesh_instance_3d_2.get_active_material(0)
	material.albedo_color = button_color


func _set_button_is_disabled(value: bool) -> void:
	button_is_disabled = value
	var material: StandardMaterial3D = mesh_instance_3d_2.get_active_material(0)
	material.albedo_color = Color.DARK_GRAY if button_is_disabled else button_color


func _input(event: InputEvent) -> void:
	if button_is_disabled:
		return
	var action := 'fret_button_{0}'.format([lane_index + 1])
	var material: StandardMaterial3D = mesh_instance_3d_2.get_active_material(0)
	if event.is_action_pressed(action):
		var tween := create_tween()
		tween.tween_property(
			model,
			'position',
			Vector3(model.position.x, -0.06, model.position.z),
			0.1
		)
		
		# Played note
		if note_in_range and not note_in_range.note_played:
			var dist_from_goal := global_position.z - note_in_range.global_position.z
			var points := 1.0
			if dist_from_goal > 0.2:
				note_in_range.play_attempt = Note.PlayAttempt.Early
				points = 0.7
			elif dist_from_goal < -0.2:
				note_in_range.play_attempt = Note.PlayAttempt.Late
				points = 0.7
			else:
				note_in_range.play_attempt = Note.PlayAttempt.Perfect
			
			note_in_range.note_played = true
			GameStats.update_player_rating(note_in_range.character, points)
		else:
			tween.tween_property(
				material,
				'albedo_color',
				Color.DARK_RED,
				0.1
			)
		
	if event.is_action_released(action):
		var tween := create_tween()
		tween.tween_property(
			model,
			'position',
			Vector3(model.position.x, 0, model.position.z),
			0.1
		)
		if material.albedo_color != button_color:
			tween.tween_property(
				material,
				'albedo_color',
				button_color,
				0.1
			)
			if note_in_range:
				GameStats.update_player_rating(note_in_range.character, -1.0)


func _on_area_3d_area_entered(area: Area3D) -> void:
	var parent = area.get_parent_node_3d()
	if is_instance_of(parent, Note) and lane_index == parent.lane_index:
		note_in_range = parent


func _on_area_3d_area_exited(area: Area3D) -> void:
	var parent = area.get_parent_node_3d()
	if is_instance_of(parent, Note) and lane_index == parent.lane_index:
		if note_in_range == parent:
			note_in_range = null
