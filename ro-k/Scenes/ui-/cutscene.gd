extends Label

var message: String
var number:int = 0
@onready var timer: Timer = $"../Timer"
var timer_running: bool = false
const HAZY_CITY = preload("uid://bciex1hebcjvf")
var allow_change = false
var trial = true
@onready var background: NinePatchRect = $"../NinePatchRect"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	message = "In a distant land not so far away, there was a hunter"
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("ui_cancel"):
		get_tree().quit()
	
	if Input.is_action_just_pressed("Inventory"):
		get_tree().reload_current_scene()
		
	if (Input.is_action_just_pressed("ui_accept") and allow_change == true) and trial == true:
		background.texture = HAZY_CITY
		message = "There lived a hunter that wants to be the greatest in the land"
		text = ""
		number = 0
		trial = false
		
	if timer_running == false:
		timer_running = true
		timer.start()
	pass


func _on_timer_timeout() -> void:
	if number <= message.length() - 1:
		text = text + message[number]
		number = number + 1
		timer_running = false
		allow_change = false
	else:
		allow_change = true
	pass # Replace with function body.
