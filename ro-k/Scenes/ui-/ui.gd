extends Control

@onready var option_pane: ColorRect = $ColorRect
@onready var volume_bar: HSlider = %Volume_bar
@onready var fullscreen: CheckButton = $ColorRect/VBoxContainer/Fullscreen_container/Fullscreen
@onready var volume_line: HSlider = %Volume_bar
@onready var input_ui: Control = $InputUI

@onready var start: Button = $VBoxContainer2/Start
@onready var options: Button = $VBoxContainer2/Options
@onready var quit: Button = $VBoxContainer2/Quit
@onready var back: Button = $ColorRect/Back
@onready var back_2: Button = $InputUI/Back2
@onready var input_config: Button = $ColorRect/inputConfig

@onready var bg_sprite: Sprite2D = $Background
@export var bg_scroll_speed: float = 50.0
@export var bg_reset_width: float = 2304.0 

@export var scale_intensity: float = 1.1
@export var duration: float = 0.2

var fullscreen_check:bool
var volume_check:float
var Background_music = 0
var config = ConfigFile.new()
const SETTINGS_FILE = "user://settings.ini"

func _ready() -> void:
	option_pane.visible = false
	if input_ui: input_ui.visible = false 
	
	if !FileAccess.file_exists(SETTINGS_FILE):
		config.set_value("Display","Fullscreen", true)
		config.set_value("Audio", "Volume", 1)
		config.save(SETTINGS_FILE)
		fullscreen_check = true
		volume_check = 1.0
	else:
		config.load(SETTINGS_FILE)
		for item in config.get_sections():
			if item == "Display":
				fullscreen_check = config.get_value(item, "Fullscreen")
			elif item == "Audio":
				volume_check = config.get_value(item, "Volume")
			
	Display_settings(fullscreen_check)
	Audio_settings(volume_check)	
	
	_setup_hover_signals(start)
	_setup_hover_signals(options)
	_setup_hover_signals(quit)
	_setup_hover_signals(back)
	_setup_hover_signals(back_2)
	_setup_hover_signals(input_config)
	
	if not back.pressed.is_connected(_on_back_pressed):
		back.pressed.connect(_on_back_pressed)
	if not start.pressed.is_connected(_on_start_pressed):
		start.pressed.connect(_on_start_pressed)
	if not options.pressed.is_connected(_on_options_pressed):
		options.pressed.connect(_on_options_pressed)
	if not quit.pressed.is_connected(_on_quit_pressed):
		quit.pressed.connect(_on_quit_pressed)

func _process(delta: float) -> void:
	if bg_sprite:
		bg_sprite.position.x -= bg_scroll_speed * delta
		if bg_sprite.position.x <= -bg_reset_width:
			bg_sprite.position.x += bg_reset_width

func _setup_hover_signals(btn: Button):
	if not btn: return
	btn.mouse_entered.connect(func(): _animate_hover(btn, scale_intensity))
	btn.mouse_exited.connect(func(): _animate_hover(btn, 1.0))

func _animate_hover(btn: Button, target_scale: float):
	var tween = create_tween()
	tween.tween_property(btn, "scale", Vector2.ONE * target_scale, duration)

func save_display_settings(key:String, value:bool):
	config.set_value("Display", key, value)
	config.save(SETTINGS_FILE)

func save_audio_settings(key:String, value:float):
	config.set_value("Audio", key, value)
	config.save(SETTINGS_FILE)
	
func Display_settings(check: bool):
	if check:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		fullscreen.button_pressed = true
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		fullscreen.button_pressed = false
	
func Audio_settings(check: float):
	var value = linear_to_db(check)
	AudioServer.set_bus_volume_db(Background_music, value)
	volume_line.value = float(check)
			
func _on_start_pressed() -> void:
	start.disabled = true
	options.disabled = true
	quit.disabled = true
	
	var transition_layer = CanvasLayer.new()
	transition_layer.layer = 100 
	add_child(transition_layer)
	
	var black_rect = ColorRect.new()
	black_rect.color = Color(0, 0, 0, 0) 
	black_rect.set_anchors_preset(Control.PRESET_FULL_RECT) 
	transition_layer.add_child(black_rect)
	
	var fade_tween = create_tween()
	fade_tween.tween_property(black_rect, "color:a", 1.0, 1.0) 
	
	await fade_tween.finished
	get_tree().change_scene_to_file("res://Scenes/cutscene.tscn")

func _on_options_pressed() -> void:
	option_pane.visible = true

func _on_quit_pressed() -> void:
	get_tree().quit()

func _on_fullscreen_toggled(toggled_on: bool) -> void:
	Display_settings(toggled_on)
	save_display_settings("Fullscreen", toggled_on)

func _on_back_pressed() -> void:
	option_pane.visible = false

func _on_h_slider_value_changed(value: float) -> void:
	var db_value = linear_to_db(value)
	AudioServer.set_bus_volume_db(Background_music, db_value)
	save_audio_settings("Volume", value)

func _on_input_config_pressed() -> void:
	input_ui.visible = true
	
func _on_back_2_pressed() -> void:
	input_ui.visible = false
