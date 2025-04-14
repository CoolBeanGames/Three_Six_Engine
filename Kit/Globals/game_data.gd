extends Node
class_name GameData

@export var data : Dictionary
@export var settings : Dictionary
@export var references : Dictionary
@export var flags : Dictionary[String, bool]
@export var save_path : String = "user://Three Six/" + ProjectSettings["application/config/name"] + "/" 

##save game data to file
func save_data(file_extension : String = ".sav", file_numer : int = 1, settings_only : bool = false) -> bool:
	var final_save_path = create_filename(file_extension,save_path,settings_only,file_numer)
	directory_checks(final_save_path)
	
	var file = FileAccess.open(final_save_path,FileAccess.WRITE)
	if file:
		if not settings_only:
			file.store_var(create_master_dictionary())
			print("save data written to file to path " + final_save_path)
			return true
		else:
			file.store_var(settings)
			print("settings data written to file to path " + final_save_path)
	else:
		printerr("failed to write save file to path " + final_save_path + "(Failed to open file)")
		return false
	return true

##load our data from the file
func load_data(file_extension : String = ".sav", file_number : int = 1, settings_only : bool = false) -> bool:
	var final_save_path = create_filename(file_extension,save_path,settings_only,file_number)
	directory_checks(final_save_path)
	
	var file = FileAccess.open(final_save_path,FileAccess.READ)
	if file:
		if not settings_only:
			var master_dict : Dictionary = file.get_var(true)
			data = get_data_dict(master_dict)
			settings = get_settings_dict(master_dict)
			flags = get_flags_dict(master_dict)
			print("succesfully loaded save data from path " + final_save_path)
		else:
			settings = file.get_var(true)
			print("successfully loaded settings from path " + final_save_path)
	else:
		printerr("failed to load game data from path " + final_save_path)
		return false
	return true

##get a complete filename
func create_filename(extension : String, path : String, settings_only : bool = false, number : int = 1) -> String:
	if not settings_only:
		var final_path = path + "save data/" +"file_" + str(number) + extension
		return final_path
	else:
		var final_path = path + "settings" + extension
		return final_path

##combine all 3 dictionaries into a combined dictionary
func create_master_dictionary(settings_only : bool = false) -> Dictionary:
	var master_dict : Dictionary
	if not settings_only:
		master_dict = {
			"data" : data,
			"settings" : settings,
			"flags" : flags }
	else:
		master_dict = settings
	return master_dict

##returns the data dictionary when loading from a file
func get_data_dict(master_dict : Dictionary) -> Dictionary:
	if master_dict.has("data"):
		return master_dict["data"]
	else:
		var new_dict : Dictionary
		printerr("[ERROR] attempted to load game data from a dictionary that does NOT contain it")
		return new_dict

##returns the settings data 
func get_settings_dict(master_dict : Dictionary) -> Dictionary:
	if master_dict.has("settings"):
		return master_dict["settings"]
	else:
		var new_dict : Dictionary
		printerr("[ERROR] attempted to load game settings from a dictionary that does NOT contain it")
		return new_dict

##returns the flags data 
func get_flags_dict(master_dict : Dictionary) -> Dictionary:
	if master_dict.has("flags"):
		return master_dict["flags"]
	else:
		var new_dict : Dictionary
		printerr("[ERROR] attempted to load game flags from a dictionary that does NOT contain it")
		return new_dict

##make sure directories exist and if not, create them!
func directory_checks(path : String):
	var base_dir = "user://"
	print("attempted to open directory at ", base_dir)
	var target_dir = path.get_base_dir().replace("user://","")
	var dir = DirAccess.open(base_dir)
	if dir:
		var current_path = ""
		var path_components = target_dir.split("/")
		for component in path_components:
			if component.is_empty():
				continue
			current_path = current_path.path_join(component)
			var full_path = base_dir.path_join(current_path)
			if not dir.dir_exists(full_path):
				var error = dir.make_dir(full_path)
				if error == OK:
					print("Directory created successfully: ", full_path)
				else:
					printerr("Error creating directory: ", full_path)
	else:
		printerr("Error opening base user directory")
