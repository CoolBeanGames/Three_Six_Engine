extends Node
class_name dialog_state

var manager : dialog_manager

func initialize(man : dialog_manager) -> void:
	manager = man

func enter_state():
	#print("dialog entered state: ", name)
	pass

func exit_state():
	pass

func tick():
	pass

func on_action():
	pass

func next_state(new_state : dialog_state):
	manager.current_state = new_state
	exit_state()
	new_state.enter_state()
