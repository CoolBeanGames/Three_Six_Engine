extends HBoxContainer
class_name dialog_display_entry

func setup(actor_name : String, group_name : String, Conversation_name : String, Line_Name : String, Line : String, is_Voiced: bool, already_Exists : bool):
	$Actor.text=actor_name
	$Group.text = group_name
	$Conversation.text = Conversation_name
	$"Line Name".text = Line_Name
	$Line.text = Line
	$is_voiced.button_pressed = is_Voiced
	$"already exists".button_pressed = already_Exists
