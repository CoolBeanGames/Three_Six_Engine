@tool
extends EditorPlugin
class_name dialog_importer

var control : PackedScene ##the control to instantiate
var instance : csv_ui ##a pointer to the UI
var entries : Array[csvDataContainer] = [] ##the total list of entries to parse
var Actors : Dictionary[String,Actor] ##all of the actor objects in the project
var Lines : Dictionary[String,DialogLine] ##all of the lines in the project
var Convos :Dictionary[String,Conversation]  ##all of the conversations in the project
var groups : Dictionary[String,ConversationGroup]  ##all of the conversation groups in the project
var choices : Dictionary[String,DialogChoice]  ##all of the dialog choices in the project
 
var to_save : Dictionary[String,savable_resource] ## the list of savable resources generated from the csv

var new_entries : int = 0  ##the number of new entries
var changed_entires : int = 0 ## the number of entries that will be changed
var total_entries : int = 0 ##the total ammount of entries in the doc
var time_taken : float = 0.0 ##how long the generater took
var start_time  ##the start time for the process 
var end_time ##the end time for the process


var csv_array : Array = [] ##an array of all the csv data (this is what you will parse)
var csv_string : String ##the string of the csv for showing in the preview box

var csv_loaded : bool = false ##enables the other buttons

var sheet_id : String ##the id for the google sheet
var sheet_num : int = 0 ##which sheet number it is


##start up the script and initialize all of the data
func _enter_tree() -> void:
	# create the control
	control = load("res://addons/ThreeSix/Dialog CSV Importer/DialogImporterUI.tscn")
	instance = control.instantiate()
	instance.parent = self
	add_control_to_dock(EditorPlugin.DOCK_SLOT_LEFT_UL,instance)
	
	#connect signals to the buttons
	connect_signals()

func reset():
	entries = [] ##the total list of entries to parse
	Actors.clear() ##all of the actor objects in the project
	Lines.clear() ##all of the lines in the project
	Convos.clear()  ##all of the conversations in the project
	groups.clear()  ##all of the conversation groups in the project
	choices.clear() ##all of the dialog choices in the project
	 
	to_save.clear() ## the list of savable resources generated from the csv
	new_entries = 0  ##the number of new entries
	changed_entires = 0 ## the number of entries that will be changed
	total_entries = 0 ##the total ammount of entries in the doc
	time_taken = 0.0 ##how long the generater took
	start_time  ##the start time for the process 
	end_time ##the end time for the process
	csv_array = [] ##an array of all the csv data (this is what you will parse)
	csv_string ##the string of the csv for showing in the preview box
	csv_loaded = false ##enables the other buttons
	
	update_strings()
	reset_timer()

##connect all the signals we need
func connect_signals():
	instance.get_load_csv_button().pressed.connect(on_load_csv)
	instance.get_parse_csv_button().pressed.connect(on_parse_csv)
	instance.get_create_resources().pressed.connect(on_create_resources)
	instance.get_https().request_completed.connect(on_https_finish)

##disconnect all signals when we exit the tree
func disconnect_signals():
	if instance.get_load_csv_button().pressed.get_connections().size() > 0:
		instance.get_load_csv_button().pressed.disconnect(on_load_csv)
	if instance.get_parse_csv_button().pressed.get_connections().size() > 0:
		instance.get_parse_csv_button().pressed.disconnect(on_parse_csv)
	if instance.get_create_resources().pressed.get_connections().size() > 0:
		instance.get_create_resources().pressed.disconnect(on_create_resources)
	if instance.get_https().pressed.get_connections().size() > 0:
		instance.get_https().request_completed.disconnect(on_https_finish)

##update all of the text at the bottom of the box
func update_strings():
	instance.update_changed_entries(str(changed_entires))
	instance.update_new_entries(str(new_entries))
	instance.update_entries_created(str(total_entries))
	instance.update_time_taken(time_taken)

##start a timer to see how long a process takes
func start_timer():
	start_time = Time.get_ticks_msec()
	print("start time: ", start_time)

##finish the timer and update strings
func end_timer():
	end_time = Time.get_ticks_msec()
	print("end time: " , end_time)
	time_taken = end_time - start_time
	print("time taken: " , time_taken)
	update_strings()

##reset the timer to prep for the next one
func reset_timer():
	start_time = 0
	end_time = 0

##remove the tree
func _exit_tree() -> void:
	remove_control_from_bottom_panel(instance)
	instance.queue_free()

