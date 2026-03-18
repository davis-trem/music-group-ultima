extends Node3D

class_name Note

@onready var meshInstance: MeshInstance3D = $Mesh
@onready var collision_shape_3d: CollisionShape3D = $Area3D/CollisionShape3D
@onready var gpu_particles_3d: GPUParticles3D = $GPUParticles3D

var player: int
var midi_player: MidiPlayer
var distance_total_to_goal: float
var lane_index: int
var tick := 0

var note_played := false: set = _set_note_played

func _ready() -> void:
	var color = ColorsUtil.LANE_COLORS[lane_index]
	set_color(color)
	


func _process(delta: float) -> void:
	if midi_player.playing and not note_played:
		position.z = (
			(midi_player.position - tick) / midi_player.smf_data.timebase * distance_total_to_goal
		) - meshInstance.mesh.height


func set_size(value: float) -> void:
	(meshInstance.mesh as CapsuleMesh).height = value


func set_color(color: Color) -> void:
	(meshInstance.get_active_material(0) as StandardMaterial3D).albedo_color = color


func _set_note_played(value: bool) -> void:
	note_played = value
	if value == true:
		meshInstance.hide()
		gpu_particles_3d.emitting = true


func _on_gpu_particles_3d_finished() -> void:
	queue_free()
