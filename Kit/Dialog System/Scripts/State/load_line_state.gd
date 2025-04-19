extends DialogState
class_name DialogLoadState

func enter_state():
	super.enter_state()
	if manager.dialog_index < manager.current_conversation.lines.size() - 1:
		manager.dialog_index += 1
		manager.current_line = manager.current_conversation.lines[manager.dialog_index]
		if manager.current_line.show_actor_portrait:
			manager.ui_refs.portrait_image.texture = manager.current_line.actor.actor_portrait
			manager.enable_element(manager.ui_refs.portrait_image)
		else:
			manager.ui_refs.portrait_image.texture = null
		if manager.current_line.use_choices:
			manager.ui_refs.choice_1.text = manager.current_line.choice.choice_one_text
			manager.ui_refs.choice_2.text = manager.current_line.choice.choice_two_text
		manager.enable_rich_label(manager.ui_refs.dialog_text, manager.current_line.line)
		manager.enable_rich_label(manager.ui_refs.name_text, manager.current_line.actor.actor_name)
		manager.enable_element(manager.ui_refs.dialog_panel)
		manager.enable_element(manager.ui_refs.name_panel)
		next_state(manager.play_state)
	else:
		manager.disable_and_reset_ui()
		next_state(manager.idle_state)
