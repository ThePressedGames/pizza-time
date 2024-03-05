class_name InteractableButton
extends StaticBody3D


@onready var audio_stream_player = $AudioStreamPlayer3D
@export var movable_platforms: Array[MovableElement]
@export var button_sounds: Array[AudioStreamWAV]


func activate_button():
	var audio_stream = button_sounds.pick_random()
	audio_stream_player.stream = audio_stream
	audio_stream_player.play()
	
	for movable_platform in movable_platforms:
		movable_platform.move_platform()
