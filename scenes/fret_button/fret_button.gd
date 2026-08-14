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


func _handle_button_pressed() -> void:
	var material: StandardMaterial3D = mesh_instance_3d_2.get_active_material(0)
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
		if dist_from_goal > 0.2:
			note_in_range.play_attempt = Note.PlayAttempt.Early
		elif dist_from_goal < -0.2:
			note_in_range.play_attempt = Note.PlayAttempt.Late
		else:
			note_in_range.play_attempt = Note.PlayAttempt.Perfect
		
		note_in_range.note_played = true
		GameStats.update_position_rating(
			note_in_range.playing_position_index,
			note_in_range.play_attempt,
		)
	else:
		tween.tween_property(
			material,
			'albedo_color',
			Color.DARK_RED,
			0.1
		)


func _handle_button_released() -> void:
	var material: StandardMaterial3D = mesh_instance_3d_2.get_active_material(0)
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
			GameStats.update_position_rating(
				note_in_range.playing_position_index,
				Note.PlayAttempt.Missed,
			)


func _input(event: InputEvent) -> void:
	if button_is_disabled:
		return
	var action := 'fret_button_{0}'.format([lane_index + 1])
	if event.is_action_pressed(action):
		_handle_button_pressed()
		
	if event.is_action_released(action):
		_handle_button_released()


func _on_area_3d_area_entered(area: Area3D) -> void:
	var parent = area.get_parent_node_3d()
	if is_instance_of(parent, Note) and lane_index == parent.lane_index:
		note_in_range = parent


func _on_area_3d_area_exited(area: Area3D) -> void:
	var parent = area.get_parent_node_3d()
	if is_instance_of(parent, Note) and lane_index == parent.lane_index:
		if note_in_range == parent:
			note_in_range = null

func _on_area_3d_input_event(_camera: Node, event: InputEvent) -> void:
	if button_is_disabled:
		return
	
	# 1. Handle Mouse Clicks exclusively
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_handle_button_pressed()
			else:
				_handle_button_released()
	# 2. Handle Touchscreen Taps exclusively
	elif event is InputEventScreenTouch:
		if event.pressed:
			_handle_button_pressed()
		else:
			_handle_button_released()
