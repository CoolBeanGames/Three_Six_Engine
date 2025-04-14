extends dialog_state
class_name dialog_idle_state

func enter_state():
	manager.disable_and_reset_ui()
	super.enter_state()
