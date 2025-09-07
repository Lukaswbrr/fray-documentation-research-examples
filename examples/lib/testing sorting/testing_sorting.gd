extends Control

const sort = preload("res://addons/fray/lib/helpers/utils/sorting.gd")

## Honeslty, this is weird. Maybe the sorting is obsolote? THere's no way that the sorting is
## supposed to have intentional behavior. Why??

var dir1 = {
	"hhhh" = 10,
}

var dir2 = {
	"hhhh" = 12,
}

var num1 = 10
var num2 = 12

func _ready() -> void:
	print( sort.sort_ascending(num2, num1) )


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
