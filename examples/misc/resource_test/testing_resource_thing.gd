extends Node2D

signal nanaya

@export var resource: TestingResource


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# NOTE: seems to be possible accessing nodes variables with this isntead of resource.thing!
	resource["thing"] = 2
	resource["thing"] = 1
	
	
	print(resource["thing"])
	
	print(has_user_signal("nanaya"))


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
