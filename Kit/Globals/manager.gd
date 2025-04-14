extends Node
class_name game_manager

var viewport_size : Vector2
var game_resolution : Vector2

var match_resolution_to_viewport : bool = true

func _ready() -> void:
	get_window().size_changed.connect(resize_screen)
	resize_screen()

func resize_screen():
	print("screen resized")
	if match_resolution_to_viewport:
		get_viewport().size = get_window().size
