extends Node
class_name DialogState

var manager : DialogManager

func initialize(man : DialogManager) -> void:
	manager = man

func enter_state():
	print("dialog entered state: ", name)
	pass

func exit_state():
	pass

func tick():
	pass

func on_action():
	pass

func next_state(new_state : DialogState):
	manager.current_state = new_state
	exit_state()
	new_state.enter_state()
