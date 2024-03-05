class_name  Player
extends CharacterBody3D

# Movement variables
var speed
const WALK_SPEED = 5.0
const SPRINT_SPEED = 8.0
const JUMP_VELOCITY = 4.5
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

# Camera variables
@onready var head = $Head
@onready var camera = $Head/Camera3D
const SENSITIVITY = 0.003
var mouse_captured = false
# Head bob
const BOB_FREQUENCY = 2.0
const BOB_AMPLITUDE = 0.08
var t_bob = 0.0
# FOV
const BASE_FOV = 75.0
const FOV_CHANGE = 1.8

# Stair stepping variables
@onready var wall_detection = $Head/WallDetectionRayCast3D
@onready var step_detection = $Head/StepDetectionRayCast3D

# Weapon & combat variables
@onready var animation_player = $AnimationPlayer
@onready var weapon_model = $Head/WeaponPivot/WeaponModel
var projectile_prefab = preload("res://Scenes/Prefabs/Projectile.tscn")
var projectile_instance
@onready var projectile_throw_trajectory = $Head/Camera3D/ProjectileThrowTrajectory

var Weapon_Attack_Types = {
	"MELEE" = "attack_melee",
	"THROW" = "attack_throw"
}
var weapon_attack_animation = Weapon_Attack_Types["THROW"]

# Audio variables
@onready var audio_stream_player = $AudioStreamPlayer3D
@export var walking_sound: AudioStreamWAV
@export var jumping_sounds: Array[AudioStreamWAV]


func _unhandled_input(event):
	if !mouse_captured:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	# When Dialogue is active, skip camera movement
	if Dialogic.current_timeline != null:
		return
	
	# Camera movement
	if event is InputEventMouseMotion:
		head.rotate_y(-event.relative.x * SENSITIVITY)
		camera.rotate_x(-event.relative.y * SENSITIVITY)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-60), deg_to_rad(80))


func _unhandled_key_input(_event):
	# DEBUGGING PURPOSES
	if Input.is_action_just_pressed("restart"):
		get_tree().reload_current_scene()
	if Input.is_action_just_pressed("quit"):
		await Analytics.handle_exit()
		get_tree().quit()


func _physics_process(delta):
	# When Dialogue is active, skip physics process
	if Dialogic.current_timeline != null:
		return
	
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta
	
	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		
		audio_stream_player.stream = jumping_sounds.pick_random()
		audio_stream_player.play()
	
	# Sprint
	if Input.is_action_pressed("sprint") and is_on_floor():
		speed = SPRINT_SPEED
		audio_stream_player.pitch_scale = 1.1
	else:
		speed = WALK_SPEED
		audio_stream_player.pitch_scale = .8
	
	# Get the input direction and handle the movement/deceleration.
	var input_dir = Input.get_vector("left", "right", "forward", "backward")
	var direction = (head.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if is_on_floor():
		if direction:
			velocity.x = direction.x * speed
			velocity.z = direction.z * speed
			
			if not audio_stream_player.is_playing():
				audio_stream_player.stream = walking_sound
				audio_stream_player.play()
		else:
			velocity.x = lerp(velocity.x, direction.x * speed, delta * 7.0)
			velocity.z = lerp(velocity.z, direction.z * speed, delta * 7.0)
			audio_stream_player.stop()
		
		# Handle stairs/steps
		#if step_detection.is_colliding() and not wall_detection.is_colliding():
			#velocity.y = 2
		
	else:
		velocity.x = lerp(velocity.x, direction.x * speed, delta * 3.0)
		velocity.z = lerp(velocity.z, direction.z * speed, delta * 3.0)
	
	# Head bob
	t_bob += delta * velocity.length() * float(is_on_floor())
	camera.transform.origin = _headbob(t_bob)
	
	# FOV
	var velocity_clamped = clamp(velocity.length(), WALK_SPEED, SPRINT_SPEED * 2)
	var target_fov = BASE_FOV + FOV_CHANGE * velocity_clamped
	camera.fov = lerp(camera.fov, target_fov, delta * 8.0)
	
	# Weapon attack
	if Input.is_action_just_pressed("attack") and !animation_player.is_playing():
		animation_player.play(weapon_attack_animation)
	
	move_and_slide()


func _headbob(time) -> Vector3:
	var pos = Vector3.ZERO
	pos.y = sin(time * BOB_FREQUENCY) * BOB_AMPLITUDE
	pos.x = cos(time * BOB_FREQUENCY / 2) * BOB_AMPLITUDE
	return pos


# Handle enemy hit
func _on_weapon_hitbox_body_entered(body):
	if body is Enemy:
		var enemy = body as Enemy
		enemy.take_hit()
	
	if body is InteractableButton:
		var button = body as InteractableButton
		button.activate_button()


# Handle pickup items
func pickup_item(item_name: String):
	print("Picked up item " + item_name)
	
	if item_name == "Dagger":
		# Change weapon model to dagger one
		weapon_attack_animation = Weapon_Attack_Types["THROW"]
	
	if item_name == "Sword":
		# Change weapon model to dagger one
		weapon_attack_animation = Weapon_Attack_Types["MELEE"]


func _on_animation_player_animation_finished(anim_name):
	if anim_name == "attack_throw":
		projectile_instance = projectile_prefab.instantiate()
		projectile_instance.position = projectile_throw_trajectory.global_position
		projectile_instance.transform.basis = projectile_throw_trajectory.global_transform.basis
		get_parent().add_child(projectile_instance)
		
		Analytics.add_event("Thrown Pizzas")
