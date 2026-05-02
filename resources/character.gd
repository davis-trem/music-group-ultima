class_name Character
extends Resource

@export var name: String
@export var instrument_code: int
@export var instrument_name: String
@export var instrument_type: Instruments.INSTRUMENT_TYPE
@export var sprite: String
@export var modulate_color: Color

var placeholder_sprite := 'res://sprites/placeholder_character.png'


func _init(n: String, instr_code: int) -> void:
	name = n
	instrument_code = instr_code
	var instrument: Dictionary = Instruments.instruments[instr_code]
	instrument_type = instrument['type']
	instrument_name = instrument['name']
	sprite = placeholder_sprite
	modulate_color = Color(randf(), randf(), randf())
