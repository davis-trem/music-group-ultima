extends Control

@onready var texture_rect: TextureRect = $TextureRect

@export var instrument_code: int
@export var playing_position_index: int

func _ready() -> void:
	var instrument_type = Instruments.instruments[instrument_code]['type']
	var sprite = Instruments.instrument_icons[instrument_type]
	texture_rect.texture = load(sprite)
	
	_move_by_percentage(0.5)


func _process(_delta: float) -> void:
	_move_by_percentage(GameStats.playing_positions[playing_position_index]['rating'] / 100)


func _move_by_percentage(value: float) -> void:
	var progress_bar: ProgressBar = get_parent()
	position.x = (progress_bar.size.x * clampf(value, 0.0, 1.0)) - (size.x / 2)
