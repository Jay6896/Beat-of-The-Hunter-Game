extends CharacterBody2D

signal player_died 

const SPEED = 500.0
const JUMP_VELOCITY = -400.0
const FALL_GRAVITY_MULTIPLIER = 2.0
const ZIP_SPEED = 0.25 

@export var max_health: float = 100.0
var current_health: float

@onready var animation = $AnimationPlayer
@onready var sprite = $Sprite2D
@onready var health_bar = $TextureProgressBar 

var is_combat_locked = false 
var original_combat_position = Vector2.ZERO 

func _ready():
	current_health = max_health
	if health_bar:
		health_bar.max_value = max_health
		health_bar.value = current_health
		health_bar.visible = false 

func _physics_process(delta: float) -> void:
	# 1. Apply Gravity (ALWAYS)
	if not is_on_floor():
		var current_gravity = get_gravity()
		if velocity.y > 0:
			velocity += current_gravity * FALL_GRAVITY_MULTIPLIER * delta
		else:
			velocity += current_gravity * delta

	# 2. COMBAT LOCK
	if is_combat_locked:
		# Stop X movement, but allow Y (Gravity) to continue
		velocity.x = move_toward(velocity.x, 0, SPEED)
		move_and_slide()
		
		# Only play idle if we are actually on the floor
		if is_on_floor() and animation.current_animation != "Attack Animation" and velocity.x == 0:
			animation.play("Idle Animation")
		return 

	# 3. INPUT GUARD
	var is_busy = false
	if animation.current_animation == "Attack Animation" and animation.is_playing(): is_busy = true
	elif animation.current_animation == "Jump Animation" and is_on_floor(): is_busy = true
		
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
		if direction < 0: sprite.flip_h = true
		else: sprite.flip_h = false
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()
	update_animations(direction)

func apply_jump_force():
	velocity.y = JUMP_VELOCITY

func update_animations(direction):
	if animation.current_animation == "Attack Animation": return 
	if animation.current_animation == "Jump Animation": return 
	if direction != 0: animation.play("Walk Animation", 0.1)
	else: animation.play("Idle Animation", 0.1)

func enter_combat_state():
	is_combat_locked = true
	# FIXED: Only set X to zero. Keep Y (Gravity/Jump) momentum!
	velocity.x = 0 
	original_combat_position = global_position 
	if health_bar: health_bar.visible = true 

func exit_combat_state():
	is_combat_locked = false
	if health_bar: health_bar.visible = false 

func perform_zip_attack(target_position):
	animation.stop()
	animation.play("Attack Animation")
	
	var tween = create_tween()
	var attack_spot = Vector2(target_position.x - 180, global_position.y)
	tween.tween_property(self, "global_position", attack_spot, ZIP_SPEED).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	await animation.animation_finished
	
	tween = create_tween()
	tween.tween_property(self, "global_position", original_combat_position, ZIP_SPEED).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)

func perform_dodge_zip(distance: float):
	var dodge_spot = Vector2(original_combat_position.x - distance, original_combat_position.y)
	var tween = create_tween()
	tween.tween_property(self, "global_position", dodge_spot, ZIP_SPEED).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	await get_tree().create_timer(0.5).timeout
	tween = create_tween()
	tween.tween_property(self, "global_position", original_combat_position, ZIP_SPEED).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)

func take_damage(amount):
	current_health -= amount
	if health_bar: health_bar.value = current_health
	if current_health <= 0: die()
	else:
		sprite.modulate = Color.RED 
		await get_tree().create_timer(0.1).timeout 
		sprite.modulate = Color.WHITE

func die():
	print("PLAYER DIED")
	emit_signal("player_died")
	
	# 1. Red Flash
	sprite.modulate = Color.RED 
	await get_tree().create_timer(0.2).timeout 
	
	# 2. Fade Sprite to Transparent
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 1.5) # Fade out over 1.5 seconds
	await tween.finished
