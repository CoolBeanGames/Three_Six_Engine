extends Node
class_name AudioManager

enum audio_type {sfx,music,vocal}

@onready var Pools : PackedScene = load("res://Kit/Audio Manager/audio_manager.tscn")
@onready var player : PackedScene = load("res://Kit/Audio Manager/audio_player.tscn")
var Active_Players : Node
var Inactive_Players : Node
var inactive_count : int

signal player_spawned(audioplayer : AudioPlayer)
signal player_pushed(audioplayer : AudioPlayer)
signal stream_finished(audioplayer : AudioPlayer)

func _ready() -> void:
	spawn_pools()

func spawn_pools():
	await get_tree().process_frame
	#get our references for spawning
	var p = Pools.instantiate()
	p.name = "audio_pools"
	get_tree().root.add_child(p)
	Active_Players = p.get_child(0)
	Inactive_Players = p.get_child(1)

func get_inactive_count() -> int:
	return Inactive_Players.get_child_count()

func spawn_player(parent : Node) -> AudioPlayer:
	var p = player.instantiate()
	parent.add_child(p)
	p.autoplay = false
	player_spawned.emit(p)
	return p

func pop_p() -> AudioPlayer:
	if get_inactive_count() > 0:
		var p = Inactive_Players.get_child(0)
		Inactive_Players.remove_child(p)
		Active_Players.add_child(p)
		return p
	else:
		var p = spawn_player(Active_Players)
		return p

func push_p(player : AudioPlayer):
	if Active_Players.get_children().has(player):
		Active_Players.remove_child(player)
		Inactive_Players.add_child(player)
		player_pushed.emit(player)

func Create(stream : AudioStream, random_pitch : bool = true, type : audio_type = audio_type.sfx, volume : float = 1, pitch_offset : float = 0) -> AudioPlayer:
	var p : AudioPlayer = pop_p()
	volume = linear_to_db(volume)
	setup_audio(p,stream,random_pitch,type,volume,pitch_offset)
	p.play(0.0)
	print("started audio")
	return p

func setup_audio(p : AudioPlayer, stream : AudioStream, random_pitch : bool , type : audio_type , volume : float, pitch_offset : float ):
	p.stream = stream
	p.volume_db = volume
	p.autoplay = false
	if random_pitch:
		p.pitch_scale = randf_range(0.9,1.1) + pitch_offset
	else:
		p.pitch_scale = 1
