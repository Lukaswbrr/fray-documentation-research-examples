@tool
class_name HitboxAttribute
extends FrayHitboxAttribute

@export var damage: int
@export var guard_damage: int
## How does the opponent react to the attack if hit?
@export var hit_anim_type: String
## How to block the attack?
## H - High (blocks stand)
## L - Low (blocks crouch)
## M - Medium (blocks stand, air and crouch (equilavent of HL)
## A - Air (blocks air)
# NOTE: figure out a way to use a list of checkbox instead
@export var hit_guard_type: String 

## If the attack is standing, crouch or air
@export var attack_type: String

## If the attack is a normal, special, super or grab
@export var attack_type_2: String

## The amount of frames the opponent will slide on the ground.
# NOTE: only works if the opponent is on the ground!
# WARNING: somehow, slide time doesnt work on ikemen go?? like
# i dont notice any differences in ikemen go
@export var slide_time: int

## How much it pushes the enemy back pause time
@export var hit_velocity: Vector2

## Amount of damping to apply. Must be below 1 to reduce velocity!
@export var hit_damping: float

## How much it pushes the attacker back if hit the enemy on wall
# default value = hit_velocity / 2
@export var hit_attacker_wall_velocity: Vector2

## How much damage the attack will do if blocked
@export var block_damage: int

## If true, then the opponent cannot block this attack.
@export var unblockable: bool

## If hit on a opponent, how much the attacker pauses?
# equilavent of pausetime (attacker value)
@export var attacker_pausetime: int

## How much should the opponent be paused if hit?
# equilavent of pausetime (opponent value)
@export var hitshake_frames: int

## The amount of frames the opponent will be in hit state (after pause time
## ends and recovery animation played)
@export var hitstate_frames: int

## How much should the oppoent be paused if he blocked this attack?
@export var hitshake_block_frames: int

# Ikemen go attributes references
#attr = S, NA                     ;Attribute: Standing, Normal Attack
#damage = 23, 0                   ;Damage that move inflicts, guard damage
#animtype = Light                 ;Animation type: Light, Medium, Heavy, Back (def: Light)
#guardflag = MA                   ;Flags on how move is to be guarded against
#hitflag = MAF                    ;Flags of conditions that move can hit
#priority = 3, Hit                ;Attack priority: 0 (least) to 7 (most), 4 default
#;Hit/Miss/Dodge type (Def: Hit)
#pausetime = 8, 80                 ;Time attacker pauses, time opponent shakes
#sparkno = 0                      ;Spark anim no (Def: set above)
#sparkxy = -10, -76               ;X-offset for the "hit spark" rel. to p2,
#;Y-offset for the spark rel. to p1
#hitsound = 5, 0                  ;Sound to play on hit
#guardsound = 6, 0                ;Sound to play on guard
#ground.type = High               ;Type: High, Low, Trip (def: Normal)
#ground.slidetime = 5             ;Time that the opponent slides back
#ground.hittime  = 110             ;Time opponent is in hit state
#ground.velocity = -4             ;Velocity at which opponent is pushed
#airguard.velocity = -1.9,-.8     ;Guard velocity in air (def: (air.xvel*1.5, air.yvel/2))
#air.type = High                  ;Type: High, Low, Trip (def: same as ground.type)
#air.velocity = -1.4,-3           ;X-velocity at which opponent is pushed,
#;Y-velocity at which opponent is pushed
#air.hittime = 15                 ;Time before opponent regains control in air

func get_damage() -> int:
	return damage

func get_hitstun_frames() -> int:
	return hitstate_frames

func get_hitshake_frames() -> int:
	return hitshake_frames

func _allows_detection_of_impl(attribute: FrayHitboxAttribute) -> bool:
	if attribute is HurtboxAttribute:
		return true
	
	return false

func _get_color_impl() -> Color:
	return Color(1, 0, 0, .5)
