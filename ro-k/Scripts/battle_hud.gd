extends CanvasLayer

signal attack_hit(damage_amount) 
signal player_hurt(damage_amount) 
signal turn_ended

@onready var container = $Control/ReticleContainer
@onready var green_reticle = $Control/ReticleContainer/GreenReticle
@onready var feedback_label = $Control/TurnBar/RichTextLabel 
@onready var turn_bar = $Control/TurnBar
@onready var music_player = $MusicPlayer 

var tween: Tween
var is_player_turn = true 
var can_input = false
var combat_ended = false 
var turn_action_count = 0 
const PLAYER_COLOR = Color("#569e16") 
const ENEMY_COLOR = Color("#C72F2A") 

# ==========================================
# 🎵 EXPORTED RHYTHM SETTINGS 🎵
# ==========================================
@export var track_audio: AudioStream 
@export var track_bpm: float = 120.0
@export var track_start_time: float = 0.0 
# --- NEW: Controls the volume of the track in decibels ---
@export var track_volume_db: float = 0.0 

@export var player_reticle_delays: Array[float] = [2.7, 3.6, 3.5]
@export var enemy_reticle_delays: Array[float] = [2.5, 3.5, 3.2]

@export var turn_start_delay: float = 3.0 
@export var post_hit_delay: float = 2.8 

var sec_per_beat: float
var reticle_duration: float
var actual_turn_start: float
var actual_post_hit: float
var actual_player_delays: Array[float] = []
var actual_enemy_delays: Array[float] = []
# ==========================================

func _ready():
	if track_audio and music_player:
		music_player.stream = track_audio
		# --- NEW: Applies your custom volume right when the level loads ---
		music_player.volume_db = track_volume_db

	sec_per_beat = 60.0 / track_bpm
	reticle_duration = sec_per_beat * 2.0
	actual_turn_start = turn_start_delay * sec_per_beat
	actual_post_hit = post_hit_delay * sec_per_beat
	
	for beats in player_reticle_delays:
		actual_player_delays.append(beats * sec_per_beat)
		
	for beats in enemy_reticle_delays:
		actual_enemy_delays.append(beats * sec_per_beat)

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

func hide_reticles():
	container.visible = false
	green_reticle.visible = false

func fade_in_reticles():
	if combat_ended: return
	container.modulate.a = 0.0 
	container.visible = true
	var fade_tween = create_tween()
	fade_tween.tween_property(container, "modulate:a", 1.0, sec_per_beat) 

func stop_combat():
	combat_ended = true
	is_player_turn = false
	can_input = false
	if tween: tween.kill()
	
	if music_player and music_player.playing:
		var music_tween = create_tween()
		music_tween.tween_property(music_player, "volume_db", -80.0, 1.5)
		music_tween.tween_callback(music_player.stop)
		# --- CHANGED: Resets to your custom volume instead of a hardcoded 0.0 ---
		music_tween.tween_callback(func(): music_player.volume_db = track_volume_db)
	
	_hide_all_ui()

func start_combat_mode():
	combat_ended = false
	self.visible = true
	turn_bar.visible = true 
	
	if music_player and not music_player.playing:
		music_player.play(track_start_time)
	
	start_player_turn_phase()

func start_player_turn_phase():
	if combat_ended: return
	is_player_turn = true
	turn_action_count = 0
	turn_bar.color = PLAYER_COLOR
	feedback_label.text = "[center][b]PLAYERS TURN[/b][/center]"
	var screen_size = get_viewport().get_visible_rect().size
	container.global_position = Vector2(screen_size.x * 0.75, screen_size.y * 0.5) - (container.size / 2)
	
	fade_in_reticles()
	
	await get_tree().create_timer(actual_turn_start).timeout
	if not combat_ended: next_reticle_cycle()

func start_enemy_turn_phase():
	if combat_ended: return
	is_player_turn = false
	turn_action_count = 0
	turn_bar.color = ENEMY_COLOR
	feedback_label.text = "[center][b]ENEMIES TURN[/b][/center]"
	var screen_size = get_viewport().get_visible_rect().size
	container.global_position = Vector2(screen_size.x * 0.25, screen_size.y * 0.5) - (container.size / 2)
	
	fade_in_reticles()
	
	await get_tree().create_timer(actual_turn_start).timeout
	if not combat_ended: next_reticle_cycle()

func next_reticle_cycle():
	if combat_ended: return
	if turn_action_count >= 3:
		if is_player_turn: start_enemy_turn_phase()
		else: start_player_turn_phase()
		return

	if not container.visible:
		fade_in_reticles()

	green_reticle.visible = false
	feedback_label.text = "[center][b]GET READY...[/b][/center]"
	feedback_label.visible = true 
	
	var calculated_delay = 0.0
	if is_player_turn:
		calculated_delay = actual_player_delays[turn_action_count]
	else:
		calculated_delay = actual_enemy_delays[turn_action_count]
	
	await get_tree().create_timer(calculated_delay).timeout
	if not combat_ended: spawn_reticle()

func spawn_reticle():
	if combat_ended: return
	
	if is_player_turn: feedback_label.text = "[center][b]HIT![/b][/center]"
	else: feedback_label.text = "[center][b]DODGE![/b][/center]"
	green_reticle.visible = true
	green_reticle.scale = Vector2(3.5, 3.5)
	can_input = true
	
	if tween: tween.kill()
	tween = create_tween()
	tween.tween_property(green_reticle, "scale", Vector2(0, 0), reticle_duration)
	tween.finished.connect(_on_miss)

func _input(event):
	if not can_input: return
	if event.is_action_pressed("Attack"): check_timing()

func check_timing():
	if tween and tween.is_running():
		tween.stop()
		can_input = false 
		var current_scale = green_reticle.scale.x
		
		if is_player_turn:
			if current_scale <= 1.1 and current_scale >= 0.8: _resolve_result("[center][b]GREAT![/b][/center]", 35, true)
			elif current_scale <= 1.6 and current_scale > 1.1: _resolve_result("[center][b]GOOD![/b][/center]", 15, true)
			else: _resolve_result("[center][b]MISS[/b][/center]", 0, true)
		else:
			if current_scale <= 1.1 and current_scale >= 0.8: _resolve_result("[center][b]PERFECT DODGE![/b][/center]", 0, false)
			elif current_scale <= 1.6 and current_scale > 1.1: _resolve_result("[center][b]PARTIAL DODGE[/b][/center]", 25, false) 
			else: _resolve_result("[center][b]HIT![/b][/center]", 34, false) 

func _on_miss():
	if can_input:
		can_input = false
		if is_player_turn: _resolve_result("[center][b]MISS[/b][/center]", 0, true)
		else: _resolve_result("[center][b]HIT![/b][/center]", 34, false)

func _resolve_result(text, value, is_attack):
	feedback_label.text = text
	feedback_label.visible = true
	
	if is_attack:
		emit_signal("attack_hit", value) 
	else:
		emit_signal("player_hurt", value) 
	
	green_reticle.visible = false
	
	if value > 0 or (not is_attack and value == 0): 
		container.visible = false 
	
	turn_action_count += 1
	
	await get_tree().create_timer(actual_post_hit).timeout
	if not combat_ended: next_reticle_cycle()


func _on_story_ui_mid_level_dialogue_finished() -> void:
	pass # Replace with function body.
