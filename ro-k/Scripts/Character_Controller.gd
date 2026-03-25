extends CharacterBody2D

signal player_died 

const SPEED = 500.0
const JUMP_VELOCITY = -600.0
const FALL_GRAVITY_MULTIPLIER = 2.0
const ZIP_SPEED = 0.25 

@export var max_health: float = 100.0
@export var real_time_attack_damage: float = 25.0 
@export var attack_audio_delay: float = 0.15 
@export var jump_audio_delay: float = 0.05 

var current_health: float

@onready var animation = $AnimationPlayer
@onready var sprite = $Sprite2D
@onready var health_bar = $TextureProgressBar 
@onready var zip_sfx = $ZipImpactSFX 
@onready var zip_miss_sfx = $ZipMissSFX 
@onready var sword_box = $SwordBox

# --- NEW: Reference to the CombatDetector so we can flip it ---
@onready var combat_detector = $CombatDetector

@onready var jump_sfx = $JumpSFX
@onready var attack_sfx = $AttackSFX
@onready var hurt_sfx = $HurtSFX
@onready var walk_sfx = $WalkSFX

var is_combat_locked = false 
var original_combat_position = Vector2.ZERO 
var in_cutscene: bool = false 

func _ready():
	current_health = max_health
	if health_bar:
		health_bar.max_value = max_health
		health_bar.value = current_health
		health_bar.visible = true 

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		var current_gravity = get_gravity()
		if velocity.y > 0:
			velocity += current_gravity * FALL_GRAVITY_MULTIPLIER * delta
		else:
			velocity += current_gravity * delta

	if in_cutscene:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		_stop_walking_sound()
		move_and_slide()
		if is_on_floor() and animation.current_animation != "Idle Animation" and velocity.x == 0:
			animation.play("Idle Animation")
		return 

	if is_combat_locked:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		_stop_walking_sound()
		move_and_slide()
		if is_on_floor() and animation.current_animation != "Attack Animation" and velocity.x == 0:
			animation.play("Idle Animation")
		return 

	var is_busy = false
	if animation.current_animation == "Attack Animation" and animation.is_playing(): is_busy = true
	elif animation.current_animation == "Jump Animation" and is_on_floor(): is_busy = true
		
	if is_busy:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		_stop_walking_sound()
		move_and_slide()
		return 

	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		animation.play("Jump Animation", 0.1)
		if jump_sfx:
			get_tree().create_timer(jump_audio_delay).timeout.connect(func(): if jump_sfx: jump_sfx.play())
		
	if Input.is_action_just_pressed("Attack"):
		animation.play("Attack Animation", 0.1)
		velocity.x = 0 
		if attack_sfx:
			get_tree().create_timer(attack_audio_delay).timeout.connect(func(): if attack_sfx: attack_sfx.play())

	var direction := Input.get_axis("ui_left", "ui_right")
	if direction:
		velocity.x = direction * SPEED
		
		if direction < 0: 
			sprite.flip_h = true
			if sword_box: sword_box.scale.x = -1 
			# --- CHANGED: Flip CombatDetector Left ---
			if combat_detector: combat_detector.scale.x = -1 
		else: 
			sprite.flip_h = false
			if sword_box: sword_box.scale.x = 1 
			# --- CHANGED: Flip CombatDetector Right ---
			if combat_detector: combat_detector.scale.x = 1 
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
		if is_on_floor() and walk_sfx and not walk_sfx.playing:
			walk_sfx.play()
		elif not is_on_floor() and walk_sfx:
			walk_sfx.stop()
	else: 
		animation.play("Idle Animation", 0.1)
		_stop_walking_sound()

func _stop_walking_sound():
	if walk_sfx and walk_sfx.playing:
		walk_sfx.stop()

# --- RHYTHM COMBAT FUNCTIONS ---
func enter_combat_state():
	is_combat_locked = true
	velocity.x = 0 
	original_combat_position = global_position 

func exit_combat_state():
	is_combat_locked = false

func perform_zip_attack(target_position, land_hit: bool):
	animation.stop()
	animation.play("Attack Animation")
	
	var tween = create_tween()
	var attack_spot = Vector2(target_position.x - 180, global_position.y)
	
	tween.tween_property(self, "global_position", attack_spot, ZIP_SPEED).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	
	if land_hit and zip_sfx:
		tween.tween_interval(0.15) 
		tween.tween_callback(zip_sfx.play)
	elif not land_hit and zip_miss_sfx:
		tween.tween_callback(zip_miss_sfx.play)
	
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
	print("--- PLAYER TOOK DAMAGE! Amount: ", amount, " ---")
	current_health -= amount
	if health_bar: health_bar.value = current_health
	if hurt_sfx: hurt_sfx.play()
	
	if current_health <= 0: die()
	else:
		sprite.modulate = Color.RED 
		await get_tree().create_timer(0.1).timeout 
		sprite.modulate = Color.WHITE

func die():
	print("PLAYER DIED")
	emit_signal("player_died")
	sprite.modulate = Color.RED 
	await get_tree().create_timer(0.2).timeout 
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 1.5) 
	await tween.finished

# --- REAL-TIME COMBAT FUNCTIONS ---
func _on_sword_box_area_entered(area: Area2D) -> void:
	print("SWORD HIT AREA: ", area.name) 
	if area.name == "HurtBox":
		var enemy = area.get_parent() 
		if enemy.has_method("take_realtime_damage"):
			print("SUCCESS! Sword dealing ", real_time_attack_damage, " damage!") 
			enemy.take_realtime_damage(real_time_attack_damage)
			
