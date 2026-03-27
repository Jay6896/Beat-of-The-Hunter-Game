extends Area2D

@export var heal_amount: float = 25.0

func _on_body_entered(body: Node2D) -> void:
	if body.has_method("heal"):
		# Try to heal the player, and store their answer in a variable
		var item_was_used = body.heal(heal_amount)
		
		# Only delete the item if the player actually needed the health!
		if item_was_used == true:
			queue_free()
