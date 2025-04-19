extends DialogLine
class_name VoicedDialogLine

@export_category("voice")
@export var voiced_line : AudioStream
@export_category("voice confirmation")
@export var end_on_voice_end : bool = false
@export var end_time_buffer : float = 1
@export var allow_skip : bool = false
