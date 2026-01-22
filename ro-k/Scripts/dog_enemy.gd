extends CharacterBody2D

signal enemy_died 

@export var patrol_distance: float = 200.0  
@export var patrol_speed: float = 60.0
@export var max_health: float = 100.0
@export var damage_amount: float = 20.0

# MOVEMENT SETTINGS
const ZIP_SPEED = 0.25 

enum State { PATROL, COMBAT_IDLE, HURT, ATTACK, DEAD } 
var current_state: State = State.PATROL
var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
var current_health: float
var start_x: float
var heading_right: bool = true
var original_combat_pos = Vector2.ZERO 

@onready var pivot: Node2D = $Pivot 
@onready var anim_player: AnimationPlayer = $Pivot/AnimationPlayer
@onready var health_bar: TextureProgressBar = $TextureProgressBar

func _ready() -> void:
	current_health = max_health
	start_x = global_position.x 
	_update_health_bar()
	health_bar.max_value = max_health
	health_bar.value = current_health

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta
		
	match current_state:
		State.PATROL: _state_patrol(delta)
		State.COMBAT_IDLE:
			velocity.x = 0
			if anim_player.current_animation != "hurt" and anim_player.current_animation != "death" and anim_player.current_animation != "attack":
				anim_player.play("idle")
		State.HURT: velocity.x = 0
		State.ATTACK: velocity.x = 0
		State.DEAD: velocity.x = 0

	move_and_slide()

func _state_patrol(delta):
	anim_player.play("walk")
	if heading_right:
		velocity.x = patrol_speed
		if global_position.x >= start_x + patrol_distance: heading_right = false
	else:
		velocity.x = -patrol_speed
		if global_position.x <= start_x - patrol_distance: heading_right = true
	if velocity.x > 0: pivot.scale.x = 1
	elif velocity.x < 0: pivot.scale.x = -1

func enter_combat_mode():
	current_state = State.COMBAT_IDLE
	pivot.scale.x = -1 
	anim_player.play("idle")
	original_combat_pos = global_position

# --- ATTACK & DODGE LOGIC ---

func perform_attack(target_position: Vector2):
	if current_state == State.DEAD: return
	current_state = State.ATTACK
	anim_player.play("attack")
	
	# Zip to target (offset by 80px to stand in front of it)
	var final_pos = Vector2(target_position.x + 80, global_position.y)
	
	var tween = create_tween()
	tween.tween_property(self, "global_position", final_pos, ZIP_SPEED).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	await anim_player.animation_finished
	
	# Zip back
	tween = create_tween()
	tween.tween_property(self, "global_position", original_combat_pos, ZIP_SPEED).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	await tween.finished
	
	if current_state != State.DEAD:
		current_state = State.COMBAT_IDLE
		anim_player.play("idle")

func perform_dodge():
	if current_state == State.DEAD: return
	
	# 1. Zip Backward (Away from player)
	var dodge_pos = Vector2(global_position.x + 200, global_position.y)
	
	var tween = create_tween()
	tween.tween_property(self, "global_position", dodge_pos, ZIP_SPEED).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	
	# 2. Wait for player's attack to finish + player zip back
	# CHANGED: Increased to 1.0s to ensure Player is gone before we return
	await get_tree().create_timer(1.0).timeout
	
	# 3. Zip Return
	tween = create_tween()
	tween.tween_property(self, "global_position", original_combat_pos, ZIP_SPEED).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)

# --- DAMAGE LOGIC ---

func take_damage(amount: float):
	current_health -= amount
	_update_health_bar()
	
	if current_health <= 0:
		await get_tree().create_timer(1.0).timeout
		die()
	else:
		current_state = State.HURT
		await get_tree().create_timer(0.2).timeout 
		anim_player.play("hurt")
		await anim_player.animation_finished
		if current_state != State.DEAD:
			current_state = State.COMBAT_IDLE
			anim_player.play("idle")

func die():
	current_state = State.DEAD
	emit_signal("enemy_died") 
	anim_player.play("death")
	
	await anim_player.animation_finished
	
	# FADE OUT
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 1.0) # Fade alpha to 0 over 1 second
	await tween.finished
	
	queue_free()

func _update_health_bar():
	await get_tree().create_timer(0.2).timeout
	health_bar.value = current_health
