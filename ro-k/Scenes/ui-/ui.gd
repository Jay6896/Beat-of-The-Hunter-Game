extends Control

@onready var option_pane: ColorRect = $ColorRect
@onready var volume_bar: HSlider = %Volume_bar
@onready var fullscreen: CheckButton = $ColorRect/VBoxContainer/Fullscreen_container/Fullscreen
@onready var volume_line: HSlider = %Volume_bar
@onready var input_ui: Control = $InputUI
@onready var start: Button = $VBoxContainer2/Start
@onready var options: Button = $VBoxContainer2/Options
@onready var quit: Button = $VBoxContainer2/Quit
@export var scale_intensity: float
@export var duration: float
@onready var back: Button = $ColorRect/Back
@onready var back_2: Button = $InputUI/Back2
@onready var input_config: Button = $ColorRect/inputConfig


var fullscreen_check:bool
var volume_check:float
var Background_music = 0
var config = ConfigFile.new()
const SETTINGS_FILE = "user://settings.ini"
func _ready() -> void:
	option_pane.visible = false
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
				var fullscreen = config.get_value(item, "Fullscreen")
				fullscreen_check = fullscreen
			elif item == "Audio":
				var volume = config.get_value(item, "Volume")
				volume_check = volume
			
	
	Display_settings(fullscreen_check)
	Audio_settings(volume_check)	
	
	
	

func _process(delta: float) -> void:
	hover_anim(start)
	hover_anim(options)
	hover_anim(quit)
	hover_anim(back)
	hover_anim(back_2)
	hover_anim(input_config)
				
func save_display_settings(key:String, value:bool):
	config.set_value("Display", key, value)
	config.save(SETTINGS_FILE)

func save_audio_settings(key:String, value:float):
	config.set_value("Audio", key, value)
	config.save(SETTINGS_FILE)
	
func Display_settings(fullscreen_check):
	if fullscreen_check == true:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		fullscreen.button_pressed = true
	
	if fullscreen_check == false:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		fullscreen.button_pressed = false
	
	
func Audio_settings(volume_check:float):
	var value = linear_to_db(volume_check)
	AudioServer.set_bus_volume_db(Background_music, value)
	volume_line.value = float(volume_check)
	
			
func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://Assets/Scenes/cutscene.tscn")
	


func _on_options_pressed() -> void:
	option_pane.visible = true


func _on_quit_pressed() -> void:
	get_tree().quit()
	


func _on_fullscreen_toggled(toggled_on: bool) -> void:
	if toggled_on == true:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		save_display_settings("Fullscreen", true)
		
	if toggled_on == false:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		save_display_settings("Fullscreen", false)
		


func _on_back_pressed() -> void:
	option_pane.visible = false
	pass # Replace with function body.
	


func _on_h_slider_value_changed(value: float) -> void:
	var db_value = linear_to_db(value)
	AudioServer.set_bus_volume_db(Background_music, db_value)
	save_audio_settings("Volume", value)
	pass # Replace with function body.


func _on_input_config_pressed() -> void:
	input_ui.visible = true
	
	
func hover_anim(button: Button):
	var tween = create_tween()
	if button.is_hovered():
		tween.tween_property(button, "scale", Vector2.ONE * scale_intensity, duration)
	else:
		tween.tween_property(button, "scale", Vector2.ONE, duration)
	pass

func _on_back_2_pressed() -> void:
	input_ui.visible = false
	
