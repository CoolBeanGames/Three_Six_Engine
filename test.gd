extends Node

func _ready() -> void:
	await get_tree().create_timer(10).timeout
	print("some text")

making this to force a push