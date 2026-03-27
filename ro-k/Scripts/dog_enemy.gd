extends CharacterBody2D

signal enemy_died 
signal boss_defeated 

@export var patrol_distance: float = 200.0  
@export var patrol_speed: float = 60.0
@export var max_health: float = 100.0
@export var damage_amount: float = 20.0
@export var combat_facing_dir: float = -1.0 

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
@onready var sprite: Sprite2D = $Pivot/Sprite2D 
@onready var health_bar: TextureProgressBar = $TextureProgressBar
@onready var zip_sfx = $ZipImpactSFX 
@onready var zip_miss_sfx = $ZipMissSFX 

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
			var curr_anim = anim_player.current_animation.to_lower()
			if curr_anim != "hurt" and curr_anim != "death" and curr_anim != "attack":
				_play_anim("idle")
		State.HURT: velocity.x = 0
		State.ATTACK: velocity.x = 0
		State.DEAD: velocity.x = 0

	move_and_slide()

func _play_anim(anim_name: String) -> bool:
	var lower = anim_name.to_lower()
	var capitalized = anim_name.capitalize()
	
	if anim_player.has_animation(lower):
		anim_player.play(lower)
		return true
	elif anim_player.has_animation(capitalized):
		anim_player.play(capitalized)
		return true
	else:
		if anim_player.has_animation("idle"):
			anim_player.play("idle")
		elif anim_player.has_animation("Idle"):
			anim_player.play("Idle")
		return false

func _state_patrol(delta):
	_play_anim("walk")
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
	pivot.scale.x = combat_facing_dir 
	_play_anim("idle")
	original_combat_pos = global_position

# --- ATTACK & DODGE LOGIC ---

func perform_attack(target_position: Vector2, land_hit: bool):
	if current_state == State.DEAD: return
	current_state = State.ATTACK
	_play_anim("attack")
	
	var final_pos = Vector2(target_position.x + 80, global_position.y)
	
	if not land_hit and zip_miss_sfx:
		zip_miss_sfx.play()
	
	var tween = create_tween()
	tween.tween_property(self, "global_position", final_pos, ZIP_SPEED).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	
	if land_hit and zip_sfx:
		tween.tween_callback(zip_sfx.play)
		
	await anim_player.animation_finished
	
	tween = create_tween()
	tween.tween_property(self, "global_position", original_combat_pos, ZIP_SPEED).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	await tween.finished
	
	if current_state != State.DEAD:
		current_state = State.COMBAT_IDLE
		_play_anim("idle")

func perform_dodge():
	if current_state == State.DEAD: return
	
	var dodge_pos = Vector2(global_position.x + 200, global_position.y)
	
	var tween = create_tween()
	tween.tween_property(self, "global_position", dodge_pos, ZIP_SPEED).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	
	await get_tree().create_timer(1.0).timeout
	
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
		
		var has_anim = _play_anim("hurt")
		
		if has_anim:
			await anim_player.animation_finished
		else:
			# FIX 1: Stop the animation player so it doesn't fight the flash!
			anim_player.stop()
			
			if sprite:
				var flash_tween = create_tween()
				# FIX 2: Using HDR color multipliers to force dark pixels to glow bright cyan!
				flash_tween.tween_property(sprite, "self_modulate", Color(2.5, 4.0, 4.0), 0.1)
				flash_tween.tween_property(sprite, "self_modulate", Color.WHITE, 0.1)
				flash_tween.tween_property(sprite, "self_modulate", Color(2.5, 4.0, 4.0), 0.1)
				flash_tween.tween_property(sprite, "self_modulate", Color.WHITE, 0.1)
				await flash_tween.finished
			else:
				await get_tree().create_timer(0.4).timeout
				
		if current_state != State.DEAD:
			current_state = State.COMBAT_IDLE
			_play_anim("idle")

func die():
	current_state = State.DEAD
	emit_signal("enemy_died") 
	
	var has_anim = _play_anim("death")
	
	if has_anim:
		await anim_player.animation_finished
	else:
		# FIX 3: CRITICAL! Stops the idle animation so it doesn't fight our fade.
		anim_player.stop() 
	
	# FIX 4: Target "self" so BOTH the sprite and the health bar fade smoothly together in 0.5s!
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.5) 
	await tween.finished
	
	emit_signal("boss_defeated") 
	queue_free()

func _update_health_bar():
	await get_tree().create_timer(0.2).timeout
	health_bar.value = current_health

# --- ANIMATION PLAYER DUMMY FUNCTIONS ---
func enable_bite():
	pass 

func disable_bite():
	pass 

func finish_attack():
	pass

func finish_hurt():
	pass

func attack_hit(damage_amount: Variant) -> void:
	take_damage(damage_amount)
