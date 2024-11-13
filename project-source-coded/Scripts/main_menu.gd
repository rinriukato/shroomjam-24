extends Control



func _on_start_button_down() -> void:
	get_tree().change_scene_to_file("res://Scenes/world_test.tscn")

func _on_exit_button_down() -> void:
	get_tree().quit()

func _on_controls_button_down() -> void:
	pass # Replace with function body.
