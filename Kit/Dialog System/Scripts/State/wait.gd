extends DialogState
class_name DialogWaitState

func on_action():
	super.on_action()
	next_state(manager.load_state)
