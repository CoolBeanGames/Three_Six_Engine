extends Node
class_name DialogManager

@export var current_state : DialogState
var current_conversation : Conversation
var current_line : DialogLine
var current_choice : DialogChoice
var ui_refs : DialogRefs
var dialog_index = 0
@export var audio_pips : Array[AudioStream] = []
@export_category("states")
@export var idle_state : DialogIdleState
@export var setup_state : DialogSetupState
@export var load_state : DialogLoadState
@export var play_state : DialogPlayState
@export var wait_state : DialogWaitState
@export var test_convo : Conversation


func _ready() -> void:
	await get_tree().process_frame
	ui_refs=DialogRefs.new()
	_init_states()
	
	await get_tree().create_timer(1).timeout
	start_dialog_conversation(test_convo)

func _init_states():
	idle_state.initialize(self)
	setup_state.initialize(self)
	load_state.initialize(self)
	play_state.initialize(self)
	wait_state.initialize(self)
	
	current_state=idle_state
	current_state.enter_state()

func _process(delta: float) -> void:
	#this is a temp function
	if Input.is_action_just_released("action"):
		current_state.on_action()
	current_state.tick()

func disable_and_reset_ui(instant : bool = false):
	ui_refs.dialog_text.text = ""
	ui_refs.name_text.text = ""
	ui_refs.choice_1.text = ""
	ui_refs.choice_2.text = ""
	if(instant):
		ui_refs.choice_1.self_modulate = Color(1,1,1,0)
		ui_refs.choice_2.self_modulate = Color(1,1,1,0)
		ui_refs.choice_box.self_modulate = Color(1,1,1,0)
		ui_refs.dialog_panel.self_modulate = Color(1,1,1,0)
		ui_refs.name_panel.self_modulate = Color(1,1,1,0)
		ui_refs.portrait_image.texture=null
		ui_refs.portrait_image.self_modulate = Color(1,1,1,0)
	else:
		var choice_1_tween : Tween = create_tween()
		var choice_2_tween : Tween = create_tween()
		var choice_box : Tween = create_tween()
		var name_panel : Tween = create_tween()
		var portrait : Tween = create_tween()
		var dialog_panel : Tween = create_tween()
		choice_1_tween.tween_property(ui_refs.choice_1,"self_modulate",Color(1,1,1,0),.25)
		choice_2_tween.tween_property(ui_refs.choice_2,"self_modulate",Color(1,1,1,0),.25)
		choice_box.tween_property(ui_refs.choice_box,"self_modulate",Color(1,1,1,0),.25)
		name_panel.tween_property(ui_refs.name_panel,"self_modulate",Color(1,1,1,0),.25)
		portrait.tween_property(ui_refs.portrait_image,"self_modulate",Color(1,1,1,0),.25)
		dialog_panel.tween_property(ui_refs.dialog_panel,"self_modulate",Color(1,1,1,0),.25)

func enable_element(element : Control):
	var tween : Tween = create_tween()
	element.visible = true 
	tween.tween_property(element,"self_modulate",Color(1,1,1,1),.25)

func enable_label(element : Label, text : String):
	var tween : Tween = create_tween()
	element.visible = true 
	element.text = text
	tween.tween_property(element,"self_modulate",Color(1,1,1,1),.25)

func enable_rich_label(element : RichTextLabel, text : String):
	var tween : Tween = create_tween()
	element.visible = true 
	element.text = text
	tween.tween_property(element,"self_modulate",Color(1,1,1,1),.25)

func enable_button(element : Button, text : String):
	var tween : Tween = create_tween()
	element.visible = true 
	element.text = text
	tween.tween_property(element,"self_modulate",Color(1,1,1,1),.25)

func disable_element(element : Control):
	var tween : Tween = create_tween()
	element.visible = true 
	tween.tween_property(element,"self_modulate",Color(1,1,1,0),.25)

func disable_label(element : Label, text : String):
	var tween : Tween = create_tween()
	element.visible = true 
	element.text = text
	tween.tween_property(element,"self_modulate",Color(1,1,1,0),.25)

func disable_rich_label(element : RichTextLabel, text : String):
	var tween : Tween = create_tween()
	element.visible = true 
	element.text = text
	tween.tween_property(element,"self_modulate",Color(1,1,1,0),.25)

func disable_button(element : Button, text : String):
	var tween : Tween = create_tween()
	element.visible = true 
	element.text = text
	tween.tween_property(element,"self_modulate",Color(1,1,1,0),.25)

func start_dialog_conversation(convo : Conversation):
	current_conversation = convo
	current_state.next_state(setup_state)

func play_audio_pip():
	if audio_pips.size() > 0:
		var pip : AudioStream = audio_pips[randi_range(0,audio_pips.size()-1)]
		Audio_Manager.Create(pip,true,AudioManager.audio_type.sfx,1,current_line.actor.pitch_offset)
