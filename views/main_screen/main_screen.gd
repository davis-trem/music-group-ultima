extends Control


func _on_tutorial_button_pressed() -> void:
	get_tree().change_scene_to_file('res://scenes/tutorial_game_play/tutorial_game_play.tscn')


func _on_exibition_button_pressed() -> void:
	get_tree().change_scene_to_file('res://views/midi_select_menu/midi_select_menu.tscn')
