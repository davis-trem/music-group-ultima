extends Node3D

class_name Note

@onready var meshInstance: MeshInstance3D = $Mesh
@onready var collision_shape_3d: CollisionShape3D = $Area3D/CollisionShape3D
@onready var gpu_particles_3d: GPUParticles3D = $GPUParticles3D
@onready var play_attempt_label_3d: Label3D = $PlayAttemptLabel3D

enum PlayAttempt { Early, Perfect, Late } 

var player: int
var midi_player: MidiPlayer
var lane_index: int
var spawned_tick: int
var start_pos: Vector3
var goal_pos: Vector3
var play_attempt: PlayAttempt
var tick := 0

var note_played := false: set = _set_note_played

func _ready() -> void:
	var color = ColorsUtil.LANE_COLORS[lane_index]
	set_color(color)
	position = start_pos
	

func _process(_delta: float) -> void:
	if midi_player.playing and not note_played:
		var direction = goal_pos.z - start_pos.z
		var duration = tick - spawned_tick

		var velocity_per_tick = direction / duration

		var offset_ticks = midi_player.position - tick

		position.z = goal_pos.z + velocity_per_tick * offset_ticks


func set_size(value: float) -> void:
	(meshInstance.mesh as CapsuleMesh).height = value


func set_color(color: Color) -> void:
	(meshInstance.get_active_material(0) as StandardMaterial3D).albedo_color = color


func _set_note_played(value: bool) -> void:
	note_played = value
	if value == true:
		meshInstance.hide()
		play_attempt_label_3d.text = PlayAttempt.find_key(play_attempt)
		play_attempt_label_3d.show()
		gpu_particles_3d.emitting = true


func _on_gpu_particles_3d_finished() -> void:
	queue_free()
