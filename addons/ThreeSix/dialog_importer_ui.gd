@tool
extends Control
class_name dialog_UI

var import_csv_button : Button
var sheet_id : String
var csv : Array

var entries : Array[csvDataContainer] = []
@export var Actors : Dictionary[String,Actor]
@export var Lines : Dictionary[String,DialogLine]
@export var Convos : Dictionary[String,Conversation]
@export var Groups : Dictionary[String,ConversationGroup]
@export var Choices : Dictionary[String,DialogChoice]

func _enter_tree() -> void:
	import_csv_button = $HBoxContainer/Button

func _on_import_csv_pressed() -> void:
	load_and_sort_dialog_resources()
	var URL : String= $HBoxContainer/URL.text
	if URL.contains("https://docs.google.com/spreadsheets"):
		#link is good continue
		print("URL is good, continuing import process")
		get_csv(URL)
		pass
	else:
		print("ERROR, URL must be from google sheets")
	pass # Replace with function body.

func get_csv(url : String):
	var req : HTTPRequest = $HTTPRequest
	req.max_redirects = 1000
	var formatted_url = format_url(url) # This will now use the /export method
	print("Attempting to download from:", formatted_url) # Keep this for debugging
	var error = req.request(formatted_url)
	if error == OK:
		#loaded correctly so continue
		pass
	else:
		printerr("Error Failed to load CSV")
		print(error)


func format_url(url : String) -> String:
	sheet_id = extract_sheet_id(url)
	var complete_String : String = "https://docs.google.com/spreadsheets/d/" + sheet_id + "/export?format=csv&gid=0"
	print("Complete URL: " , complete_String)
	return complete_String


func extract_sheet_id(main_url: String) -> String:
	var start_index = main_url.find("/d/")
	if start_index == -1:
		return "" # "/d/" not found

	start_index += 3 # Move past "/d/"

	var end_index = main_url.find("/", start_index)
	if end_index == -1:
		end_index = main_url.find("#", start_index) # Check for the gid

	if end_index == -1:
		return main_url.substr(start_index) # If no "/" or "#" found after "/d/"
	else:
		return main_url.substr(start_index, end_index - start_index)


func _on_http_request_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	print("HTTPS Request Completed: ", body.get_string_from_utf8())
	$VBoxContainer/RichTextLabel.text = body.get_string_from_utf8()

	if response_code == 302 or response_code == 307: # Check for redirect status codes
		var body_string = body.get_string_from_utf8()
		var redirect_url_start = body_string.find("<A HREF=\"")
		if redirect_url_start != -1:
			redirect_url_start += 9 # Move past "<A HREF=\""
			var redirect_url_end = body_string.find("\">", redirect_url_start)
			if redirect_url_end != -1:
				var redirect_url = body_string.substr(redirect_url_start, redirect_url_end - redirect_url_start)
				print("Following redirect to:", redirect_url)
				$HTTPRequest.request(redirect_url) # Make a new request to the redirected URL
				return # Important: Exit this function to avoid further processing of the redirect HTML
		else:
			printerr("Error: Could not find redirect URL in response.")
			return
	elif result == HTTPRequest.RESULT_SUCCESS and response_code == 200:
		var csv_text = body.get_string_from_utf8()
		var rows = csv_text.split("\n", false)
		csv.clear() # Clear the previous data
		for row_string in rows:
			var columns = row_string.split(",", false)
			csv.append(columns)
		print("Parsed CSV Data:", csv)
		parse_csv()
	else:
		printerr("Failed to download CSV. Result:", result, "Response Code:", response_code)

