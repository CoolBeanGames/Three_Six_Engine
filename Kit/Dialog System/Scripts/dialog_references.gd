class_name DialogRefs

var portrait_image : TextureRect
var dialog_parent : Control
var dialog_text : RichTextLabel
var dialog_panel : PanelContainer
var name_text : RichTextLabel
var name_panel : PanelContainer
var choice_box : PanelContainer
var choice_1 : Button
var choice_2 : Button

func _init() -> void:
	dialog_parent = Game_Data.references["dialog_parent"]
	portrait_image = Game_Data.references["portrait_image"]
	dialog_text = Game_Data.references["dialog_text"]
	dialog_panel = Game_Data.references["dialog_panel"]
	name_text = Game_Data.references["name_text"]
	name_panel = Game_Data.references["name_panel"]
	choice_box = Game_Data.references["choice_box"]
	choice_1 = Game_Data.references["choice_1_button"]
	choice_2 = Game_Data.references["choice_2_button"]
