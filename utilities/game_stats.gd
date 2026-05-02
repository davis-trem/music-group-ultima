extends Node

var crowd_favor: float = 50.0
var characters_rating: Dictionary[Character, float] = {}

var characters: Array[Character] = []

var playing_positions: Array[Dictionary] = []

func _ready() -> void:
	var demo_characters := [
		{
			'name': 'Poo Drummer',
			'instrument_code': 999
		},
		{
			'name': 'Boy on da Strings',
			'instrument_code': 50
		},
		{
			'name': 'Allbout Thatbass',
			'instrument_code': 87
		},
		{
			'name': 'Keys Likecocaine',
			'instrument_code': 4
		},
	]
	for ch in demo_characters:
		var character := Character.new(
			ch['name'],
			ch['instrument_code']
		)
		characters.append(character)

func reset_game(instrument_character_selection: Dictionary[int, Character]) -> void:
	crowd_favor = 50.0
	for code in instrument_character_selection:
		playing_positions.append({
			'instrument_code': code,
			'character': instrument_character_selection[code],
			'rating': 50.0
		})

func update_position_rating(position_index: int, change: float) -> void:
	playing_positions[position_index]['rating'] += change
	crowd_favor = playing_positions.reduce(
		func(sum, pos): return sum + pos['rating'], 0
	) / playing_positions.size()
