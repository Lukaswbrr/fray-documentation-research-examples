extends FrayHitbox2D


# Damn, so the reason why this wasnt working was due to ready getting overwrriten.
# bruh
func _ready() -> void:
	super._ready()
	source = get_parent()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
