extends Resource
class_name dialog_choice

@export var choice_one_text : String
@export var choice_one_conversation : conversation
@export var choice_one_flags : Array[String] = []
@export var choice_two_text : String
@export var choice_two_conversation : conversation
@export var choice_two_flags : Array[String] = []
@export var ui_selected : int = 0 ##0=1 1=2

func choose(choice : int) -> conversation:
	match choice:
		1:
			for f in choice_one_flags:
				Flag_Events.set_flag(f,true)
			return choice_one_conversation
		2:
			for f in choice_two_flags:
				Flag_Events.set_flag(f,true)
			return choice_two_conversation
	return null
