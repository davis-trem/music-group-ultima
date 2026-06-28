extends Node

var crowd_favor: float = 50.0
var characters_rating: Dictionary[Character, float] = {}
var min_note_count: int = 999999
var value_change_rate: float = 1.0

var characters: Array[Character] = []

# { instrument_code: int, character: Character, note_count: int, rating: float }[]
class PlayerPosition:
	var instrument_code: int
	var character: Character
	var note_count: int
	var rating: float
	var power_value: float
	func _init(
		_instrument_code: int,
		_character: Character,
		_note_count: int,
		_rating: float,
		_power_value: float
	) -> void:
		instrument_code = _instrument_code
		character = _character
		note_count = _note_count
		rating = _rating
		power_value = _power_value

var playing_positions: Array[PlayerPosition] = []

const power_bar_cost := 25.0

signal game_finished(success: bool)
signal rating_updated(position_index: int, rating: float, power_value: float)

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

func reset_game(playing_positions_details: Array[Dictionary]) -> void:
	crowd_favor = 50.0
	min_note_count = 999999
	playing_positions = []
	for detail in playing_positions_details:
		min_note_count = min(min_note_count, detail['note_count'])
		playing_positions.append(PlayerPosition.new(
			detail['instrument_code'],
			detail['character'],
			detail['note_count'],
			50.0,
			0.0
		))
	value_change_rate = 100.0 / float(min_note_count)

func update_position_rating(position_index: int, play_attempt: Note.PlayAttempt) -> void:
	var play_attempt_change := 1.0
	match play_attempt:
		Note.PlayAttempt.Early, Note.PlayAttempt.Late:
			play_attempt_change = 0.7
		Note.PlayAttempt.Perfect:
			play_attempt_change = 1.0
		Note.PlayAttempt.Missed, _:
			play_attempt_change = (
				-0.5 if playing_positions[position_index].character == null
				else -1.0
			)
	var adjusted_change := play_attempt_change * value_change_rate * (
		float(min_note_count) / float(playing_positions[position_index].note_count)
	)
	playing_positions[position_index].rating = clampf(
		playing_positions[position_index].rating + adjusted_change,
		0.0,
		100.0
	)
	
	if adjusted_change > 0:
		playing_positions[position_index].power_value = clampf(
			playing_positions[position_index].power_value + adjusted_change,
			0.0,
			50.0
		)
	
	adjust_crowd_favor_from_ratings()
	
	rating_updated.emit(
		position_index,
		playing_positions[position_index].rating,
		playing_positions[position_index].power_value
	)


func adjust_crowd_favor_from_ratings() -> void:
	var new_crowd_favor: float = playing_positions.reduce(
		func(sum, pos): return sum + pos.rating, 0
	) / playing_positions.size()
	crowd_favor = clampf(new_crowd_favor, 0.0, 100.0)
	if crowd_favor <= 5 or crowd_favor >= 95:
		game_finished.emit(crowd_favor >= 95)


func activate_power_move(position_index: int):
	playing_positions[position_index].power_value = clamp(
			playing_positions[position_index].power_value - power_bar_cost,
			0.0,
			50.0
		)
	PowerMoves.power_move_functions[
		playing_positions[position_index].character.power_move
	].call(position_index)
	rating_updated.emit(
		position_index,
		playing_positions[position_index].rating,
		playing_positions[position_index].power_value
	)
