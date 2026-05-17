extends Node3D

const FRET_BOARD = preload('res://scenes/fret_board/fret_board.tscn')
const INSTRUMENT_PROGRESS_ICON = preload("uid://bibqfw0iu5i80")

@onready var midi_player: MidiPlayer = $MidiPlayer
@onready var play_bar: Node3D = $PlayBar
@onready var progress_bar: ProgressBar = $ProgressBar
@onready var state_label: Label = $StateLabel
@onready var outcome_panel_container: PanelContainer = $OutcomePanelContainer
@onready var outcome_label: Label = $OutcomePanelContainer/MarginContainer/VBoxContainer/OutcomeLabel
@onready var break_down_label: Label = $OutcomePanelContainer/MarginContainer/VBoxContainer/BreakDownLabel

@export var instrument_character_selection: Dictionary[int, Character]
@export var midi_file: String

var selected_board_index := 0
var boards := []
var game_started := false
var channel_volumes: Dictionary[int, float] = {}

func _ready() -> void:
	GameStats.game_finished.connect(_on_game_finished)
	midi_player.file = midi_file
	midi_player.analyze_midi(midi_file)
	for ch in midi_player.channel_status:
		channel_volumes[ch.number] = ch.volume
	
	GameStats.reset_game(instrument_character_selection)
	for code in instrument_character_selection:
		var board = FRET_BOARD.instantiate()
		board.instrument_code = code
		board.midi_player = midi_player
		board.character = instrument_character_selection[code]
		board.playing_position_index = boards.size()
		
		var instrument_progress_icon := INSTRUMENT_PROGRESS_ICON.instantiate()
		instrument_progress_icon.instrument_code = code
		instrument_progress_icon.playing_position_index = boards.size()
		progress_bar.add_child(instrument_progress_icon)
		
		if boards.size() > 0:
			board.position = Vector3(
				boards.size() * 4.2,
				-3,
				-1
			)
		boards.push_back(board)
		board.process_notes()
		add_child(board)
	
	_update_play_bar_status()


func _process(_delta: float) -> void:
	progress_bar.value = GameStats.crowd_favor


func _update_play_bar_status() -> void:
	for fret_button in get_tree().get_nodes_in_group('fret_buttons'):
		fret_button.button_is_disabled = boards[selected_board_index].board_is_disabled


func _input(event: InputEvent) -> void:
	if (
		(event.is_action_pressed('shift_fret_board_left') and selected_board_index > 0) or
		(event.is_action_pressed('shift_fret_board_right') and selected_board_index < boards.size() - 1)
	):
		selected_board_index += -1 if event.is_action_pressed('shift_fret_board_left') else 1
		var tween := create_tween()
		tween.set_parallel()
		for i in range(boards.size()):
			tween.tween_property(
				boards[i],
				'position',
				Vector3(
					(i - selected_board_index) * 4.2,
					0 if selected_board_index == i else -3,
					0 if selected_board_index == i else -1,
				),
				0.2
			)
		#tween.tween_callback(tween.queue_free)
		tween.play()
		
		_update_play_bar_status()
		
		for ch in midi_player.channel_status:
			if ch.number == boards[selected_board_index].channel_number:
				ch.volume = _calc_volume_for_selected_board(channel_volumes[ch.number])
			else:
				ch.volume = _calc_volume_for_unselected_board(channel_volumes[ch.number])
			midi_player.update_channel_status(ch)
	
	if event.is_action_pressed('toggle_play'):
		if not midi_player.playing:
			if game_started:
				midi_player.playing = true
			else:
				game_started = true
				midi_player.play()
				
			state_label.hide()
		else:
			midi_player.playing = false
			state_label.text = 'Paused'
			state_label.show()
	
	if event.is_action('ui_cancel'):
		midi_player.stop()
		get_tree().change_scene_to_file("res://views/midi_select_menu/midi_select_menu.tscn")


func _calc_volume_for_selected_board(volume: float) -> float:
	return (volume * 0.2) + 0.8


func _calc_volume_for_unselected_board(volume: float) -> float:
	return volume * 0.4


func _on_midi_player_midi_event(
	channel: MidiPlayer.GodotMIDIPlayerChannelStatus,
	event: SMF.MIDIEvent
) -> void:
	if (
		 event.type == SMF.MIDIEventType.control_change and
		event.number == SMF.control_number_volume
	):
		var volume := float( event.value ) / 127.0
		channel_volumes[channel.number] = volume
		if channel.number == boards[selected_board_index].channel_number:
			channel.volume = _calc_volume_for_selected_board(channel_volumes[channel.number])
		else:
			channel.volume = _calc_volume_for_unselected_board(channel_volumes[channel.number])
		midi_player.update_channel_status(channel)


func _on_midi_player_finished() -> void:
	_on_game_finished(GameStats.crowd_favor > 50)


func _on_game_finished(success: bool):
	if midi_player.playing:
		midi_player.stop()
	outcome_label.text = 'Success!!' if success else 'Fail :('
	var rating_breakdown := []
	for detail in GameStats.playing_positions:
		if detail['character'] != null:
			rating_breakdown.append('{0}: {1}%'.format([
				(detail['character'] as Character).name,
				detail['rating']
			]))
	break_down_label.text = '\n'.join(rating_breakdown)
	outcome_panel_container.show()


func _on_outcome_panel_button_pressed() -> void:
	get_tree().change_scene_to_file('res://views/midi_select_menu/midi_select_menu.tscn')
