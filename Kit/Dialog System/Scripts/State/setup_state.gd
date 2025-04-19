extends DialogState
class_name DialogSetupState

func enter_state():
	manager.dialog_index = -1
	manager.disable_and_reset_ui(true)
	next_state(manager.load_state)
