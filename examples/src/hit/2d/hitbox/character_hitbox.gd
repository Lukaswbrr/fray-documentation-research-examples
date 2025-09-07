extends FrayHitbox2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super._ready()
	source = get_parent()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