func parse_csv():
	var index : int = 0
	for s in csv:
		if index >= 1: #for skipping the header
			var data : csvDataContainer = csvDataContainer.new()

			data.actor_name = s[0] if s.size() > 0 else ""
			data.group_name = s[1] if s.size() > 1 else ""
			data.convo_name = s[2] if s.size() > 2 else ""
			data.flags = []
			if s.size() > 3 and not s[3].is_empty():
				var flags_packed = s[3].split(" ")
				for flag in flags_packed:
					data.flags.append(flag)

			data.line_name = s[4] if s.size() > 4 else ""
			data.line_text = s[5] if s.size() > 5 else ""

			data.use_typewriter = bool(str(s[6] if s.size() > 6 else "false").to_lower() == "true")
			data.is_voiced = bool(str(s[7] if s.size() > 7 else "false").to_lower() == "true")
			data.has_choice = bool(str(s[8] if s.size() > 8 else "false").to_lower() == "true")

			data.choice_name = s[9] if s.size() > 9 else ""
			data.choice_1_Convo_Name = s[10] if s.size() > 10 else "" # Or "" if Conversation is String
			data.choice_2_Convo_Name = s[11] if s.size() > 11 else "" # Or "" if Conversation is String
			data.choice_1_Text = s[12] if s.size() > 12 else ""
			data.choice_2_Text = s[13] if s.size() > 13 else ""

			data.choice_1_Flags = []
			if s.size() > 14 and not s[14].is_empty():
				var choice_1_flags_packed = s[14].split(" ")
				for flag in choice_1_flags_packed:
					data.choice_1_Flags.append(flag)

			data.choice_2_Flags = []
			if s.size() > 15 and not s[15].is_empty():
				var choice_2_flags_packed = s[15].split(" ")
				for flag in choice_2_flags_packed:
					data.choice_2_Flags.append(flag)
			
			#create everything here
			create_line(data.actor_name,data.group_name,data.convo_name,data.line_name,data.line_text,data.flags,data.use_typewriter,data.has_choice,data.choice_1_Convo_Name)
			if data.has_choice:
				create_choice(data.choice_name,data.choice_1_Text,data.choice_1_Convo_Name,data.choice_1_Flags,data.choice_2_Text,data.choice_2_Convo_Name,data.choice_2_Flags)
			entries.append(data)
		index += 1
	print("\n \n Entries Created:")
	print(entries)

func load_and_sort_dialog_resources(base_path: String = "res://Data") -> Dictionary:
	var resources : Dictionary = {
		"Actors": {},
		"Lines": {},
		"Convo": {},
		"Groups": {},
		"Choices": {}
	}
	ensure_dialog_directories()
	var res :Array = find_dialog_resources()
	sort_resources(res)
	print(Actors.size())
	return resources


func ensure_dialog_directories(base_path: String = "res://Data", dialog_dir_name: String = "Dialog") -> bool:
	var dialog_path = base_path.rstrip("/") + "/" + dialog_dir_name
	var actor_path = dialog_path + "/Actors"
	var line_path = dialog_path + "/Lines"
	var convo_path = dialog_path + "/Conversations"
	var group_path = dialog_path + "/Groups"
	var choice_path = dialog_path + "/Choices"

	# Create the base Data directory if it doesn't exist
	if not DirAccess.dir_exists_absolute(base_path):
		var make_dir_result = DirAccess.make_dir_recursive_absolute(base_path)
		if make_dir_result != OK:
			printerr("Error: Could not create base directory:", base_path, "Error code:", make_dir_result)
			return false

	# Create the Dialog subdirectory and its children if they don't exist
	if not DirAccess.dir_exists_absolute(dialog_path):
		var make_dir_result = DirAccess.make_dir_recursive_absolute(dialog_path)
		if make_dir_result != OK:
			printerr("Error: Could not create dialog directory:", dialog_path, "Error code:", make_dir_result)
			return false
		DirAccess.make_dir_recursive_absolute(actor_path)
		DirAccess.make_dir_recursive_absolute(line_path)
		DirAccess.make_dir_recursive_absolute(convo_path)
		DirAccess.make_dir_recursive_absolute(group_path)
		DirAccess.make_dir_recursive_absolute(choice_path)
	return true

func find_dialog_resources(base_path: String = "res://Data", dialog_dir_name: String = "Dialog") -> Array:
	var resources : Array = []
	var dialog_path = base_path.rstrip("/") + "/" + dialog_dir_name
	var dir_access = DirAccess.open(dialog_path)

	if dir_access == null:
		printerr("Error: Could not open dialog directory:", dialog_path)
		return [] # Return an empty array if the directory can't be opened

	var subdirectories = ["Actors", "Lines", "Conversations", "Groups", "Choices"]
	for subdir in subdirectories:
		var current_dir_path = dialog_path + "/" + subdir
		var current_dir = DirAccess.open(current_dir_path)
		if current_dir == null:
			printerr("Error: Could not open subdirectory:", current_dir_path)
			continue # Skip to the next subdirectory

		current_dir.list_dir_begin()
		var file_name = current_dir.get_next()
		while file_name != "":
			if not current_dir.current_is_dir():
				var full_path = current_dir_path.rstrip("/") + "/" + file_name
				var resource = load(full_path)
				if resource != null:
					resources.append(resource)
			file_name = current_dir.get_next()
		current_dir.list_dir_end()

	return resources

