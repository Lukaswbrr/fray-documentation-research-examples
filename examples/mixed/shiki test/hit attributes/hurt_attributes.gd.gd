@tool
class_name HurtboxAttribute
extends FrayHitboxAttribute

@export var is_blocking: bool ## If true, leads to block stun instead of hurt
@export var block_type: String = "normal" ## low, normal, air, all
@export var armor: bool ## If true, doesnt lead to block stun.

func _get_color_impl() -> Color:
	return Color(0, 0.5, 1, .5)

func _allows_detection_of_impl(attribute: FrayHitboxAttribute) -> bool:
	return false
