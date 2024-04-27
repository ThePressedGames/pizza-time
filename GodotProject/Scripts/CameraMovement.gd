extends Node3D


@onready var underwater_environment= preload("res://Art/Environments/underwater._environment.tres")

@onready var red_path_follow = $RedPath3D/PathFollow3D
@onready var blue_path_follow = $BluePath3D/PathFollow3D
@onready var choice_position = $ChoicePosition
@onready var player = $"../Player"
@onready var player_head = $"../Player/Head"
@onready var player_pizza = $"../Player/Head/WeaponPivot"
@onready var hud = $"../Player/HUD"
@onready var pizza_presence = $"../PizzaPresence"
@onready var pizza_presence_red_area = $"../PizzaPresence/RedPizzaArea3D"
@onready var pizza_presence_blue_area = $"../PizzaPresence/BluePizzaArea3D"
@export var pizza_presence_animation_player: AnimationPlayer
var camera: Camera3D
var camera_speed = .08
var camera_acceleration = .01
var follow_red_path_started = false
var follow_blue_path_started = false
var falling_time = 0.0

var faded_to_black = false
var underwater = false


func _ready():
	camera = get_viewport().get_camera_3d()
	Dialogic.signal_event.connect(end_cinematic)


func end_cinematic(argument: String):
	if argument == "start_choice_cinematic":
		pizza_presence_animation_player.play("Final_purple_pizza")
		
		var tween = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
		tween.tween_property(player_head, "rotation", Vector3.ZERO, 5)
		tween.parallel().tween_property(camera, "rotation", Vector3.ZERO, 5)
		tween.parallel().tween_property(player, "position", choice_position.global_position, 5)
		hud.show_cinematic_bands(true)
	
	if argument == "choice_taken":
		pizza_presence_red_area.monitoring = false
		pizza_presence_blue_area.monitoring = false
		
		var tween = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
		tween.tween_property(camera, "global_rotation", Vector3.DOWN * PI , 2)
		await  tween.finished
		player_pizza.hide()
	
	if argument == "start_red_ending_cinematic":
		Music.play_final_music()
		camera.reparent(red_path_follow)
		follow_red_path_started = true
		await get_tree().create_timer(2.9).timeout
		camera.rotation = Vector3.ZERO
		pizza_presence_animation_player.stop()
	
	if argument == "start_blue_ending_cinematic":
		pizza_presence.hide()
		camera.reparent(blue_path_follow)
		follow_blue_path_started = true 
		var tween = create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
		tween.tween_interval(0.2)
		tween.chain().tween_property(camera, "rotation", Vector3.ZERO, 0.4)
		
	if argument == "lower_music_volume":
		Music.stop_music()


func _process(delta):
	if follow_red_path_started:
		camera.position = lerp(camera.position, Vector3.ZERO, delta * 1.5)
		red_path_follow.progress_ratio = lerp(red_path_follow.progress_ratio, 1.0, delta * camera_speed * 0.5)
		if red_path_follow.progress_ratio >= .9 and !faded_to_black:
			hud.last_hide(.01)
			faded_to_black = true
			
	elif follow_blue_path_started:
		falling_time += delta
		blue_path_follow.progress_ratio += falling_time * camera_speed * 0.07
		
		if blue_path_follow.progress_ratio > 0.35 and !underwater:
			camera.environment = underwater_environment
			Music.play_splash_sfx()
			underwater = true

		if blue_path_follow.progress_ratio >= .9 and !faded_to_black:
			hud.last_hide(3)
			faded_to_black = true
