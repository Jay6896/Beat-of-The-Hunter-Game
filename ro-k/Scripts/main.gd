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
	if area.name == "CombatTrigger": start_combat()

func start_combat():
	print("MAIN: Starting Combat")
	is_combat_active = true
	if player.has_method("enter_combat_state"): player.enter_combat_state()
	player.animation.play("Idle Animation")
	if camera: camera.lock_camera()
	if dog and is_instance_valid(dog): dog.enter_combat_mode()
	battle_hud.start_combat_mode()

# --- PLAYER ATTACK TURN ---
func _on_player_attack_hit(damage_amount):
	if dog and is_instance_valid(dog):
		battle_hud.hide_reticles()
		
		# 1. Player always zips in
		player.perform_zip_attack(dog.global_position)
		
		# 2. Sync wait (0.25s)
		await get_tree().create_timer(0.25).timeout 
		
		if damage_amount > 0:
			# HIT: Dog takes damage
			dog.take_damage(damage_amount)
		else:
			# MISS (0 Damage): Dog Dodges!
			print("MAIN: Player Missed! Dog Dodging.")
			dog.perform_dodge()
	else:
		player.animation.play("Attack Animation")

# --- ENEMY ATTACK TURN ---
func _on_player_hurt_by_enemy(damage_amount):
	battle_hud.hide_reticles()
	
	if dog and is_instance_valid(dog):
		
		# CASE A: PERFECT DODGE (0 Damage)
		if damage_amount == 0:
			print("MAIN: Perfect Dodge!")
			player.perform_dodge_zip(75.0)
			dog.perform_attack(player.original_combat_position)
			
		# CASE B: PARTIAL DODGE (Partial Damage)
		elif damage_amount < 34: 
			print("MAIN: Partial Dodge!")
			player.perform_dodge_zip(45.0)
			await get_tree().create_timer(0.05).timeout
			dog.perform_attack(player.global_position)
			
			await get_tree().create_timer(0.25).timeout
			if player.has_method("take_damage"):
				player.take_damage(damage_amount)
			
		# CASE C: FULL HIT / MISS DEFENSE (34 Damage)
		else:
			print("MAIN: Direct Hit!")
			# 1. Player stands still
			# 2. Enemy attacks Player directly
			dog.perform_attack(player.global_position)
			
			await get_tree().create_timer(0.25).timeout
			if player.has_method("take_damage"):
				player.take_damage(damage_amount)
	else:
		print("MAIN: Player Dodged! (No Dog found)")

func _on_enemy_defeated():
	print("MAIN: Enemy Defeated!")
	_end_combat()

# --- FADE TO BLACK AND RESPAWN ---
func _on_player_defeated():
	print("MAIN: Player Defeated! Fading out...")
	
	# 1. Stop combat logic
	_end_combat()
	
	# 2. Wait for Player Sprite to fade (Matches the 1.5s in Character_Controller.gd)
	await get_tree().create_timer(1.5).timeout
	
	# --- CRITICAL FIX ---
	# _end_combat() hides the HUD, so we must turn it back ON
	# otherwise the black screen we add below will be invisible.
	battle_hud.visible = true 
	# --------------------
	
	# 3. Create a black screen overlay
	var overlay = ColorRect.new()
	overlay.color = Color.BLACK
	overlay.color.a = 0.0 # Start transparent
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	
	# Add to HUD
	battle_hud.add_child(overlay) 
	
	# 4. Tween the screen to Black (0.5 seconds as requested)
	var tween = create_tween()
	tween.tween_property(overlay, "color:a", 1.0, 0.5)
	await tween.finished
	
	# 5. Hold the black screen for a moment (so it doesn't reload instantly)
	await get_tree().create_timer(0.5).timeout
	
	# 6. Reload Scene
	get_tree().reload_current_scene()

func _end_combat():
	is_combat_active = false
	battle_hud.stop_combat()
	if player.has_method("exit_combat_state"): player.exit_combat_state()
	if camera: camera.unlock_camera()
	player.animation.play("Idle Animation")
