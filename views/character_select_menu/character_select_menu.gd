extends Control

const GAME_PLAY = preload('res://scenes/game_play/game_play.tscn')

@onready var character_list: ItemList = $VBoxContainer/HBoxContainer/CharacterList
@onready var instrument_list: ItemList = $VBoxContainer/InstrumentList
@onready var play_button: Button = $VBoxContainer/PlayButton

@export var midi_file: String
@export var instrument_codes: Array[int]


var selected_character := -1
var instrument_character_selection: Dictionary[int, Dictionary] = {}

const characters: Array[Dictionary] = [
	{
		'name': 'Poo Drummer',
		'instrument_code': 999-1
	},
	{
		'name': 'Boy on da Strings',
		'instrument_code': 51-1
	},
	{
		'name': 'Allbout Thatbass',
		'instrument_code': 88-1
	},
	{
		'name': 'Keys Likecocaine',
		'instrument_code': 5-1
	},
]


func _ready() -> void:
	for character in characters:
		var img := load("res://assets/cirlce.png")
		var instrument := Intruments.instruments[character['instrument_code'] + 1]
		var text := '{0} ({1})'.format([character['name'], instrument['name']])
		character_list.add_item(text, img)
		character_list.set_item_metadata(
			character_list.item_count - 1,
			{ 'character': character, 'instrument': instrument }
		)
	for code in instrument_codes:
		instrument_character_selection[code] = {}
		var instrument := Intruments.instruments[code + 1]
		var icon := load(Intruments.instrument_icons[instrument['type']])
		var text := '{0} ({1})'.format([
			instrument['name'],
			Intruments.INSTRUMENT_TYPE.find_key(instrument['type'])
		])
		instrument_list.add_item(text, icon, false)
		instrument_list.set_item_metadata(instrument_list.item_count - 1, instrument)


func _on_character_list_item_selected(index: int) -> void:
	if selected_character == index:
		character_list.deselect(index)
		selected_character = -1
	else:
		selected_character = index
	
	for instr_index in instrument_list.item_count:
		var matching: bool = selected_character != -1\
			and character_list.get_item_metadata(selected_character)['instrument']['type']\
				== instrument_list.get_item_metadata(instr_index)['type']
		instrument_list.set_item_custom_bg_color(
			instr_index,
			Color.WEB_GREEN if matching else Color.TRANSPARENT
		)
		instrument_list.set_item_selectable(instr_index, matching)


func _on_instrument_list_item_selected(index: int) -> void:
	if selected_character != -1:
		var char_icon = character_list.get_item_icon(selected_character)
		instrument_list.set_item_icon(index, char_icon)
		instrument_list.set_item_custom_bg_color(index, Color.TRANSPARENT)
		
		var metadata = character_list.get_item_metadata(selected_character)
		var instrument_code = metadata['character']['instrument_code']
		instrument_character_selection[instrument_code] = metadata['character']
		
		character_list.deselect(selected_character)
		selected_character = -1
		
	instrument_list.deselect(index)
	
	if instrument_character_selection.size() > 0:
		play_button.disabled = false


func _on_play_button_pressed() -> void:
	#prints(instrument_character_selection)
	var game_play_scene := GAME_PLAY.instantiate()
	game_play_scene.midi_file = midi_file
	game_play_scene.instrument_character_selection = instrument_character_selection
	get_tree().change_scene_to_node(game_play_scene)