func get_resource_filename(resource: Resource) -> String:
	if resource and not resource.resource_path.is_empty():
		var full_path = resource.resource_path
		var filename = full_path.get_file()  # Get the filename with extension
		return filename.get_basename()       # Get the filename without extension
	else:
		return ""  # Or return null or handle the case as you prefer

func sort_resources(elements : Array):
	Actors.clear()
	Lines.clear()
	Convos.clear()
	Groups.clear()
	Choices.clear()
	
	for r in elements:
		if r is Actor:
			Actors.set(get_resource_filename(r),r)
		if r is DialogLine:
			Lines.set(get_resource_filename(r),r)
		if r is Conversation:
			Convos.set(get_resource_filename(r),r)
		if r is ConversationGroup:
			Groups.set(get_resource_filename(r),r)
		if r is DialogChoice:
			Choices.set(get_resource_filename(r),r)

#create and return a new actor
func create_actor(actor_name : String, pitch_offset : float = 1) -> Actor:
	if Actors.has(actor_name):
		return Actors[actor_name]
	else:
		var A : Actor = Actor.new()
		A.actor_name = actor_name
		
		var path = "res://Data/Dialog/Actors/" + actor_name + ".tres"
		var error = ResourceSaver.save(A,path)
		if error == OK:
			print("successfully created new Actor  " + actor_name)
			Actors.set(actor_name,A)
			return A
		else:
			printerr("failed to create Actor " + actor_name + " Path: " + path + " Error: " + error)
			return null
	pass

#create and return a new line
func create_line(actor_name : String,group_name : String,convo_name : String, line_name : String, line : String, flags : Array[String], typewriter : bool, choices : bool, choice_name : String) -> DialogLine:
	if Lines.has(line_name):
		var l : DialogLine = Lines[line_name]
		l.actor = create_actor(actor_name)
		l.line = line
		l.flags = flags
		l.typewriter = typewriter
		l.use_choices = choices
		if l.use_choices:
			l.choice = create_choice(choice_name)
		add_line_to_convo(l,group_name,convo_name)
		return l
	else:
		var l : DialogLine = DialogLine.new()
		l.actor = create_actor(actor_name)
		l.line = line
		l.flags = flags
		l.typewriter = typewriter
		l.use_choices = choices
		if l.use_choices:
			l.choice = create_choice(choice_name)
		
		var path = "res://Data/Dialog/Lines/" + line_name + ".tres"
		var error = ResourceSaver.save(l,path)
		if error == OK:
			print("successfully created new line  " + line_name)
			Lines.set(line_name,l)
			add_line_to_convo(l,group_name,convo_name)
			return l
		else:
			printerr("failed to create Line " + line_name + " Path: " + path + " Error: " + error)
			return null
		
		add_line_to_convo(l,group_name,convo_name)

##adds a line to the conversation
func add_line_to_convo(line : DialogLine , group_name : String, convo_name : String):
	var c : Conversation = create_convo(convo_name,group_name)
	var already_added : bool = false
	
	if c.lines.has(line):
		print("convo " + convo_name + " already contains " + line.resource_name)
	else:
		c.lines.append(line)
		print("added line " + line.resource_name + " to convo ", convo_name)

#create and setup a conversation
func create_convo(convo_name : String, group_name  : String= "", required_flag : Array[String] = []) -> Conversation:
	if Convos.has(convo_name):
		var c : Conversation = Convos[convo_name]
		if c.required_flags != required_flag:
			c.required_flags = required_flag
		if group_name!="":
			assign_convo_to_group(c,group_name)
		print("successfully updated conversation ", convo_name)
		return c
	else:
		var c : Conversation = Conversation.new()
		c.required_flags = required_flag
		var path = "res://Data/Dialog/Conversations/" + convo_name + ".tres"
		var error = ResourceSaver.save(c,path)
		if error == OK:
			print("successfully created new conversation  " + convo_name)
			Convos.set(convo_name,c)
			if group_name!="":
				assign_convo_to_group(c,group_name)
			return c
		else:
			printerr("failed to create Conversation " + convo_name + " Path: " + path + " Error: " + error)
			return null
	pass