##reload files
func reload_files():
	get_editor_interface().get_resource_filesystem().scan_sources()

##start loadig in the data
func on_load_csv():
	print("load csv")
	start_timer()
	load_and_sort_dialog_resources()
	var URL : String= instance.get_url()
	if URL.contains("https://docs.google.com/spreadsheets"):
		#link is good continue
		#print("URL is good, continuing import process")
		start_https(URL)

##make all directories, load the resources, and sort them into the list
func load_and_sort_dialog_resources(base_path: String = "res://Data") :
	ensure_dialog_directories()
	var res :Array = find_dialog_resources()
	sort_resources(res)

##start the https request
func start_https(url : String):
	var req : HTTPRequest = instance.get_https()
	req.max_redirects = 1000
	var formatted_url = format_url(url) # This will now use the /export method
	#print("Attempting to download from:", formatted_url) # Keep this for debugging
	var error = req.request(formatted_url)

##format a google docs url into a download csv one and return it
func format_url(url : String) -> String:
	url = instance.get_url()
	sheet_num = instance.get_sheet_number()
	sheet_id = extract_sheet_id(url)
	var complete_String : String = "https://docs.google.com/spreadsheets/d/" + sheet_id + "/export?format=csv&gid=" + str(sheet_num)
	#print("Complete URL: " , complete_String)
	return complete_String

##find all of the dialog resources in the project
func find_dialog_resources(base_path: String = "res://Data", dialog_dir_name: String = "Dialog") -> Array:
	var resources : Array = []
	var dialog_path = base_path.rstrip("/") + "/" + dialog_dir_name
	var dir_access = DirAccess.open(dialog_path)

	if dir_access == null:
		#printerr("Error: Could not open dialog directory:", dialog_path)
		return [] # Return an empty array if the directory can't be opened

	var subdirectories = ["Actors", "Lines", "Conversations", "Groups", "Choices"]
	for subdir in subdirectories:
		var current_dir_path = dialog_path + "/" + subdir
		var current_dir = DirAccess.open(current_dir_path)
		if current_dir == null:
			#printerr("Error: Could not open subdirectory:", current_dir_path)
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

##get the sheet ID from a complete google drive sheets link
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

##make sure the needed directories exist, if they done: create them
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
			#printerr("Error: Could not create base directory:", base_path, "Error code:", make_dir_result)
			return false

	# Create the Dialog subdirectory and its children if they don't exist
	if not DirAccess.dir_exists_absolute(dialog_path):
		var make_dir_result = DirAccess.make_dir_recursive_absolute(dialog_path)
		if make_dir_result != OK:
			#printerr("Error: Could not create dialog directory:", dialog_path, "Error code:", make_dir_result)
			return false
		DirAccess.make_dir_recursive_absolute(actor_path)
		DirAccess.make_dir_recursive_absolute(line_path)
		DirAccess.make_dir_recursive_absolute(convo_path)
		DirAccess.make_dir_recursive_absolute(group_path)
		DirAccess.make_dir_recursive_absolute(choice_path)
	return true

##sorts all of the loaded resources into the correct dictionary
func sort_resources(elements : Array):
	Actors.clear()
	Lines.clear()
	Convos.clear()
	groups.clear()
	choices.clear()
	
	for r in elements:
		if r is Actor:
			Actors.set(r.resource_name,r)
		if r is DialogLine:
			Lines.set(r.resource_name,r)
		if r is Conversation:
			Convos.set(r.resource_name,r)
		if r is ConversationGroup:
			groups.set(r.resource_name,r)
		if r is DialogChoice:
			choices.set(r.resource_name,r)

##HELPER: gets the filename for a single resource
func get_resource_filename(resource: Resource) -> String:
	if resource and not resource.resource_path.is_empty():
		var full_path = resource.resource_path
		var filename = full_path.get_file()  # Get the filename with extension
		return filename.get_basename()       # Get the filename without extension
	else:
		return ""  # Or return null or handle the case as you prefer

#when we press the parse csv button set up our data
func on_parse_csv():
	print("parse CSV")
	start_timer()
	parse_csv()
	end_timer()
	pass

func on_create_resources():
	print("create resources")
	reset_timer()
	start_timer()
	save_res()
	end_timer()
	pass

##actually save all of our resources
func save_res():
	for i  in to_save:
		var entry : savable_resource = to_save[i]
		ResourceSaver.save(entry.resource,entry.path)

