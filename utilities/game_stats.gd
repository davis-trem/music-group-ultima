extends Node

var crowd_favor: float = 50
var players_rating: Dictionary[int, float] = {}

func reset_ratings(instrument_codes: Array[int]) -> void:
	crowd_favor = 50
	for code in instrument_codes:
		players_rating[code] = 100

func update_player_rating(player: int, change: float) -> void:
	players_rating[player] += change
	crowd_favor += change / players_rating.size()