##assign a conversation to a group
func assign_convo_to_group(convo : Conversation, group_name : String):
	var g : ConversationGroup = create_group(group_name)
	var already_added : bool = false
	
	if g.priority_conversations.has(convo) or g.basic_conversations.has(convo) or g.approved_priority_conversations.has(convo) or g.fallback_conversation == convo:
		print("group " + group_name + " already contains " + convo.resource_name)
	else:
		if convo.required_flags.size() == 0:
			g.basic_conversations.append(convo)
			print("convo has no flags, appending to basic conversations")
		else:
			g.priority_conversations.append(convo)
			print("convo has " + str(convo.required_flags.size()) + " flags, appending to priority conversations")

##create and setup a group
func create_group(group_name : String) -> ConversationGroup:
	if Groups.has(group_name):
		var g = Groups[group_name]
		print("group already existed, returning")
		return g
	else:
		var g = ConversationGroup.new()
		print("creating new group " , group_name)
		var path = "res://Data/Dialog/Groups/" + group_name + ".tres"
		var error = ResourceSaver.save(g,path)
		if error == OK:
			print("successfully created new conversation group " + group_name)
			Groups.set(group_name,g)
			return g
		else:
			printerr("failed to create group " + group_name + " Path: " + path + " Error: " + error)
			return null
	pass

#create and return a voiced dialog line
func create_voice_line(actor_name : String,group_name : String,convo_name : String, line_name : String, line : String, flags : Array[String], typewriter : bool, choices : bool, choice_name : String) -> VoicedDialogLine:
	if Lines.has(line_name):
		var l : VoicedDialogLine = Lines[line_name]
		l.voiced_line = null
		l.actor = create_actor(actor_name)
		l.line = line
		l.flags = flags
		l.typewriter = typewriter
		l.use_choices = choices
		l.choice = create_choice(choice_name)
		if l.use_choices:
			l.choice = create_choice(choice_name)
		return l
	else:
		var l : VoicedDialogLine = VoicedDialogLine.new()
		l.actor = create_actor(actor_name)
		l.line = line
		l.flags = flags
		l.typewriter = typewriter
		l.use_choices = choices
		if l.use_choices:
			l.choice = create_choice(choice_name)
		
		var path = "res://Data/Dialog/Lines/" + line_name + ".tres"
		var error = ResourceSaver.save(l,path)
		if error == OK:
			print("successfully created new line  " + line_name)
			Lines.set(line_name,l)
			add_line_to_convo(l,group_name,convo_name)
			return l
		else:
			printerr("failed to create Line " + line_name + " Path: " + path + " Error: " + error)
			return null
		
		add_line_to_convo(l,group_name,convo_name)

#create and return a choice
func create_choice(choice_name : String, choice_1_text : String = "", choice_1_convo : String = "", choice_1_flags : Array[String] = [], choice_2_text : String= "", choice_2_convo : String= "", choice_2_flags : Array[String]= []) -> DialogChoice:
	if Choices.has(choice_name):
		var c : DialogChoice = Choices[choice_name]
		if c.choice_one_text != choice_1_text and choice_1_text != "":
			c.choice_one_text = choice_1_text
		if c.choice_two_text != choice_2_text and choice_2_text != "":
			c.choice_two_text = choice_2_text
		if choice_1_flags != []:
			c.choice_one_flags = choice_1_flags
		if choice_2_flags != []:
			c.choice_two_flags = choice_2_flags
		c.choice_one_conversation = create_convo(choice_1_convo)
		c.choice_two_conversation = create_convo(choice_2_convo)
		return c
	else:
		var c : DialogChoice = DialogChoice.new()
		c.choice_one_text = choice_1_text
		c.choice_two_text = choice_2_text
		c.choice_one_flags = choice_1_flags
		c.choice_two_flags = choice_2_flags
		c.choice_one_conversation = create_convo(choice_1_convo)
		c.choice_two_conversation = create_convo(choice_2_convo)
		
		var path = "res://Data/Dialog/Choices/" + choice_name + ".tres"
		var error = ResourceSaver.save(c,path)
		if error == OK:
			print("successfully created new Choice  " + choice_name)
			Choices.set(choice_name,c)
			return c
		else:
			printerr("failed to create choice " + choice_name + " Path: " + path + " Error: " + error)
			return null
	pass
