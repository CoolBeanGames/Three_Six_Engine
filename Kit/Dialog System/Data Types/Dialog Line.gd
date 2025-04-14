extends Resource
class_name dialog_line

@export var actor : Actor
@export_multiline var line : String = ""
@export var flags : Array[String]
@export_category("flags") 
@export var show_actor_portrait : bool = false
@export_category("typewriter")
@export var typewriter : bool = true
@export_category("choices")
@export var use_choices : bool = false
@export var choice: dialog_choice
@export_category("confirmation")
@export var auto_confirm : bool = false
@export var confirm_on_typewriter_end : bool = false
