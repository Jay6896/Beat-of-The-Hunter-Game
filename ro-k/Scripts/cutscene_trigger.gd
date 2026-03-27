extends Area2D

@export_multiline var cutscene_dialogue: String = "You dare challenge me?"
@export var story_ui: CanvasLayer 

func _on_body_entered(body: Node2D) -> void:
	if body.name == "CharacterBody2D" and story_ui:
		# --- NEW: Turn off the player's ability to jump! ---
		if body.has_method("disable_jump"):
			body.disable_jump()
			
		story_ui.trigger_mid_level_text(cutscene_dialogue)
		queue_free()
