@tool
extends EditorPlugin
class_name dialog_importer

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
	instance.import_finished.connect(reload_files)


func _exit_tree() -> void:
	remove_control_from_bottom_panel(instance)
	instance.import_finished.disconnect(reload_files)
	instance.queue_free()	

func reload_files():
	print("reloading files")
	get_editor_interface().get_resource_filesystem().scan_sources()
