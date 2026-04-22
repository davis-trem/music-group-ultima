extends PanelContainer

const INSTRUMENT_NOTES_AMOUNT = preload("uid://d1ewcxxw37u5n")
const CHARACTER_SELECT_MENU = preload("uid://xwa7rmlmy5ow")

@onready var label: Label = $HBoxContainer/Label
@onready var instrument_list: HBoxContainer = $HBoxContainer/ScrollContainer/InstrumentList

var midi_name: String
var instruments_details: Array[Dictionary] # { instrument_code, note_count, notes_percentage }

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	label.text = midi_name
	for detail in instruments_details:
		var instrument = Intruments.instruments[detail['instrument_code'] + 1]
		
		var instrument_notes_amount := INSTRUMENT_NOTES_AMOUNT.instantiate()
		instrument_notes_amount.instrument_type = instrument['type'];
		instrument_notes_amount.value = detail['notes_percentage'] * 100
		instrument_notes_amount.instrument_name = instrument['name']
		instrument_list.add_child(instrument_notes_amount)


func _on_button_pressed() -> void:
	var character_select_menu_scene := CHARACTER_SELECT_MENU.instantiate()
	character_select_menu_scene.midi_file = 'res://midis/' + midi_name
	var instrument_codes: Array[int]
	for detail in instruments_details:
		instrument_codes.append(detail['instrument_code'])
	character_select_menu_scene.instrument_codes = instrument_codes.slice(1, 4) # TODO: test code
	get_tree().change_scene_to_node(character_select_menu_scene)
