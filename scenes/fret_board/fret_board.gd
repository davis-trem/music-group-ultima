extends Node3D

const NOTE = preload('res://scenes/note/note.tscn')

@onready var goal_area_3d: Area3D = $GoalArea3D
@onready var instrument_icon: Sprite3D = $InstrumentIcon

@export var midi_player: MidiPlayer
@export var instrument_code: int
@export var character: Dictionary

var notes := []
var spawned_noted := []

var lanes := [-1.05, -0.35, 0.35, 1.05]

var channel_number := -1
var board_is_disabled := false


func _ready() -> void:
	var instrument_type = Intruments.instruments[instrument_code]['type']
	var icon := load(Intruments.instrument_icons[instrument_type])
	instrument_icon.texture = icon
	if character.is_empty():
		board_is_disabled = true


func _process(_delta: float) -> void:
	if midi_player.playing:
		for note in notes:
			if not note['visited'] and midi_player.position + (midi_player.smf_data.timebase * 5) >= note['tick']:
				note['visited'] = true
				var n = NOTE.instantiate()
				n.character = character
				n.midi_player = midi_player
				n.tick = note['tick']
				n.lane_index = note['lane']
				n.spawned_tick = midi_player.position
				n.start_pos = Vector3(lanes[note['lane']], 0.03, -5)
				n.goal_pos = Vector3(lanes[note['lane']], 0.03, goal_area_3d.position.z)
				add_child(n)
				#if note['duration'] != midi_player.smf_data.timebase:
					#n.set_size(float(note['duration']) / float(midi_player.smf_data.timebase))

				spawned_noted.push_back(n)


func process_notes() -> Array[Dictionary]:
	var chunk_start_index := 0
	var min_note := 1000
	var max_note := -1000
	var temp_notes: Array[Dictionary] = []
	var notes_on := {}
	for ec in midi_player.track_status.events:
		# TODO: Handle channels sharing the same instrument
		if ec.event.type == SMF.MIDIEventType.program_change and ec.event.number == instrument_code:
			channel_number = ec.channel_number
		if ec.channel_number == channel_number and ec.event.type == SMF.MIDIEventType.note_on:
			temp_notes.push_back({
				'tick': ec.time,
				'note': ec.event.note,
				# default length to quarter note
				'duration': midi_player.smf_data.timebase,
				'visited': false,
			})
			notes_on[ec.event.note] = temp_notes.size() - 1
			if min_note == 1000 and max_note == -1000:
				min_note = ec.event.note
				max_note = ec.event.note
			else:
				var new_min_note: int = min(min_note, ec.event.note)
				var new_max_note: int = max(max_note, ec.event.note)
				
				# if reach new octave
				if new_max_note - new_min_note > 12:
					# calc the lanes for notes in prev chunk
					for index in range(chunk_start_index, temp_notes.size() - 1):
						temp_notes[index]['min_note'] = min_note
						temp_notes[index]['max_note'] = max_note
						temp_notes[index]['lane'] = map_note_to_lane(
							temp_notes[index]['note'],
							min_note,
							max_note
						)
					chunk_start_index = temp_notes.size() - 1
				min_note = new_min_note
				max_note = new_max_note
		# calc note duration
		if ec.channel_number == channel_number and ec.event.type == SMF.MIDIEventType.note_off:
			if notes_on.has(ec.event.note):
				var i = notes_on[ec.event.note]
				var diff = ec.time - temp_notes[i]['tick']
				if diff >= midi_player.smf_data.timebase:
					temp_notes[i]['duration'] = diff
				notes_on.erase(ec.event.note)
	
	# calc the lanes for remaining notes in prev chunk
	for index in range(chunk_start_index, temp_notes.size()):
		temp_notes[index]['min_note'] = min_note
		temp_notes[index]['max_note'] = max_note
		temp_notes[index]['lane'] = map_note_to_lane(
			temp_notes[index]['note'],
			min_note,
			max_note
		)
	
	# limit notes in chord
	var chord: Array[Dictionary] = []
	var notes_w_limited_chord: Array[Dictionary] = []
	for note in temp_notes:
		# note is in chord if tick and duration is 50 ticks apart
		if chord.size() == 0:
			chord.push_back(note)
		elif (
			abs(chord[chord.size() - 1]['tick'] - note['tick']) <= 50 and
			abs(chord[chord.size() - 1]['duration'] - note['duration']) <= 50
		):
			# if chord is in the same lane do nothing
			if chord[chord.size() - 1]['lane'] != note['lane']:
				chord.push_back(note)
		else:
			# sort chord by notes
			chord.sort_custom(func(a, b): return a['note'] < b['note'])
			# size <=2 stays; size 3 get index 0 and avg(1,2); size >3 get index avg(0,1) and avg(-1,-2)
			if chord.size() <= 2:
				notes_w_limited_chord.append_array(chord)
			elif chord.size() == 3:
				notes_w_limited_chord.push_back(chord[0])
				var new_note = chord[1]
				new_note['note'] = floor((chord[1]['note'] + chord[2]['note']) / 2)
				new_note['lane'] = map_note_to_lane(
					new_note['note'],
					new_note['min_note'],
					new_note['max_note']
				)
				notes_w_limited_chord.push_back(new_note)
			else:
				var new_note = chord[1]
				new_note['note'] = floor((chord[0]['note'] + chord[1]['note']) / 2)
				new_note['lane'] = map_note_to_lane(
					new_note['note'],
					new_note['min_note'],
					new_note['max_note']
				)
				notes_w_limited_chord.push_back(new_note)
				
				new_note = chord[chord.size() - 1]
				new_note['note'] = floor(
					(chord[chord.size() - 1]['note'] + chord[chord.size() - 2]['note']) / 2
				)
				new_note['lane'] = map_note_to_lane(
					new_note['note'],
					new_note['min_note'],
					new_note['max_note']
				)
				notes_w_limited_chord.push_back(new_note)
			
			chord.clear()
			chord.push_back(note)
	
	notes_w_limited_chord.sort_custom(func(a, b): return a['tick'] < b['tick'])
	
	notes = notes_w_limited_chord
	return notes_w_limited_chord


func map_note_to_lane(note: int, min_note: int, max_note: int):
	var pitch_range: = max_note - min_note
	if pitch_range <= 0:
		return 0  # fallback if all notes are same pitch
	# Normalize pitch to 0–1 within region
	var normalized = (note - min_note) / float(pitch_range)
	# Scale normalized value to lane index
	var lane_index = floor(normalized * lanes.size())
	# Clamp in case of edge rounding
	lane_index = clamp(lane_index, 0, lanes.size() - 1)
	return lane_index


func _on_goal_area_3d_area_exited(area: Area3D) -> void:
	var parent = area.get_parent_node_3d()
	if is_instance_of(parent, Note) and not parent.note_played:
		(parent as Note).set_color(Color.DARK_RED)
		GameStats.update_player_rating((parent as Note).character, -1)
		#print('FAIL', (parent as Note).lane_index)


func _on_exit_area_3d_area_exited(area: Area3D) -> void:
	var parent = area.get_parent_node_3d()
	if is_instance_of(parent, Note):
		parent.queue_free()
