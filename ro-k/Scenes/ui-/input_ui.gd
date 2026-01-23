extends Control
@onready var input_button: Button = $Button
const INPUT_BUTTON = preload("uid://bdhl358igdt6s")
var check_input = false
var check_label:Label
@onready var action_list: VBoxContainer = $PanelContainer/VBoxContainer/MarginContainer/VBoxContainer/ScrollContainer/ActionList
var performance:String
var config = ConfigFile.new()
var SETTINGSFILE = "user://settings.ini"
var actions = {
	"move up":["move up","ui_up"],
	"move right":["move right","ui_right"],
	"move down":["move down","ui_down"],
	"move left":["move left","ui_left"],
	"jump":["jump","ui_accept"],
	"cancel":["cancel","ui_cancel"],
	"Attack":["Attack", "Attack"],
	"Inventory":["Inventory", "Inventory"]
	 }
func _ready() -> void:
	if !FileAccess.file_exists(SETTINGSFILE):
		config.set_value("Keybindings", "move up", 4194320)
		config.set_value("Keybindings", "move right", 4194321)
		config.set_value("Keybindings", "move down", 4194322)
		config.set_value("Keybindings", "move left", 4194319)
		config.set_value("Keybindings", "jump", 32)
		config.set_value("Keybindings", "cancel", 4194305)
		config.set_value("Keybindings", "Attack", 76)
		config.save(SETTINGSFILE)
	else:
		config.load(SETTINGSFILE)
		for input in config.get_section_keys("keybindings"):
			var event_check = InputEventKey.new()
			var value = config.get_value("keybindings", input)
			event_check["keycode"] = value
			InputMap.action_erase_events(actions[input][1])
			InputMap.action_add_event(actions[input][1], event_check)
		
	for item in action_list.get_children():
		item.queue_free()
		
	
	create_action_button(INPUT_BUTTON)
	
		
func create_action_button(input_button) -> void:
	for action in actions:
			var button = input_button.instantiate()
			var action_name = button.find_child("Action_name")
			var event_name: Label = button.find_child("Event_name")
			var Abutton = button.find_child("Button")
			action_name.text = actions[action][0]
			var events = InputMap.action_get_events(actions[action][1])
			if events.size() > 0:
				event_name.text = events[0].as_text().trim_suffix(" (Physical)")
			
			action_list.add_child(button)
			Abutton.pressed.connect(_on_button_pressed.bind(event_name, action))
			
				
			
func save_input_event(action, event:InputEventKey):
	print(event.keycode)
	config.set_value("keybindings", action, event.keycode)
	config.save(SETTINGSFILE)
	
func _on_button_pressed(event_name, action):
	event_name.text = "Enter a key"
	check_input = true
	check_label = event_name
	performance = action
	
	
	
func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		if check_input == true:
			_Change_event(event)
			check_input = false
		
			
func _Change_event(event):
	check_label.text = event.as_text()
	InputMap.action_erase_events(actions[performance][1])
	InputMap.action_add_event(actions[performance][1], event)
	save_input_event(actions[performance][0], event)
	
	
			
	
	
