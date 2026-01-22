extends Node2D

@onready var player = $CharacterBody2D
@onready var dog = $DogEnemy 
@onready var battle_hud = $BattleHUD 
@onready var camera = $CharacterBody2D/Camera2D 

var is_combat_active = false

func _ready():
	if player.has_node("CombatDetector"):
		player.get_node("CombatDetector").area_entered.connect(_on_combat_triggered)
	
	if battle_hud:
		battle_hud.attack_hit.connect(_on_player_attack_hit)
		battle_hud.player_hurt.connect(_on_player_hurt_by_enemy)
		
	if dog and dog.has_signal("enemy_died"):
		dog.enemy_died.connect(_on_enemy_defeated)
		
	if player.has_signal("player_died"):
		player.player_died.connect(_on_player_defeated)

func _on_combat_triggered(area):
	if is_combat_active: return
	if area.name == "CombatTrigger":
		start_combat()

func start_combat():
	print("MAIN: Starting Combat")
	is_combat_active = true
	
	if player.has_method("enter_combat_state"):
		player.enter_combat_state()
	player.animation.play("Idle Animation")
	
	if camera: camera.lock_camera()
	
	if dog and is_instance_valid(dog):
		dog.enter_combat_mode()
	
	battle_hud.start_combat_mode()

func _on_player_attack_hit(damage_amount):
	# Player -> Enemy
	player.animation.stop() 
	player.animation.play("Attack Animation")
	if dog and is_instance_valid(dog):
		dog.take_damage(damage_amount)

func _on_player_hurt_by_enemy(damage_amount):
	# Enemy -> Player
	
	# 1. Play Dog Attack Animation (Visual)
	if dog and is_instance_valid(dog):
		dog.perform_attack()
	
	# 2. Deal Damage (If any)
	if damage_amount > 0:
		print("MAIN: Player took damage: ", damage_amount)
		if player.has_method("take_damage"):
			player.take_damage(damage_amount)
	else:
		print("MAIN: Player Dodged!")

func _on_enemy_defeated():
	print("MAIN: Enemy Defeated!")
	_end_combat()

func _on_player_defeated():
	print("MAIN: Player Defeated!")
	_end_combat()

func _end_combat():
	is_combat_active = false
	battle_hud.stop_combat()
	if player.has_method("exit_combat_state"):
		player.exit_combat_state()
	if camera: camera.unlock_camera()
	player.animation.play("Idle Animation")