##parse our webpage navigating redirects until we get the csv we need
##this is the actual loading conde that loads the web page, downloads the csv, and
##preps it for processing
func on_https_finish(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	print("https finished")
	#print("HTTPS Request Completed: ", body.get_string_from_utf8())
	var csv_string = body.get_string_from_utf8()
	var lines : PackedStringArray = csv_string.split("\n")
	
	var data_lines = []
	
	for i in range(lines.size()):
		if i > 0 or lines.size() == 1:
			data_lines.append(lines[i])
	
	var data_string = str(data_lines) 
	
	csv_string = data_string

	if response_code == 302 or response_code == 307: # Check for redirect status codes
		var body_string = body.get_string_from_utf8()
		var redirect_url_start = body_string.find("<A HREF=\"")
		if redirect_url_start != -1:
			redirect_url_start += 9 # Move past "<A HREF=\""
			var redirect_url_end = body_string.find("\">", redirect_url_start)
			if redirect_url_end != -1:
				var redirect_url = body_string.substr(redirect_url_start, redirect_url_end - redirect_url_start)
				#print("Following redirect to:", redirect_url)
				instance.get_https().request(redirect_url) # Make a new request to the redirected URL
				return # Important: Exit this function to avoid further processing of the redirect HTML
		else:
			#printerr("Error: Could not find redirect URL in response.")
			return
	elif result == HTTPRequest.RESULT_SUCCESS and response_code == 200:
		var csv_text = body.get_string_from_utf8()
		var rows = csv_text.split("\n", false)
		csv_array.clear() # Clear the previous data
		for row_string in rows:
			var columns = row_string.split(",", false)
			csv_array.append(columns)
		#print("Parsed CSV Data:", csv)
		csv_loaded = true
		instance.update_csv_preview(csv_string)
		
		total_entries = csv_array.size()
		end_timer()
	else:
		pass
		#printerr("Failed to download CSV. Result:", result, "Response Code:", response_code)
	pass

## this function goes through and sets up all of the data, no files get created
## but it does Prep files for creation
func parse_csv():
	var index : int = 0
	for s in csv_array:
		if index >= 1: #for skipping the header
			var data : csvDataContainer = csvDataContainer.new()
##-------------------------------------------------------------------------------------------------
			#create our actor data
			data.actor_name = s[0] if s.size() > 0 else ""
			data.actor_object = create_actor(data.actor_name)
##-------------------------------------------------------------------------------------------------
			#create our group data
			data.group_name = s[1] if s.size() > 1 else ""
			data.group_object = create_group(data.group_name)
##-------------------------------------------------------------------------------------------------
			#create our conversation data
			data.convo_name = s[2] if s.size() > 2 else ""

			#load in the flags
			data.flags = []
			if s.size() > 3 and not s[3].is_empty():
				var flags_packed = s[3].split(" ")
				for flag in flags_packed:
					data.flags.append(flag)

			data.convo_object = create_convo(data)
##-------------------------------------------------------------------------------------------------
			#set a few bools
			data.use_typewriter = bool(str(s[6] if s.size() > 6 else "false").to_lower() == "true")
			data.is_voiced = bool(str(s[7] if s.size() > 7 else "false").to_lower() == "true")
			data.has_choice = bool(str(s[8] if s.size() > 8 else "false").to_lower() == "true")
##-------------------------------------------------------------------------------------------------
			#setup the choice
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

			data.choice_1_Convo_Object = get_convo(data.choice_1_Convo_Name)
			data.choice_2_Convo_Object = get_convo(data.choice_2_Convo_Name)
			data.choice_object = create_choice(data)
			
##-------------------------------------------------------------------------------------------------
			#setup the line
			data.line_name = s[4] if s.size() > 4 else ""
			data.line_text = s[5] if s.size() > 5 else ""
			

			if data.is_voiced:
				data.line_object = create_voiced_line(data)
			else:
				data.line_object = create_line(data)
			
			entries.append(data)
		index += 1
	#print("\n \n Entries Created:")
	get_editor_interface().get_resource_filesystem().scan()
	
	#print(entries)

##given a resource assign the data to the correct structure, add it to the list and return it
func prep_resource_for_saving(name : String, path : String, res : Resource) -> savable_resource:
	var entry : savable_resource = savable_resource.new()
	entry.resource_name = name
	entry.resource = res
	entry.path = path
	to_save.set(name,entry)
	return entry

##attempt to grab an actor object or create a new one if needed then return it
func create_actor(name : String, pitch : float = 1) -> Actor:
	var is_new : bool 
	var is_changed : bool = false
	var A : Actor
	if Actors.has(name):
		print("actor ", name, " already exists")
		A  = Actors[name]
		is_new=false
	else:
		A = Actor.new()
		is_new = true
	
	##start setting up fields
	
	#pitch
	if pitch != A.pitch_offset and !is_new:
		A.pitch_offset = pitch
		is_changed = true
	
	#name
	if A.actor_name != name:
		A.actor_name = name
		is_changed = true
	
	##update counts
	if is_changed:
		changed_entires += 1
	
	if is_new:
		new_entries += 1
	
	update_strings()
	
	##prep for saving if we need to
	if is_changed or is_new:
		prep_resource_for_saving(name,"res://Data/Dialog/Actors/" + name + ".tres",A)
	return A

##creates and returns a conversation group
func create_group(name : String) -> ConversationGroup:
	var g : ConversationGroup
	var is_new : bool = false
	if groups.has(name):
		g = groups[name]
	else:
		g = ConversationGroup.new()
		is_new = true
	
	##setup fields
	if is_new:
		new_entries += 1
		prep_resource_for_saving(name,"res://Data/Dialog/Groups/" + name + ".tres",g)
		update_strings()
	
	return g

##returns a group, creates a new one if it doesnt exist (otherwise doesnt update data or save)
func get_group(name : String) -> ConversationGroup:
	if groups.has(name):
		return groups[name]
	else:
		return create_group(name)

##create a new conversation or return an existing one
func create_convo(data : csvDataContainer) -> Conversation:
	var is_new : bool
	var is_changed : bool
	var c : Conversation
	
	#get the data
	if Convos.has(data.convo_name):
		c = Convos[data.convo_name]
		is_new=false
	else:
		c = Conversation.new()
		is_new=true
	
	#did we change the flags?
	if data.flags != c.required_flags:
		is_changed = true
		c.required_flags = data.flags
	
	#do we need to save?
	if is_new:
		new_entries += 1
	if is_changed:
		changed_entires +=1
	
	#prep for saving phase
	if is_new or is_changed:
		prep_resource_for_saving(data.convo_name,"res://Data/Dialog/Conversations/"+name+".tres",c)
	
	add_convo_to_group(c,data.convo_name,data.group_name)
	return c

#adds a conversation to a group
func add_convo_to_group(c : Conversation,convo_name : String, group_name : String):
	var g : ConversationGroup = get_group(group_name)
	var in_group : bool = false
	for x in g.basic_conversations:
		if x.resource_name == convo_name:
			in_group = true
			break
	if !in_group:
		for y in g.priority_conversations:
			if y.resource_name == convo_name:
				in_group = true
				break
		if !in_group:
			for z in g.approved_priority_conversations:
				if z.resource_name == convo_name:
					in_group = true
					break
	if !in_group:
		g.basic_conversations.append(c)
		if !to_save.has(group_name):
			changed_entires+=1
			to_save.set(group_name,g)

##return a conversation
func get_convo(name : String) -> Conversation:
	if Convos.has(name):
		return Convos[name]
	else:
		var dat : csvDataContainer = csvDataContainer.new()
		dat.convo_name = name
		return create_convo(dat)

func create_choice(data : csvDataContainer) -> DialogChoice:
	var c : DialogChoice 
	var is_new : bool = false
	var is_changed : bool = false
	
	#get our instance
	if choices.has(name):
		c= choices[name]
	else:
		c= DialogChoice.new()
	
	#check if any of the data has changed
	if c.choice_one_conversation != data.choice_1_Convo_Object or c.choice_one_conversation.resource_name != data.choice_1_Convo_Name:
		is_changed = true
		c.choice_one_conversation = data.choice_1_Convo_Object
	if c.choice_two_conversation != data.choice_2_Convo_Object or c.choice_two_conversation.resource_name != data.choice_2_Convo_Name:
		is_changed = true
		c.choice_one_conversation = data.choice_1_Convo_Object
	if c.choice_one_text != data.choice_1_Text:
		is_changed = true
		c.choice_one_text = data.choice_1_Text
	if c.choice_two_text != data.choice_2_Text:
		is_changed = true
		c.choice_two_text = data.choice_2_Text
	if c.choice_one_flags != data.choice_1_Flags:
		is_changed = true
		c.choice_one_flags = data.choice_1_Flags
	if c.choice_two_flags != data.choice_2_Flags:
		is_changed = true
		c.choice_one_flags = data.choice_2_Flags
	
	#update string entries
	if is_new:
		new_entries += 1
	if is_changed:
		changed_entires += 1
	
	#prep for saving and return
	if is_new or is_changed:
		prep_resource_for_saving(data.choice_name,"res://Data/Dialog/Choices/" + name + ".tres",c)
	
	return c

##return or create a choice object
func get_choice(name : String) -> DialogChoice:
	if choices.has(name):
		return choices[name]
	else:
		var dat : csvDataContainer = csvDataContainer.new()
		dat.choice_1_Text = ""
		dat.choice_2_Text = ""
		dat.choice_1_Flags = []
		dat.choice_2_Flags = []
		dat.choice_1_Convo_Name = ""
		dat.choice_2_Convo_Name = ""
		dat.choice_1_Convo_Object = null
		dat.choice_2_Convo_Object = null
		dat.choice_name = name
		return create_choice(dat)

func create_line(data : csvDataContainer) -> DialogLine:
	var l : DialogLine
	var is_new : bool = false
	var is_changed : bool = false
	
	
	if is_new:
		new_entries += 1
	if is_changed:
		changed_entires += 1
	
	##go through and update the data if it needs changed
	if data.actor_object != l.actor:
		is_changed = true
		l.actor = create_actor(data.actor_name)
	if data.line_text != l.line:
		is_changed = true
		l.line = data.line_text
	if data.flags != l.flags:
		is_changed = true
		l.flags = data.flags
	if data.use_typewriter != l.typewriter:
		is_changed = true
		l.typewriter = data.use_typewriter
	if data.has_choice != l.use_choices:
		is_changed = true
		l.use_choices = data.has_choice
		if l.use_choices:
			l.choice = get_choice(data.choice_name)	
	
	add_line_to_convo(l,data.line_name,data.convo_name)
	
	if is_new or is_changed:
		prep_resource_for_saving(data.line_name,"res://Data/Dialog/Lines/" + data.line_name + ".tres",l)
	
	return l

##add this line to our conversation
func add_line_to_convo(line : DialogLine, line_name : String, convo_name : String):
	var convo : Conversation = get_convo(convo_name)
	var in_convo : bool = false
	for l in convo.lines:
		if l.resource_name == line_name:
			in_convo = true
			break
	if !in_convo:
		convo.lines.append(line)
		if !to_save.has(convo_name):
			changed_entires+=1
			prep_resource_for_saving(convo_name,"res://Data/Dialog/Conversations/"+convo_name+".tres",convo)

func create_voiced_line(data : csvDataContainer) -> VoicedDialogLine:
	var l : VoicedDialogLine
	var is_new : bool = false
	var is_changed : bool = false
	
	
	if is_new:
		new_entries += 1
	if is_changed:
		changed_entires += 1
	
	##go through and update the data if it needs changed
	if data.actor_object != l.actor:
		is_changed = true
		l.actor = create_actor(data.actor_name)
	if data.line_text != l.line:
		is_changed = true
		l.line = data.line_text
	if data.flags != l.flags:
		is_changed = true
		l.flags = data.flags
	if data.use_typewriter != l.typewriter:
		is_changed = true
		l.typewriter = data.use_typewriter
	if data.has_choice != l.use_choices:
		is_changed = true
		l.use_choices = data.has_choice
		if l.use_choices:
			l.choice = get_choice(data.choice_name)	
	
	add_line_to_convo(l,data.line_name,data.convo_name)
	
	if is_new or is_changed:
		prep_resource_for_saving(data.line_name,"res://Data/Dialog/Lines/" + data.line_name + ".tres",l)
	
	return l

##get or create a dialog line even if we need to make a new one
func get_line(name : String, voiced : bool = false) -> DialogLine:
	if Lines.has(name):
		return Lines[name]
	else:
		var data : csvDataContainer = csvDataContainer.new()
		data.actor_name = ""
		data.line_text = ""
		data.use_typewriter = true
		data.line_name = name
		if voiced:
			data.is_voiced = true
			return create_voiced_line(data)
		else:
			data.is_voiced=false
			return create_line(data)
