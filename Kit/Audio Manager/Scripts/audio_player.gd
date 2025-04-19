extends AudioStreamPlayer
class_name AudioPlayer

var test : AudioPlayer
func _on_finished() -> void:
	Audio_Manager.stream_finished.emit(self)
	Audio_Manager.push_p(self)
