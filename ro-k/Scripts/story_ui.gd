extends CanvasLayer

signal mid_level_dialogue_finished 

@onready var fade_rect = $FadeRect
@onready var textbox = $Textbox
@onready var label = $Textbox/RichTextLabel

var state = "INTRO" 
@export var next_scene_path: String = "res://Scenes/placeholder_level.tscn"

@export_multiline var intro_text: String = "Find and defeat the spiritual Dog! \n[font_size=56]Press [color=black]W[/color] and [color=black]D[/color] to move,\n[color=black]Space[/color] to jump and \n[color=black]K[/color] to attack[/font_size]"
@export_multiline var boss_defeated_text: String = "The spiritual Dog has been defeated... \nThe path forward is finally clear!"

var text_tween: Tween 

@onready var player = get_parent().get_node_or_null("CharacterBody2D")

func _ready():
	fade_rect.visible = true
	fade_rect.modulate.a = 1.0 
	
	var fade_in_tween = create_tween()
	fade_in_tween.tween_property(fade_rect, "modulate:a", 0.0, 1.5)
	
	textbox.visible = true
	label.visible_ratio = 1.0 
	label.text = intro_text
	
	await fade_in_tween.finished
	fade_rect.visible = false
	
func _input(event):
	# --- FIX: Now advances dialogue on ANY keyboard key, mouse click, or controller button! ---
	var any_key_pressed = event.is_pressed() and not event.is_echo() and (event is InputEventKey or event is InputEventMouseButton or event is InputEventJoypadButton)
	
	if any_key_pressed:
		if state == "INTRO":
			_dismiss_intro()
		elif state == "TYPING":
			if text_tween: text_tween.kill() 
			label.visible_ratio = 1.0
			state = "WAITING"
		elif state == "WAITING":
			_transition_to_next_level()
		elif state == "MID_TYPING":
			if text_tween: text_tween.kill()
			label.visible_ratio = 1.0
			state = "MID_WAITING"
		elif state == "MID_WAITING":
			_dismiss_mid_level_dialogue()

func _dismiss_intro():
	state = "HIDDEN"
	var tween = create_tween()
	tween.tween_property(textbox, "modulate:a", 0.0, 0.2)
	await tween.finished
	textbox.visible = false
	textbox.modulate.a = 1.0 

func trigger_mid_level_text(story_text: String):
	state = "MID_TYPING"
	
	if player:
		player.in_cutscene = true 
	
	textbox.modulate.a = 1.0
	textbox.visible = true
	label.text = story_text
	label.visible_ratio = 0.0 
	
	if text_tween: text_tween.kill()
		
	text_tween = create_tween()
	var duration = story_text.length() * 0.05 
	
	text_tween.tween_property(label, "visible_ratio", 1.0, duration)
	await text_tween.finished
	
	if state == "MID_TYPING":
		state = "MID_WAITING"

func _dismiss_mid_level_dialogue():
	state = "HIDDEN"
	
	var tween = create_tween()
	tween.tween_property(textbox, "modulate:a", 0.0, 0.2)
	await tween.finished
	textbox.visible = false
	textbox.modulate.a = 1.0 
	
	if player:
		player.in_cutscene = false
		
	emit_signal("mid_level_dialogue_finished")

func trigger_boss_text(story_text: String):
	state = "TYPING"
	if player: player.in_cutscene = true 
	textbox.visible = true
	label.text = story_text
	label.visible_ratio = 0.0 
	if text_tween: text_tween.kill()
	text_tween = create_tween()
	var duration = story_text.length() * 0.05 
	text_tween.tween_property(label, "visible_ratio", 1.0, duration)
	await text_tween.finished
	if state == "TYPING": state = "WAITING"

func _transition_to_next_level():
	state = "HIDDEN"
	textbox.visible = false
	fade_rect.visible = true
	var tween = create_tween()
	tween.tween_property(fade_rect, "modulate:a", 1.0, 1.5) 
	await tween.finished
	get_tree().change_scene_to_file(next_scene_path)

func _on_boss_defeated() -> void:
	trigger_boss_text(boss_defeated_text)

func _on_dog_enemy_boss_defeated() -> void:
	_on_boss_defeated()

func _on_rhythm_snake_boss_boss_defeated() -> void:
	_on_boss_defeated()

func _on_hunter_boss_boss_defeated() -> void:
	_on_boss_defeated()
