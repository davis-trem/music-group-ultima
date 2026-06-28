extends Node

class_name PowerMoves

enum PowerMoveKey {
	INCREASE_POWER_PLAYER_RATING_BY_10_PERCENT,
	#INCREASE_RANDOM_PLAYER_RATING_BY_10_PERCENT,
	#STAGGER_POWER_PLAYERS_OPPONENT,
	#STAGGER_RANDOM_OPPONENT,
}

static var power_move_functions: Dictionary[PowerMoveKey, Callable] = {
	PowerMoveKey.INCREASE_POWER_PLAYER_RATING_BY_10_PERCENT: PowerMoves._increase_power_player_rating_by_10_percent
}

static func _increase_power_player_rating_by_10_percent(position_index: int) -> void:
	GameStats.playing_positions[position_index].rating = clampf(
		GameStats.playing_positions[position_index].rating + 10,
		0.0,
		100.0
	)
	GameStats.adjust_crowd_favor_from_ratings()
