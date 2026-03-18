extends Control

const GAME_PLAY = preload('res://scenes/game_play/game_play.tscn')

@onready var v_box_container: VBoxContainer = $MarginContainer/VBoxContainer
@onready var midi_player: MidiPlayer = $MidiPlayer

const MIDI_DIR = 'res://midis/'

func _ready() -> void:
	var dir := DirAccess.open(MIDI_DIR)
	if dir:
		dir.list_dir_begin()
		var file_name := dir.get_next()
		while file_name != "":
			if not dir.current_is_dir():
				_create_row(file_name)
			file_name = dir.get_next()


func _create_row(file_name: String) -> void:
	var row := HBoxContainer.new()
	row.custom_minimum_size.y = 200
	
	var label := Label.new()
	label.text = file_name
	label.add_theme_font_size_override('font_size', 30)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label)
	
	var instrument_list := ItemList.new()
	instrument_list.select_mode = ItemList.SELECT_TOGGLE
	instrument_list.add_theme_font_size_override('font_size', 30)
	instrument_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(instrument_list)
	
	var play_button := Button.new()
	play_button.text = 'Play'
	play_button.add_theme_font_size_override('font_size', 30)
	play_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	#play_button.disabled = true
	play_button.pressed.connect(func(): _on_play_button_pressed(file_name, instrument_list))
	row.add_child(play_button)
	
	v_box_container.add_child(row)
	
	var ok := midi_player.analyze_midi(MIDI_DIR + file_name)
	if ok:
		var instruments_details = _get_instruments_details()
		for detail in instruments_details:
			var instrument_name = Intruments.instruments[detail['instrument_code'] + 1]['name']
			instrument_list.add_item('{0} - {1} notes'.format([
				instrument_name,
				detail['note_count']
			]))
			instrument_list.set_item_metadata(instrument_list.item_count - 1, detail)
	else:
		prints('naaah', MIDI_DIR + '/' + file_name)


func _on_play_button_pressed(file_name: String, item_list: ItemList) -> void:
	var selected_indecies := item_list.get_selected_items()
	
	var instrument_codes: Array[int] = []
	for i in selected_indecies:
		var metadata: Dictionary = item_list.get_item_metadata(i)
		instrument_codes.push_back(metadata['instrument_code'])
	
	var game_play_scene := GAME_PLAY.instantiate()
	game_play_scene.midi_file = MIDI_DIR + file_name
	game_play_scene.instrument_codes = instrument_codes
	
	get_tree().root.add_child(game_play_scene)
	hide()
	queue_free()


func _get_instruments_details() -> Array[Dictionary]:
	var channel_instrument: Dictionary[int, int] = {}
	var instrument_notes: Dictionary[int, int] = {}
	for ec in midi_player.track_status.events:
		# TODO: Handle channels sharing the same instrument
		if ec.event.type == SMF.MIDIEventType.program_change:
			channel_instrument[ec.channel_number] = ec.event.number
		
		if ec.event.type == SMF.MIDIEventType.note_on:
			var instrument_code = channel_instrument[ec.channel_number]
			instrument_notes[instrument_code] = instrument_notes.get(instrument_code, 0) + 1
	
	var list: Array[Dictionary] = []
	for instrument_code in instrument_notes:
		var entry := {
			'instrument_code': instrument_code,
			'note_count': instrument_notes[instrument_code]
		}
		list.push_back(entry)
	return list
