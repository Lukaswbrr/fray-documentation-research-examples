extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_character_2d_health_changed(health: int) -> void:
	var text = $Label.get_text()
	var split = text.split(":")
	$Label.set_text(split[0] + ": " + str(health))
