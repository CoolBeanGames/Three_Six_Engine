extends AudioStreamPlayer
class_name audio_player

func _on_finished() -> void:
	AudioManager.stream_finished.emit(self)
	AudioManager.push_p(self)
