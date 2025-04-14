extends dialog_state
class_name dialog_play_state

var typewriter : bool = false
var typewriter_tween : Tween
var is_voiced : bool
var auto_finish_on_voice : bool
var auto_finish_on_typewriter : bool

func enter_state():
	super.enter_state()
	if manager.current_line.typewriter:
		typewriter=true
		manager.ui_refs.dialog_text.visible_ratio = 0
		typewriter_tween = create_tween()
		typewriter_tween.tween_property(manager.ui_refs.dialog_text,"visible_ratio",1,0.1 * manager.current_line.line.length())
		typewriter_tween.finished.connect(tween_finished)

func tick():
	if typewriter:
		#typewriter sound
		pass
	super.tick()

func tween_finished():
	typewriter_tween.finished.disconnect(tween_finished)
	print("tween finish")
	if manager.current_line.confirm_on_typewriter_end:
		if !manager.current_line.use_choices:
			#move to wait
			await get_tree().create_timer(1).timeout
			next_state(manager.load_state)
			pass
	elif manager.current_line.use_choices:
		print("choice")
		manager.enable_element(manager.ui_refs.choice_box)
		manager.enable_element(manager.ui_refs.choice_1)
		manager.enable_element(manager.ui_refs.choice_2)
		manager.ui_refs.choice_1.pressed.connect(choice_1)
		manager.ui_refs.choice_2.pressed.connect(choice_2)

func choice_1():
	manager.ui_refs.choice_1.pressed.disconnect(choice_1)
	manager.ui_refs.choice_2.pressed.disconnect(choice_2)
	manager.current_conversation = manager.current_line.choice.choice_one_conversation
	next_state(manager.setup_state)

func choice_2():
	manager.ui_refs.choice_1.pressed.disconnect(choice_1)
	manager.ui_refs.choice_2.pressed.disconnect(choice_2)
	manager.current_conversation = manager.current_line.choice.choice_two_conversation
	next_state(manager.setup_state)

func on_action():
	print("play on action")
	if typewriter_tween.is_running():
		typewriter_tween.stop()
		typewriter_tween.finished.disconnect(tween_finished)
		manager.ui_refs.dialog_text.visible_ratio=1
	elif !is_voiced and !manager.current_line.use_choices:
		next_state(manager.load_state)
	super.on_action()
