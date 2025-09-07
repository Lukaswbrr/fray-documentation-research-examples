extends Node2D

@onready var fray_anim = $FrayAnimationObserver

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var start = fray_anim.usignal_started("aa")
	
	start.connect(print_thing)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func print_thing():
	print("adad")


func _on_timer_timeout() -> void:
	$AnimationPlayer.play("aa")
