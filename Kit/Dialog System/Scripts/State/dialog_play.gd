extends DialogState
class_name DialogPlayState

var typewriter : bool = false
var typewriter_tween : Tween
var is_voiced : bool
var auto_finish_on_voice : bool
var auto_finish_on_typewriter : bool
var auto_finish : bool
var choice_active : bool = false
var current_line : DialogLine
var current_choice : DialogChoice
var typewriter_speed : float  = 0
var vocal_player : AudioPlayer

#setup the machine
func enter_state():
	super.enter_state()
	check_data()
	choice_active = false
	if current_line.typewriter:
		typewriter=true
		manager.ui_refs.dialog_text.visible_ratio = 0
		start_typewriter()
	else:
		if current_choice != null:
			enable_choices()
	if is_voiced:
		vocal_player = Audio_Manager.Create(current_line.voiced_line,false)
		vocal_player.finished.connect(on_voice_finished)
		##play voice line here
		return

##set flags for this line
func check_data():
	current_line = manager.current_line
	if current_line.use_choices:
		current_choice = current_line.choice
	else:
		current_choice = null
	is_voiced = current_line is VoicedDialogLine
	typewriter = current_line.typewriter
	if is_voiced:
		auto_finish_on_voice = current_line.end_on_voice_end
	else:
		auto_finish_on_voice = false
	auto_finish_on_typewriter = current_line.confirm_on_typewriter_end
	auto_finish = current_line.auto_confirm

##helper function to start the typewriter tween
func start_typewriter():
	typewriter_tween = create_tween()
	typewriter_speed = 0.1 * current_line.line.length()
	if is_voiced:
		typewriter_speed *= .3
	typewriter_tween.tween_property(manager.ui_refs.dialog_text,"visible_ratio",1,typewriter_speed)
	typewriter_tween.finished.connect(tween_finished)
	if not is_voiced:
		$"../Timer".start()

##used for playing typewriter sounds
func pip_timer():
	manager.play_audio_pip()
	$"../Timer".start()


##called when the typewriter tween finishes
func tween_finished():
	typewriter_tween.finished.disconnect(tween_finished)
	$"../Timer".stop()
	print("tween finish")
	if auto_finish_on_typewriter: ##autoconfirm on end
		if current_choice == null:
			#move to wait
			await get_tree().create_timer(1).timeout
			next_state(manager.load_state)
			pass
	elif current_choice != null: ##if we have choices, call them
		enable_choices()

#enable the choices UI
func enable_choices():
	reset_buttons()
	choice_active = true
	manager.enable_element(manager.ui_refs.choice_box)
	manager.enable_element(manager.ui_refs.choice_1)
	manager.enable_element(manager.ui_refs.choice_2)
	manager.ui_refs.choice_1.pressed.connect(choice_1)
	manager.ui_refs.choice_2.pressed.connect(choice_2)

#choice 1 was chosen
func choice_1():
	choice_helper(current_choice.choice_one_conversation,current_choice.choice_one_flags)

#choice 2 was chosen
func choice_2():
	choice_helper(current_choice.choice_two_conversation,current_choice.choice_two_flags)

##call me to reset all the buttons
func exit_state():
	reset_buttons()
	super.exit_state()

##used to held disconnect choices when something is chosen
func choice_helper(choice_conversation : Conversation, flags : Array[String]):
	reset_buttons()
	if is_voiced and vocal_player and vocal_player.playing:
		vocal_player.stop()
		vocal_player.finished.disconnect(on_voice_finished)
	if typewriter_tween and typewriter_tween.is_running():
		typewriter_tween.stop()
	manager.current_conversation = choice_conversation
	#set all the flags for the choice
	for f in flags:
		Flag_Events.set_flag(f,true)
	next_state(manager.setup_state)

func reset_buttons():
	for conn in manager.ui_refs.choice_1.pressed.get_connections():
		manager.ui_refs.choice_1.pressed.disconnect(conn.callable)
	for conn in manager.ui_refs.choice_2.pressed.get_connections():
		manager.ui_refs.choice_2.pressed.disconnect(conn.callable)
	manager.disable_element(manager.ui_refs.choice_box)
	manager.disable_element(manager.ui_refs.choice_1)
	manager.disable_element(manager.ui_refs.choice_2)	

##on action for moving to next states
func on_action():
	print("play on action") 
	if typewriter_tween and typewriter_tween.is_running(): ##this is a typewriter
		stop_typewriter()
		print("stopping tween in play")
		if_use_choices_on_end()
		return
	if is_voiced and vocal_player: ##and voice playing
		##stop voice
		end_audio()
		if_use_choices_on_end()
		return
	if current_choice != null: ##not a typerwriter voiced and doesnt use choices
		if_use_choices_on_end()
		return
	##none of the other conditions are true so just return
	print("not voiced and doesnt use choices, going back to load")
	next_state(manager.load_state)
	return
	super.on_action()

##todo add end voice line code here
func end_audio():
	if vocal_player.playing:
		vocal_player.stop()
		on_voice_finished()
	return

##called when a voice line finishes
func on_voice_finished():
	var typewriter_done := not typewriter_tween or not typewriter_tween.is_running()
	vocal_player.finished.disconnect(on_voice_finished)
	vocal_player=null
	if auto_finish_on_voice and typewriter_done and current_choice == null:
		next_state(manager.load_state)
	elif current_choice != null:
		enable_choices()

##called when the user presses action and the line uses choices
func if_use_choices_on_end():
	if  current_choice != null:
		print("enable choices in action")
		enable_choices()

##stops the typewriter effect dead in its tracks
func stop_typewriter():
	typewriter_tween.stop()
	typewriter_tween.finished.disconnect(tween_finished)
	manager.ui_refs.dialog_text.visible_ratio=1
