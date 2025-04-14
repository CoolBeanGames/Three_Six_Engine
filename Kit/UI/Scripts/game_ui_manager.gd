extends Control
class_name GameUIManager

func _ready() -> void:
	assign_dialog_references()

func assign_dialog_references():
	Game_Data.references["dialog_parent"] = $MarginContainer/Dialog_UI
	Game_Data.references["portrait_image"] = $MarginContainer/Dialog_UI/Portrait/TextureRect
	Game_Data.references["dialog_text"] = $MarginContainer/Dialog_UI/TextBox/MarginContainer/DialogText
	Game_Data.references["dialog_panel"] = $MarginContainer/Dialog_UI/TextBox
	Game_Data.references["name_text"] = $MarginContainer/Dialog_UI/NameBox/MarginContainer/NameText
	Game_Data.references["name_panel"] = $MarginContainer/Dialog_UI/NameBox
	Game_Data.references["choice_box"] = $"MarginContainer/Dialog_UI/Choice Box"
	Game_Data.references["choice_1_button"] = $"MarginContainer/Dialog_UI/Choice Box/MarginContainer/VBoxContainer/Button Choice 1"
	Game_Data.references["choice_2_button"] = $"MarginContainer/Dialog_UI/Choice Box/MarginContainer/VBoxContainer/Button Choice 2"
