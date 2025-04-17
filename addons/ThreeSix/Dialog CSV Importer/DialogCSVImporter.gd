@tool
extends EditorPlugin
class_name dialog_importer

var control : PackedScene
var instance : csv_ui
var entries : Array[csvDataContainer] = []
var Actors : Dictionary[String,Actor]
var Lines : Dictionary[String,DialogLine]
var Convos :Dictionary[String,Conversation] 
var groups : Dictionary[String,ConversationGroup] 
var choices : Dictionary[String,DialogChoice] 

var new_entries : int = 0
var changed_entires : int = 0
var total_entries : int = 0
var time_taken : float = 0.0

var csv_array : Array = []
var csv_string : String

var csv_loaded : bool = false

var sheet_id : String
var sheet_num : int = 0


func _enter_tree() -> void:
	# create the control
	control = load("res://addons/ThreeSix/Dialog CSV Importer/DialogImporterUI.tscn")
	instance = control.instantiate()
	instance.parent = self
	add_control_to_dock(EditorPlugin.DOCK_SLOT_LEFT_UL,instance)
	
	#connect signals to the buttons
	connect_signals()

##connect all the signals we need
func connect_signals():
	instance.get_load_csv_button().pressed.connect(on_load_csv)
	instance.get_parse_csv_button().pressed.connect(on_parse_csv)
	instance.get_create_resources().pressed.connect(on_create_resources)
	instance.get_https().request_completed.connect(on_https_finish)

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

func format_url(url : String) -> String:
	url = instance.get_url()
	sheet_num = instance.get_sheet_number()
	sheet_id = extract_sheet_id(url)
	var complete_String : String = "https://docs.google.com/spreadsheets/d/" + sheet_id + "/export?format=csv&gid=" + str(sheet_num)
	#print("Complete URL: " , complete_String)
	return complete_String

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

func get_resource_filename(resource: Resource) -> String:
	if resource and not resource.resource_path.is_empty():
		var full_path = resource.resource_path
		var filename = full_path.get_file()  # Get the filename with extension
		return filename.get_basename()       # Get the filename without extension
	else:
		return ""  # Or return null or handle the case as you prefer

func on_parse_csv():
	print("parse CSV")
	pass

func on_create_resources():
	print("create resources")
	pass

##parse our webpage navigating redirects until we get the csv we need
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
	else:
		pass
		#printerr("Failed to download CSV. Result:", result, "Response Code:", response_code)
	pass
