extends CharacterBody2D

signal health_changed(health: int)

const SPEED = 300.0
const JUMP_VELOCITY = -400.0

var health: int = 100:
	set(value):
		health = value
		emit_signal("health_changed", value)

func _ready() -> void:
	$FrayHitStateManager2D/state1.set_hitbox_active(0, true)
	print("hey????")

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction := Input.get_axis("ui_left", "ui_right")
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()

# TODO: Learn more about the hit state and hit state manager and learn a way for hitboxes only to be
# detected if its from the active state.
func _on_fray_hit_state_manager_2d_hitbox_intersected(detector_hitbox: FrayHitbox2D, detected_hitbox: FrayHitbox2D) -> void:
	var state: FrayHitState2D = $FrayHitStateManager2D.get_current_state_obj()
	#var state_hitboxes: Array[FrayHitbox2D] = state.get_hitboxes()
	#var hitbox_index = state_hitboxes.find(detector_hitbox)
	#
	#if hitbox_index == -1:
		#return
	#
	#if state.is_hitbox_active(hitbox_index):
		#print("it is!!!")
		#print(detected_hitbox)
	
	if state._is_active:
		print("it is..")
	
	print(state)
	
	
	
