@tool
extends Control
class_name csv_ui

var parent : dialog_importer

##button getters
func get_load_csv_button() -> Button:
	return $"Main Container/HBoxContainer/Button"	

func get_parse_csv_button() -> Button:
	return $"Main Container/HBoxContainer/Button2"

func get_create_resources() -> Button:
	return $"Main Container/HBoxContainer/Button3"

func get_https() -> HTTPRequest:
	return $HTTPRequest

func get_url() -> String:
	return $"Main Container/Url Box".text

func get_sheet_number() -> int:
	return int($"Main Container/sheet id box".text)

##update bottom text
func update_changed_entries(text : String):
	$"Main Container/HBoxContainer2/changed entries".text = "entries changed: " + text

func update_new_entries(text : String):
	$"Main Container/HBoxContainer2/new entries".text = "new entries: " + text

func update_entries_created(text : String):
	$"Main Container/HBoxContainer2/entries created".text ="entries: " + text

func update_time_taken(text : float):
	if text > 1000:
		$"Main Container/HBoxContainer2/time taken".text ="time taken: " + str(text/1000) + " seconds"
		return
	$"Main Container/HBoxContainer2/time taken".text ="time taken: " + str(text/1000) + " MS"

func update_csv_preview(text : String):
	$"Main Container/ScrollContainer/VBoxContainer/csv_preview/Panel/RichTextLabel".text = text
