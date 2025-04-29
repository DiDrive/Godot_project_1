extends Node

var audio_players: Array[AudioStreamPlayer2D] = []
const POOL_SIZE = 4  # 初始音效播放器数量

func _ready() -> void:
	# 预先创建音频播放器
	for i in range(POOL_SIZE):
		var player = AudioStreamPlayer2D.new()
		add_child(player)
		audio_players.append(player)

func play_sound(stream: AudioStream, volume_db: float = 0.0) -> void:
	# 查找空闲的播放器
	for player in audio_players:
		if not player.playing:
			player.stream = stream
			player.volume_db = volume_db
			player.play()
			return
	
	# 如果没有空闲播放器，创建新的
	var new_player = AudioStreamPlayer2D.new()
	new_player.stream = stream
	new_player.volume_db = volume_db
	add_child(new_player)
	audio_players.append(new_player)
	new_player.play()
