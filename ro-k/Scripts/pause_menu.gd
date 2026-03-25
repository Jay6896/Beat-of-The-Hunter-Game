extends CanvasLayer

@onready var overlay = $Overlay
@onready var pause_icon = $PauseIcon

func _ready():
	# Hide the gray overlay and resume button when the game starts
	overlay.visible = false

# Triggered when you click the little pause icon in the corner
func _on_pause_icon_pressed() -> void:
	get_tree().paused = true      # Freeze the game
	overlay.visible = true        # Show the gray screen and Resume button
	pause_icon.visible = false    # Hide the pause icon so they don't click it twice

# Triggered when you click the big Resume button in the middle
func _on_resume_button_pressed() -> void:
	get_tree().paused = false     # Unfreeze the game
	overlay.visible = false       # Hide the gray screen
	pause_icon.visible = true     # Bring the pause icon back
