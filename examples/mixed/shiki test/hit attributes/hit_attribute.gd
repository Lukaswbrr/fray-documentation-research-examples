@tool
class_name HitboxAttribute
extends FrayHitboxAttribute

@export var damage: int
@export var block_damage: int
@export var unblockable: bool
@export var hitstun_frames: int
@export var hitstun_block_frames: int

func get_damage() -> int:
	return damage

func get_hitstun_frames() -> int:
	return hitstun_frames

func _allows_detection_of_impl(attribute: FrayHitboxAttribute) -> bool:
	if attribute is HurtboxAttribute:
		return true
	
	return false

func _get_color_impl() -> Color:
	return Color(1, 0, 0, .5)
