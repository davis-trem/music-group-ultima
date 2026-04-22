extends TextureProgressBar

@export var instrument_type: Intruments.INSTRUMENT_TYPE
@export var instrument_name: String

@onready var texture_rect: TextureRect = $TextureRect

func _ready() -> void:
	var icon := load(Intruments.instrument_icons[instrument_type])
	texture_rect.texture = icon
	tooltip_text = instrument_name
