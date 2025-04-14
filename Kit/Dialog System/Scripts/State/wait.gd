extends dialog_state
class_name dialog_wait_state

func on_action():
	super.on_action()
	next_state(manager.load_state)
