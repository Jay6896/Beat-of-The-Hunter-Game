extends CanvasLayer

signal attack_hit(damage_amount) 
signal player_hurt(damage_amount) 
signal turn_ended

@onready var container = $Control/ReticleContainer
@onready var green_reticle = $Control/ReticleContainer/GreenReticle
@onready var feedback_label = $Control/TurnBar/RichTextLabel 
@onready var turn_bar = $Control/TurnBar

var tween: Tween
var is_player_turn = true 
var can_input = false
var combat_ended = false 
var turn_action_count = 0 

const PLAYER_COLOR = Color("#569e16") 
const ENEMY_COLOR = Color("#C72F2A") 

func _ready():
	_hide_all_ui()
	if container: container.set_anchors_preset(Control.PRESET_CENTER)
	reset_reticle_positions()

func reset_reticle_positions():
	if not container: return
	var center_offset = container.size / 2 
	for child in container.get_children():
		if child is Control:
			child.position = center_offset - (child.size / 2)
	if green_reticle: green_reticle.pivot_offset = green_reticle.size / 2 

func _hide_all_ui():
	self.visible = false
	if container: container.visible = false
	if turn_bar: turn_bar.visible = false
	if green_reticle: green_reticle.visible = false
	if feedback_label: feedback_label.text = ""

func stop_combat():
	combat_ended = true
	is_player_turn = false
	can_input = false
	if tween: tween.kill()
	_hide_all_ui()

func start_combat_mode():
	combat_ended = false
	print("HUD: Combat Mode Activated")
	self.visible = true
	turn_bar.visible = true 
	start_player_turn_phase()

func start_player_turn_phase():
	if combat_ended: return
	is_player_turn = true
	turn_action_count = 0
	
	turn_bar.color = PLAYER_COLOR
	feedback_label.text = "[center][b]PLAYERS TURN[/b][/center]"
	
	var screen_size = get_viewport().get_visible_rect().size
	container.global_position = Vector2(screen_size.x * 0.75, screen_size.y * 0.5) - (container.size / 2)
	container.visible = false
	
	await get_tree().create_timer(1.5).timeout
	if not combat_ended: next_reticle_cycle()

func start_enemy_turn_phase():
	if combat_ended: return
	is_player_turn = false
	turn_action_count = 0
	
	turn_bar.color = ENEMY_COLOR
	feedback_label.text = "[center][b]ENEMIES TURN[/b][/center]"
	
	var screen_size = get_viewport().get_visible_rect().size
	container.global_position = Vector2(screen_size.x * 0.40, screen_size.y * 0.5) - (container.size / 2)
	container.visible = false
	
	await get_tree().create_timer(1.5).timeout
	if not combat_ended: next_reticle_cycle()

func next_reticle_cycle():
	if combat_ended: return
	if turn_action_count >= 3:
		if is_player_turn: start_enemy_turn_phase()
		else: start_player_turn_phase()
		return

	container.visible = true
	green_reticle.visible = false
	feedback_label.text = "[center][b]GET READY...[/b][/center]"
	
	await get_tree().create_timer(1.0).timeout
	if not combat_ended: spawn_reticle()

func spawn_reticle():
	if combat_ended: return
	turn_action_count += 1
	
	if is_player_turn: feedback_label.text = "[center][b]HIT![/b][/center]"
	else: feedback_label.text = "[center][b]DODGE![/b][/center]"
	
	green_reticle.visible = true
	green_reticle.scale = Vector2(3.5, 3.5)
	can_input = true
	
	if tween: tween.kill()
	tween = create_tween()
	tween.tween_property(green_reticle, "scale", Vector2(0, 0), 1.2)
	tween.finished.connect(_on_miss)

func _input(event):
	if not can_input: return
	if event.is_action_pressed("Attack"):
		check_timing()

func check_timing():
	if tween and tween.is_running():
		tween.stop()
		can_input = false 
		
		var current_scale = green_reticle.scale.x
		
		if is_player_turn:
			# --- PLAYER ATTACK ---
			if current_scale <= 1.1 and current_scale >= 0.8:
				_resolve_result("[center][b]GREAT![/b][/center]", 35, true)
			elif current_scale <= 1.6 and current_scale > 1.1:
				_resolve_result("[center][b]GOOD![/b][/center]", 15, true)
			else:
				_resolve_result("[center][b]MISS[/b][/center]", 0, true)
		else:
			# --- PLAYER DODGE (Enemy Turn) ---
			
			# Perfect Dodge (Green/Red) -> 0 Damage
			if current_scale <= 1.1 and current_scale >= 0.8:
				_resolve_result("[center][b]PERFECT DODGE![/b][/center]", 0, false)
			
			# Partial Dodge (Orange) -> 10 Damage
			elif current_scale <= 1.6 and current_scale > 1.1:
				_resolve_result("[center][b]PARTIAL DODGE[/b][/center]", 10, false) 
			
			# Miss (Too early) -> 34 Damage (Kill in 3)
			else:
				_resolve_result("[center][b]HIT![/b][/center]", 34, false) 

func _on_miss():
	if can_input:
		can_input = false
		if is_player_turn:
			_resolve_result("[center][b]MISS[/b][/center]", 0, true)
		else:
			# Miss (Too late) -> 34 Damage
			_resolve_result("[center][b]HIT![/b][/center]", 34, false)

func _resolve_result(text, value, is_attack):
	feedback_label.text = text
	
	if is_attack:
		if value > 0: emit_signal("attack_hit", value)
	else:
		# Always emit signal so Dog animation plays, even if 0 damage
		emit_signal("player_hurt", value) 
	
	green_reticle.visible = false
	
	await get_tree().create_timer(1.5).timeout
	if not combat_ended: next_reticle_cycle()
