extends Camera2D

@export var look_ahead_distance = 400.0 
@export var shift_speed = 2.0

var target_offset_x = 0.0
var is_locked = false 
var initial_local_pos = Vector2.ZERO # Store starting position

func _ready():
	# 1. Remember exactly where the camera was placed in the editor
	initial_local_pos = position 
	
	target_offset_x = look_ahead_distance
	offset.x = look_ahead_distance

func _process(delta):
	if is_locked: return 

	var direction = Input.get_axis("ui_left", "ui_right")
	
	if direction > 0:
		target_offset_x = look_ahead_distance
	elif direction < 0:
		target_offset_x = -look_ahead_distance
		
	offset.x = lerp(offset.x, target_offset_x, shift_speed * delta)

func lock_camera():
	if is_locked: return
	
	var current_global_pos = global_position
	top_level = true 
	global_position = current_global_pos
	is_locked = true

func unlock_camera():
	if not is_locked: return
	
	is_locked = false
	top_level = false 
	
	# 2. Return to the ORIGINAL editor position, not (0,0)
	position = initial_local_pos
