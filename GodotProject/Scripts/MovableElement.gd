@tool
class_name MovableElement
extends Node3D


@onready var starting_node = $StartingNode
@onready var ending_node = $EndingNode
@onready var animation_pivot = $Pivot
@onready var audio_stream_player = $AudioStreamPlayer3D

@export var two_way_movement = false
@export var activated = false
@export var is_pausable = false

var tween
@export var animation_duration: float = 2.0
@export var animation_transition_type: Tween.TransitionType = Tween.TRANS_LINEAR
@export var animation_ease_type: Tween.EaseType = Tween.EASE_IN_OUT

@export var move_with_timer = false:
	set(value):
		move_with_timer = value
		notify_property_list_changed()
var animation_interval = 0.0
var auto_start = false

@export var movement_sounds: Array[AudioStreamWAV]

# Editor behaviour function, not important for the actual behaviour of the class
func _get_property_list():
	var property_usage = PROPERTY_USAGE_NO_EDITOR
	
	if move_with_timer:
		property_usage = PROPERTY_USAGE_DEFAULT
	
	var properties = []
	properties.append({
		"name": "animation_interval",
		"type": TYPE_FLOAT,
		"usage": property_usage, # See above assignment.
		"hint": PROPERTY_HINT_NONE,
		"hint_string": "Interval between the end of an animation and the start of the new one"
	})
	properties.append({
		"name": "auto_start",
		"type": TYPE_BOOL,
		"usage": property_usage, # See above assignment.
		"hint": PROPERTY_HINT_NONE,
		"hint_string": ""
	})
	
	return properties


# Reset the platform position and rotation on start
func _ready():
	if activated:
		animation_pivot.position = ending_node.position
		animation_pivot.rotation = ending_node.rotation
	else:
		animation_pivot.position = starting_node.position
		animation_pivot.rotation = starting_node.rotation
	
	if move_with_timer:
		two_way_movement = true
		if auto_start:
			move_platform()


func move_platform():
	# Tween was already created
	if tween != null and tween.is_valid():
		# If tween is pausable execute pause logic, otherwise do nothing
		if is_pausable:
			if tween.is_running():
				tween.pause()
				if audio_stream_player.stream != null:
					audio_stream_player.stream_paused = true
			
			else:
				tween.play()
				if audio_stream_player.stream != null:
					audio_stream_player.stream_paused = false
	# New tween needs to be created
	else:
		var audio_stream = movement_sounds.pick_random()
		audio_stream_player.stream = audio_stream
		
		if !activated:
			_start_animation(true)
			activated = true
			audio_stream_player.play()
		elif two_way_movement:
			_start_animation(false)
			activated = false
			audio_stream_player.play()


func _start_animation(forward: bool):
	tween = create_tween().set_parallel(true).set_trans(animation_transition_type).set_ease(animation_ease_type)
	if forward:
		tween.tween_property(animation_pivot, "position", ending_node.position, animation_duration)
		tween.tween_property(animation_pivot, "rotation", ending_node.rotation, animation_duration)
	else:
		tween.tween_property(animation_pivot, "position", starting_node.position, animation_duration)
		tween.tween_property(animation_pivot, "rotation", starting_node.rotation, animation_duration)
	
	if move_with_timer:
		await tween.chain().tween_interval(animation_interval).finished
		tween = null
		move_platform()
