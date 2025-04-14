class_name flag_events extends Node

enum watch_type {always,only_true,only_false,one_shot,only_true_one_shot,only_false_one_shot}
@export var Watchers : Dictionary[String,Array] ##anything added to this will be called whenever a flag is changed

func register(flag : String, callback : Callable, type : watch_type, node : Node):
	flag=flag.to_lower()
	var w = create_watcher(node,callback,type)
	if Watchers.has(flag):
		Watchers[flag].append(w)
	else:
		Watchers[flag] = [w]

func deregister(flag : String , node : Node):
	flag=flag.to_lower()
	if Watchers.has(flag):
		var watcher_array = Watchers[flag]
		var removed_count = 0
		# Iterate backwards to safely remove elements
		for i in range(watcher_array.size() - 1, -1, -1):
			var w : flag_watcher = watcher_array[i]
			if is_instance_valid(w) and w.watcher_name == node.name:
				Watchers[flag].remove_at(i)
				removed_count += 1
		if removed_count > 0:
			print("Deregistered", removed_count, "watcher(s) for node", node.name, "on flag", flag)
			return true
		else:
			print("Warning: No watcher found for node", node.name, "on flag", flag)
			return false
	else:
		print("Warning: Flag", flag, "not found in Watchers")
		return false

func set_flag(flag : String, value : bool = true):
	flag=flag.to_lower()
	if Watchers.has(flag):
		var array : Array[flag_watcher] = Watchers[flag]
		var to_remove_indices : Array[int] = []
		for i in range(array.size()-1,-1,-1):
			var w : flag_watcher = array[i]
			match w.type:
				watch_type.only_true:
					if is_instance_valid(w.callback.get_object()) and value:
						w.callback.call()
				watch_type.only_false:
					if is_instance_valid(w.callback.get_object()) and not value:
						w.callback.call()
				watch_type.only_true_one_shot:
					if is_instance_valid(w.callback.get_object()) and value:
						w.callback.call()
						to_remove_indices.append(i)
				watch_type.only_false_one_shot:
					if is_instance_valid(w.callback.get_object()) and not value:
						w.callback.call()
						to_remove_indices.append(i)
				watch_type.one_shot:
					if is_instance_valid(w.callback.get_object()):
						w.callback.call()
						to_remove_indices.append(i)
				watch_type.always:
					if is_instance_valid(w.callback.get_object()):
						w.callback.call()
		
		#remove the indices to remove
		for i in range(to_remove_indices.size()-1,-1,-1):
			Watchers[flag].remove_at(to_remove_indices[i])
		
		if Watchers[flag].is_empty():
			Watchers.erase(flag)

##create and return a single instance of a flag watcher object for registration
func create_watcher(node : Node , callback : Callable , type : watch_type) -> flag_watcher:
	var w = flag_watcher.new()
	w.callback = callback
	w.type = type
	w.watcher_name = node.name
	return w

func read_flag_value(flag : String) -> bool:
	flag=flag.to_lower()
	return Game_Data.flags.get(flag,false)

#completly clear out watchers
func deregister_all(node: Node):
	for flag in Watchers.keys():
		deregister(flag, node)
