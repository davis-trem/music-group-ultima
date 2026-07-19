extends "res://scenes/game_play/game_play.gd"

func _ready() -> void:
	super()
	midi_player.loop = true

func _process(_delta: float) -> void:
	super(_delta)
	if midi_player.position >= 3071:
		midi_player.seek(0)
