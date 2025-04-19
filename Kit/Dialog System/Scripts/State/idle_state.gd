extends DialogState
class_name DialogIdleState

func enter_state():
	manager.disable_and_reset_ui()
	super.enter_state()
