extends Area3D


const SPEED = 20.0
@onready var despawn_timer = $DespawnTimer
@onready var animation_player = $AnimationPlayer
@onready var audio_stream_player = $AudioStreamPlayer3D
@export var pizza_throw_sounds: Array[AudioStreamWAV]
@export var pizza_hit_sounds: Array[AudioStreamWAV]
var hit = false


func _ready():
	despawn_timer.start()
	
	var audio_stream = pizza_throw_sounds.pick_random()
	audio_stream_player.stream = audio_stream
	audio_stream_player.play()


func _process(delta):
	if !hit:
		position += transform.basis * Vector3(0, 0, -SPEED) * delta


func _on_body_entered(body):
	hit = true
	animation_player.stop()
	
	if body is InteractableButton:
		var button = body as InteractableButton
		button.activate_button()
		queue_free()
	elif body is NPC:
		var npc = body as NPC
		npc.start_dialogue()
		queue_free()
	else:
		var audio_stream = pizza_hit_sounds.pick_random()
		audio_stream_player.stream = audio_stream
		audio_stream_player.volume_db = 0
		audio_stream_player.play()
		await audio_stream_player.finished
		await get_tree().create_timer(3.0).timeout
		queue_free()


func _on_despawn_timer_timeout():
	queue_free()
