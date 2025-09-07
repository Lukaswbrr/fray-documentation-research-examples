extends Node

var fray = preload("res://addons/fray/src/fray.gd")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var msec = fray.frame_to_msec(600)
	var sec = fray.msec_to_sec(msec)
	$Timer.set_wait_time(sec)
	$Timer.start()
	print(verify_type())
	

func verify_type() -> bool:
	return fray.is_of_type(fray, fray)


func _on_timer_timeout() -> void:
	print("timeout!!!")
