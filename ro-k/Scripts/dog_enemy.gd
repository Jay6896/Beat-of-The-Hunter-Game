extends CharacterBody2D

# --- SETTINGS ---
@export var patrol_speed: float = 60.0
@export var chase_speed: float = 140.0
@export var max_health: float = 100.0
@export var damage_amount: float = 20.0

# --- STATE MACHINE ---
enum State { PATROL, CHASE, ATTACK, HURT, DEAD }
var current_state: State = State.PATROL
var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
var current_health: float

# --- NODES ---
@onready var sprite: Sprite2D = $Sprite2D
@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var health_bar: TextureProgressBar = $TextureProgressBar

# Raycasts
@onready var wall_check: RayCast2D = $Raycasts/WallCheck
@onready var player_detect: RayCast2D = $Raycasts/PlayerDetect
@onready var attack_range: RayCast2D = $Raycasts/AttackRange

# Combat
@onready var hit_box: Area2D = $HitBox
@onready var hurt_box: CollisionShape2D = $HurtBox

func _ready() -> void:
	current_health = max_health
	_update_health_bar()
	
	# Initial Setup
	hit_box.monitoring = false  # Teeth off
	#hurt_box.monitoring = true  # Body on
	
	# Connect Signals via Code (Or do it in editor)
	hit_box.body_entered.connect(_on_hit_box_body_entered)
func _physics_process(delta: float) -> void:
	# 1. Apply Gravity
	if not is_on_floor():
		velocity.y += gravity * delta
		
	# 2. State Logic
	match current_state:
		State.PATROL:
			_state_patrol(delta)
		State.CHASE:
			_state_chase(delta)
		State.ATTACK:
			_state_attack(delta)
		State.HURT:
			_state_hurt(delta)
		State.DEAD:
			velocity.x = 0

	move_and_slide()

# --- STATE FUNCTIONS ---

func _state_patrol(delta):
	anim_player.play("walk")
	velocity.x = patrol_speed * scale.x
	
	# Turn around at walls
	if wall_check.is_colliding():
		scale.x = -scale.x
	
	# Spot Player -> Switch to Chase
	if player_detect.is_colliding():
		current_state = State.CHASE

func _state_chase(delta):
	anim_player.play("walk") # Or "run" if you have it
	velocity.x = chase_speed * scale.x
	
	# Player found -> Attack
	if attack_range.is_colliding():
		current_state = State.ATTACK
	
	# Player lost -> Return to Patrol
	if not player_detect.is_colliding():
		current_state = State.PATROL

func _state_attack(delta):
	velocity.x = 0 # Stop moving to bite
	anim_player.play("attack")
	# The logic to EXIT this state happens in the Animation Method Tracks (see Phase 4)

func _state_hurt(delta):
	velocity.x = 0
	anim_player.play("hurt")
	# Logic to exit happens in Animation Method Tracks

# --- PUBLIC FUNCTIONS (Called by Player) ---

func take_damage(amount: float):
	if current_state == State.DEAD: return
	
	current_health -= amount
	_update_health_bar()
	
	if current_health <= 0:
		current_state = State.DEAD
		anim_player.play("death")
		# Add a method track at end of death anim to call queue_free()
	else:
		current_state = State.HURT

# --- ANIMATION EVENTS (Called by AnimationPlayer) ---
# You MUST add Method Tracks in your animation player to call these!

func enable_bite():
	hit_box.monitoring = true

func disable_bite():
	hit_box.monitoring = false

func finish_attack():
	# Decide what to do after bite animation finishes
	if attack_range.is_colliding():
		current_state = State.ATTACK # Bite again!
	else:
		current_state = State.CHASE # Run after them!

func finish_hurt():
	current_state = State.CHASE # Angry dog chases after getting hit

# --- SIGNALS ---

func _on_hit_box_body_entered(body: Node2D) -> void:
	if body.has_method("take_damage"):
		body.take_damage(damage_amount)
	elif body.name == "Player": # Fallback if you haven't added take_damage to player yet
		get_tree().reload_current_scene()

func _update_health_bar():
	health_bar.value = (current_health / max_health) * 100
