extends CharacterBody2D

signal boss_defeated 

@export var patrol_speed: float = 60.0
@export var chase_speed: float = 120.0
@export var max_health: float = 50.0
@export var patrol_distance: float = 200.0
@export var attack_range: float = 400.0
@export var attack_damage: float = 15.0

@export var attack_lunge_offset: float = 80.0 
@export var attack_lunge_delay: float = 0.3 
@export var right_facing_offset: float = -50.0 
@export var hitbox_right_offset: float = -50.0 

@export_enum("Right:1", "Left:-1") var start_direction: int = 1

var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
var current_health: float
var start_x: float
var target_player = null
var direction: int

var default_sprite_x: float = 0.0 
var default_body_x: float = 0.0
var default_attack_x: float = 0.0
var default_detector_x: float = 0.0

var pre_lunge_offset: float = 0.0
var pre_lunge_attack_x: float = 0.0

enum State { PATROL, SPOT_PLAYER, CHASE, ATTACK, HURT, DEAD }
var current_state: State = State.PATROL

@onready var sprite = $Sprite2D
@onready var anim_player = $AnimationPlayer
@onready var health_bar = $HealthBar 

@onready var attack_box = $AttackBox 
@onready var player_detector = $PlayerDetector 
@onready var body_col = $Body 
@onready var hurt_box = $HurtBox

func _ready():
	current_health = max_health
	start_x = global_position.x
	default_sprite_x = sprite.position.x 
	
	if body_col: default_body_x = body_col.position.x
	if attack_box: default_attack_x = attack_box.position.x
	if player_detector: default_detector_x = player_detector.position.x
	
	if health_bar:
		health_bar.max_value = max_health
		health_bar.value = current_health

	direction = start_direction
	_flip_enemy(direction)

func _physics_process(delta):
	if not is_on_floor():
		velocity.y += gravity * delta
		
	match current_state:
		State.PATROL: _state_patrol()
		State.SPOT_PLAYER: velocity.x = 0
		State.CHASE: _state_chase()
		State.ATTACK: velocity.x = 0
		State.HURT: velocity.x = 0
		State.DEAD: velocity.x = 0
		
	move_and_slide()

func _state_patrol():
	if anim_player.current_animation != "Walk":
		anim_player.play("Walk")
		
	velocity.x = direction * patrol_speed
	
	if direction == 1 and global_position.x > start_x + patrol_distance:
		_flip_enemy(-1)
	elif direction == -1 and global_position.x < start_x - patrol_distance:
		_flip_enemy(1)

func _state_chase():
	if not target_player:
		current_state = State.PATROL
		start_x = global_position.x
		return
		
	if anim_player.current_animation != "Walk":
		anim_player.play("Walk")
		
	var dist = global_position.distance_to(target_player.global_position)
	var dir_to_player = sign(target_player.global_position.x - global_position.x)
	
	_flip_enemy(dir_to_player)
	
	if dist <= attack_range:
		_perform_attack()
	else:
		velocity.x = dir_to_player * chase_speed

func _flip_enemy(dir):
	if current_state == State.ATTACK: return 
	direction = dir
	
	if dir > 0: 
		sprite.flip_h = true
		sprite.offset.x = right_facing_offset 
		
		if body_col:
			body_col.scale.x = -1
			body_col.position.x = -default_body_x + hitbox_right_offset
			
		if attack_box:
			attack_box.scale.x = -1
			attack_box.position.x = -default_attack_x + hitbox_right_offset
		if player_detector:
			player_detector.scale.x = -1
			player_detector.position.x = -default_detector_x + hitbox_right_offset
			
	elif dir < 0: 
		sprite.flip_h = false
		sprite.offset.x = 0.0 
		
		if body_col:
			body_col.scale.x = 1
			body_col.position.x = default_body_x
		if attack_box:
			attack_box.scale.x = 1
			attack_box.position.x = default_attack_x
		if player_detector:
			player_detector.scale.x = 1
			player_detector.position.x = default_detector_x

func _on_player_detector_body_entered(body):
	if body.has_method("take_damage") and current_state == State.PATROL:
		# Removed cutscene lock
		target_player = body
		current_state = State.SPOT_PLAYER
		velocity.x = 0
		
		anim_player.play("Idle")
		await get_tree().create_timer(0.6).timeout 
		
		if current_state != State.DEAD and current_state != State.HURT:
			current_state = State.CHASE

func _on_player_detector_body_exited(body):
	if body == target_player:
		target_player = null
		if current_state != State.DEAD and current_state != State.HURT:
			current_state = State.PATROL
			start_x = global_position.x 

func _perform_attack():
	if current_state == State.ATTACK or current_state == State.DEAD: return
	current_state = State.ATTACK
	
	anim_player.play("Attack")
	
	pre_lunge_offset = sprite.offset.x
	if attack_box: pre_lunge_attack_x = attack_box.position.x
	
	var anim_length = anim_player.current_animation_length
	await get_tree().create_timer(attack_lunge_delay).timeout
	
	if current_state == State.ATTACK:
		if direction > 0:
			sprite.offset.x = pre_lunge_offset + attack_lunge_offset
			if attack_box: attack_box.position.x = pre_lunge_attack_x + attack_lunge_offset
		else:
			sprite.offset.x = pre_lunge_offset - attack_lunge_offset
			if attack_box: attack_box.position.x = pre_lunge_attack_x - attack_lunge_offset
			
		var time_left = anim_length - attack_lunge_delay
		if time_left > 0:
			await get_tree().create_timer(time_left).timeout
		else:
			await get_tree().create_timer(0.1).timeout
			
	if current_state != State.DEAD:
		sprite.offset.x = pre_lunge_offset
		if attack_box: attack_box.position.x = pre_lunge_attack_x
		
		if current_state == State.ATTACK:
			current_state = State.CHASE

func _on_attack_box_body_entered(body: Node2D) -> void:
	if body.has_method("take_damage"):
		body.take_damage(attack_damage)

func take_realtime_damage(amount: float):
	if current_state == State.DEAD: return
	
	current_health -= amount
	if health_bar: health_bar.value = current_health
	
	if current_health <= 0:
		current_state = State.DEAD
		anim_player.play("Death")
		await anim_player.animation_finished
		
		var tween = create_tween()
		tween.tween_property(self, "modulate:a", 0.0, 1.0)
		await tween.finished
		
		boss_defeated.emit() 
		
		queue_free()
	else:
		current_state = State.HURT
		anim_player.play("Hurt")
		
		_flip_enemy(direction)
		
		await anim_player.animation_finished
		
		if current_state != State.DEAD:
			current_state = State.CHASE if target_player else State.PATROL

func _on_boss_defeated() -> void:
	pass
