class_name flag_watcher

##the name of the node connected to the flag
@export var watcher_name : String
##the function to call when the flag is triggered
@export var callback : Callable
##the type of callback for the flag
@export var type : watch_type

enum watch_type {always,only_true,only_false,one_shot,only_true_one_shot,only_false_one_shot}
