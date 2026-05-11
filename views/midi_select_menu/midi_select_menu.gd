extends Control

const GAME_PLAY = preload('res://scenes/game_play/game_play.tscn')
const MIDI_SELECT_ROW = preload("uid://cilh5n8c0v3ho")

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
	var ok := midi_player.analyze_midi(MIDI_DIR + file_name)
	if ok:
		var instruments_details = _get_instruments_details()

		var select_row := MIDI_SELECT_ROW.instantiate()
		select_row.midi_name = file_name
		
		select_row.instruments_details = instruments_details
		v_box_container.add_child(select_row)
	else:
		prints('naaah', MIDI_DIR + file_name)


func _get_instruments_details() -> Array[Dictionary]:
	var channel_instrument: Dictionary[int, int] = {}
	var instruments_ticks: Dictionary[int, Array] = {}
	var highest_notes_count := 0
	for ec in midi_player.track_status.events:
		# TODO: Handle channels sharing the same instrument
		if ec.event.type == SMF.MIDIEventType.program_change:
			channel_instrument[ec.channel_number] = ec.event.number \
				if ec.channel_number != MidiPlayer.drum_track_channel else 999
		
		if ec.event.type == SMF.MIDIEventType.note_on:
			var instrument_code = channel_instrument[ec.channel_number]
			var ticks: Array = instruments_ticks.get(instrument_code, [])
			# note is in chord if tick and duration is 50 ticks apart
			if ticks.size() == 0 or ticks[-1] + 50 <= ec.time:
				ticks.append(ec.time)
				instruments_ticks[instrument_code] = ticks
			highest_notes_count = max(highest_notes_count, instruments_ticks[instrument_code].size())
	
	var list: Array[Dictionary] = []
	for instrument_code in instruments_ticks:
		var entry := {
			'instrument_code': instrument_code,
			'note_count': instruments_ticks[instrument_code].size(),
			'notes_percentage': (
				float(instruments_ticks[instrument_code].size()) / float(highest_notes_count)
			)
		}
		list.push_back(entry)
	return list
