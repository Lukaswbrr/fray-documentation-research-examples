@tool
@icon("res://addons/fray/assets/icons/hit_attribute.svg")
class_name FrayHitboxAttributeTest
extends FrayHitboxAttribute

## Apparently, this seems to be a tool script. Why though? 
## The _ functions seems to be have predefined attributes. Is this something unfinished???
## That's weird.
## Oh wait, it's meant to be overwritten.
# Maybe this could be useful, for example, making custom hit colors, effects? probably

## Abstract data class used to define hitbox attribute.

## Returns the color a hitbox with this attribute should be.

@export var color: Color
@export var damage: int

## [code]Virtual method[/code] used to implement [method get_color].
## Currently this does nothing for [FrayHitbox3D].
func _get_color_impl() -> Color:
	return Color(1, 0, 0, 0.5)

func _get_damage():
	return damage

## [code]Virtual method[/code] used to implement [method allows_detection_of] method
func _allows_detection_of_impl(attribute: FrayHitboxAttribute) -> bool:
	return true
