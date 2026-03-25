extends Node2D

@onready var player = $CharacterBody2D
@onready var battle_hud = $BattleHUD 
@onready var camera = $CharacterBody2D/Camera2D 

var is_combat_active = false
var current_enemy = null 

func _ready():
	if player.has_node("CombatDetector"):
		player.get_node("CombatDetector").area_entered.connect(_on_combat_triggered)
	if battle_hud:
		battle_hud.attack_hit.connect(_on_player_attack_hit)
		battle_hud.player_hurt.connect(_on_player_hurt_by_enemy)
	if player.has_signal("player_died"):
		player.player_died.connect(_on_player_defeated)

func _on_combat_triggered(area):
	if is_combat_active: return
	if area.name == "CombatTrigger":
		var enemy_node = area.get_parent()
		if not enemy_node.has_signal("enemy_died"):
			enemy_node = area.owner 
			
		if enemy_node and enemy_node.has_signal("enemy_died"):
			current_enemy = enemy_node
			
			if not current_enemy.enemy_died.is_connected(_on_enemy_defeated):
				current_enemy.enemy_died.connect(_on_enemy_defeated)
				
			start_combat()

func start_combat():
	print("MAIN: Starting Combat")
	is_combat_active = true
	if player.has_method("enter_combat_state"): player.enter_combat_state()
	player.animation.play("Idle Animation")
	if camera: camera.lock_camera()
	if current_enemy and is_instance_valid(current_enemy): current_enemy.enter_combat_mode()
	battle_hud.start_combat_mode()

# --- PLAYER ATTACK TURN ---
func _on_player_attack_hit(damage_amount):
	if current_enemy and is_instance_valid(current_enemy):
		battle_hud.hide_reticles()
		var is_hit = (damage_amount > 0)
		player.perform_zip_attack(current_enemy.global_position, is_hit)
		
		await get_tree().create_timer(0.25).timeout 
		
		if is_hit:
			current_enemy.take_damage(damage_amount)
			# --- FIX: INSTANTLY STOP UI IF ENEMY IS DEAD ---
			if current_enemy.current_health <= 0:
				battle_hud.stop_combat()
		else:
			current_enemy.perform_dodge()
	else:
		player.animation.play("Attack Animation")

# --- ENEMY ATTACK TURN ---
func _on_player_hurt_by_enemy(damage_amount):
	battle_hud.hide_reticles()
	
	if current_enemy and is_instance_valid(current_enemy):
		if damage_amount == 0:
			player.perform_dodge_zip(200.0)
			current_enemy.perform_attack(player.original_combat_position, false)
			
		elif damage_amount < 34: 
			player.perform_dodge_zip(100.0)
			await get_tree().create_timer(0.05).timeout
			current_enemy.perform_attack(player.global_position, true)
			
			await get_tree().create_timer(0.25).timeout
			if player.has_method("take_damage"):
				player.take_damage(damage_amount)
				# --- FIX: INSTANTLY STOP UI IF PLAYER IS DEAD ---
				if player.current_health <= 0:
					battle_hud.stop_combat()
		else:
			current_enemy.perform_attack(player.global_position, true)
			
			await get_tree().create_timer(0.25).timeout
			if player.has_method("take_damage"):
				player.take_damage(damage_amount)
				# --- FIX: INSTANTLY STOP UI IF PLAYER IS DEAD ---
				if player.current_health <= 0:
					battle_hud.stop_combat()

func _on_enemy_defeated():
	print("MAIN: Enemy Defeated!")
	await get_tree().create_timer(1.0).timeout 
	_end_combat()

func _on_player_defeated():
	print("MAIN: Player Defeated! Fading out...")
	_end_combat()
	
	await get_tree().create_timer(1.5).timeout
	battle_hud.visible = true
	
	var overlay = ColorRect.new()
	overlay.color = Color.BLACK
	overlay.color.a = 0.0 
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	
	battle_hud.add_child(overlay) 
	
	var tween = create_tween()
	tween.tween_property(overlay, "color:a", 1.0, 0.5)
	await tween.finished
	await get_tree().create_timer(0.5).timeout
	get_tree().reload_current_scene()

func _end_combat():
	is_combat_active = false
	current_enemy = null 
	battle_hud.stop_combat()
	if player.has_method("exit_combat_state"): player.exit_combat_state()
	if camera: camera.unlock_camera()
	player.animation.play("Idle Animation")
