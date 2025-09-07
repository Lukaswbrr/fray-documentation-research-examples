extends StaticBody2D

@export var node_path: NodePath
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# source exceptions works!
	$FrayHitbox2D.add_source_exception_with(self)
	$FrayHitbox2D2.add_source_exception_with(self)
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

# seems not to be working.
func _on_fray_hitbox_2d_hitbox_entered(hitbox: FrayHitbox2D) -> void:
	if hitbox.source is CharacterBody2D:
		hitbox.source.health -= 10
		print("ouchieeee!!!!!")
