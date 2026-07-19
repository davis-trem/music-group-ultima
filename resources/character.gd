class_name Character
extends Resource

@export var name: String
@export var instrument_code: int: set = _set_instrument_info
@export var instrument_name: String
@export var instrument_type: Instruments.INSTRUMENT_TYPE
@export var power_move: PowerMoves.PowerMoveKey
@export var sprite: String
@export var modulate_color: Color

var placeholder_sprite := 'res://sprites/placeholder_character.png'

 
func _init(n: String = 'Player Name', instr_code: int = 0) -> void:
	name = n
	_set_instrument_info(instr_code)
	power_move = PowerMoves.PowerMoveKey.values().pick_random()
	sprite = placeholder_sprite
	modulate_color = Color(randf(), randf(), randf())

func _set_instrument_info(instr_code: int) -> void:
	instrument_code = instr_code
	var instrument: Dictionary = Instruments.instruments[instr_code]
	instrument_type = instrument['type']
	instrument_name = instrument['name']
