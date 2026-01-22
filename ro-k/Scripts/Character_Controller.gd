extends CharacterBody2D

signal player_died # New signal

const SPEED = 500.0
const JUMP_VELOCITY = -400.0
const FALL_GRAVITY_MULTIPLIER = 2.0

# --- HEALTH SETTINGS ---
@export var max_health: float = 100.0
var current_health: float

@onready var animation = $AnimationPlayer
@onready var sprite = $Sprite2D
@onready var health_bar = $TextureProgressBar # Make sure you added this node!

var is_combat_locked = false 

func _ready():
	current_health = max_health
	if health_bar:
		health_bar.max_value = max_health
		health_bar.value = current_health
		health_bar.visible = false # Hidden by default (World Mode)

func _physics_process(delta: float) -> void:
	# 1. Apply Gravity
	if not is_on_floor():
		var current_gravity = get_gravity()
		if velocity.y > 0:
			velocity += current_gravity * FALL_GRAVITY_MULTIPLIER * delta
		else:
			velocity += current_gravity * delta

	# 2. COMBAT LOCK
	if is_combat_locked:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		move_and_slide()
		if is_on_floor() and animation.current_animation != "Attack Animation":
			animation.play("Idle Animation")
		return 

	# 3. INPUT GUARD
	var is_busy = false
	if animation.current_animation == "Attack Animation" and animation.is_playing():
		is_busy = true
	elif animation.current_animation == "Jump Animation" and is_on_floor():
		is_busy = true
		
	if is_busy:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		move_and_slide()
		return 

	# 4. Handle Inputs
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		animation.play("Jump Animation", 0.1)
		
	if Input.is_action_just_pressed("Attack"):
		animation.play("Attack Animation", 0.1)
		velocity.x = 0 

	var direction := Input.get_axis("ui_left", "ui_right")
	if direction:
		velocity.x = direction * SPEED
		if direction < 0:
			sprite.flip_h = true
		else:
			sprite.flip_h = false
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()
	update_animations(direction)

func apply_jump_force():
	velocity.y = JUMP_VELOCITY

func update_animations(direction):
	if animation.current_animation == "Attack Animation": return 
	if animation.current_animation == "Jump Animation": return 

	if direction != 0:
		animation.play("Walk Animation", 0.1)
	else:
		animation.play("Idle Animation", 0.1)

# --- COMBAT FUNCTIONS ---
func enter_combat_state():
	is_combat_locked = true
	velocity.x = 0 
	if health_bar: health_bar.visible = true # Show Bar

func exit_combat_state():
	is_combat_locked = false
	if health_bar: health_bar.visible = false # Hide Bar

func take_damage(amount):
	current_health -= amount
	if health_bar: health_bar.value = current_health
	
	print("PLAYER: Ouch! Health: ", current_health)
	
	if current_health <= 0:
		die()
	else:
		# Optional: Play hurt animation here if you have one
		sprite.modulate = Color.RED # Flash red temporarily
		await get_tree().create_timer(0.2).timeout
		sprite.modulate = Color.WHITE

func die():
	print("PLAYER DIED")
	emit_signal("player_died")
	# Handle death logic (Reload scene, Game Over screen, etc.)
	get_tree().reload_current_scene()
