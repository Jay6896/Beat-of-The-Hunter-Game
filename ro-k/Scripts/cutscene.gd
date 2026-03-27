extends Control

@export var next_scene_path: String = "res://Scenes/main.tscn"

@export_multiline var slide_texts: Array[String] = []

@onready var image_container = $ImageContainer 
@onready var text_label = $TextBox/TextLabel

var current_slide_index: int = 0
var is_typing: bool = false
var text_tween: Tween
var image_tween: Tween
var image_nodes: Array = []

func _ready():
	image_nodes = image_container.get_children()
	
	for img in image_nodes:
		img.modulate.a = 0.0
		
	if image_nodes.size() == 0 or slide_texts.size() == 0:
		print("WARNING: You need to add image nodes to the ImageContainer and text to the Inspector!")
		return
		
	show_slide(current_slide_index)

func show_slide(index: int):
	if index >= image_nodes.size() or index >= slide_texts.size():
		finish_cutscene()
		return

	text_label.text = slide_texts[index]
	text_label.visible_ratio = 0.0
	is_typing = true

	for i in range(image_nodes.size()):
		if i != index:
			image_nodes[i].modulate.a = 0.0

	if text_tween: text_tween.kill()
	text_tween = create_tween()
	var text_duration = slide_texts[index].length() * 0.05 
	text_tween.tween_property(text_label, "visible_ratio", 1.0, text_duration)
	text_tween.finished.connect(_on_typing_finished)

	var current_image = image_nodes[index]
	if image_tween: image_tween.kill()
	image_tween = create_tween()
	image_tween.tween_property(current_image, "modulate:a", 1.0, 1.5)

func _on_typing_finished():
	is_typing = false

func _input(event):
	var any_key_pressed = event.is_pressed() and not event.is_echo() and (event is InputEventKey or event is InputEventMouseButton or event is InputEventJoypadButton)
	
	if any_key_pressed:
		if is_typing:
			if text_tween: text_tween.kill()
			if image_tween: image_tween.kill()
			text_label.visible_ratio = 1.0
			image_nodes[current_slide_index].modulate.a = 1.0
			is_typing = false
		else:
			current_slide_index += 1
			show_slide(current_slide_index)

func finish_cutscene():
	var transition_layer = CanvasLayer.new()
	transition_layer.layer = 100 
	add_child(transition_layer)
	
	var black_rect = ColorRect.new()
	black_rect.color = Color(0, 0, 0, 0) 
	black_rect.set_anchors_preset(Control.PRESET_FULL_RECT) 
	transition_layer.add_child(black_rect)
	
	var fade_tween = create_tween()
	fade_tween.tween_property(black_rect, "color:a", 1.0, 1.5) 
	
	await fade_tween.finished
	get_tree().change_scene_to_file(next_scene_path)
