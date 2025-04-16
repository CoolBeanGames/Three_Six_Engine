@tool
extends EditorPlugin

var control : PackedScene
var instance : dialog_UI
var entries : Array[csvDataContainer] = []
var Actors : Array[Actor] = []
var Lines : Array[DialogLine] = []
var Convos : Array[Conversation] = []
var groups : Array[ConversationGroup] = []
var choices : Array[DialogChoice] = []

func _enter_tree() -> void:
	# Initialization of the plugin goes here.
	control = load("res://addons/ThreeSix/DialogImporterUI.tscn")
	instance = control.instantiate()
	add_control_to_bottom_panel(instance,"import UI")
	pass


func _exit_tree() -> void:
	remove_control_from_bottom_panel(instance)
	instance.queue_free()
	# Clean-up of the plugin goes here.
	pass

func scan_trees():
	pass

func on_button():
	pass
