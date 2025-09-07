extends CharacterBody2D

signal health_changed(health: int)

const SPEED = 300.0
const JUMP_VELOCITY = -400.0

@onready var state_machine = $FrayStateMachine
@onready var advancer = $FrayStateMachine/FrayBufferedInputAdvancer

var sequence_matcher := FraySequenceMatcher.new()
var sequence_tree := FraySequenceTree.new()

var is_crouched_pressed: bool

var health: int = 100:
	set(value):
		health = value
		emit_signal("health_changed", value)

func _ready() -> void:
	FrayInputMap.add_bind_action("right", "ui_right")
	FrayInputMap.add_bind_action("left", "ui_left")
	FrayInputMap.add_bind_action("up", "ui_up")
	FrayInputMap.add_bind_action("down", "ui_down")
	FrayInputMap.add_bind_action("light", "light")
	FrayInputMap.add_bind_action("medium", "medium")
	FrayInputMap.add_bind_action("heavy", "heavy")
	FrayInputMap.add_bind_action("special", "special")
	
	state_machine.initialize({}, FrayCompoundState.builder()
		# TODO: make it so it transitions globally back to idle if animation
		# ends? not sure if you make this way or just make it via the
		# animation player signal
		.register_conditions({
			"is_crouched_pressed" = func(): return is_crouched_pressed
		})
		
		.tag_multi(["idle","5l", "5m", "5h"], ["normal"])
		.tag("236p", ["special"])
		
		.add_rule("normal", "special")
		
		
		.transition_press("idle", "crouch", {input="down"})
		.transition("crouch", "idle", 
			{
				auto_advance=true,
				advance_conditions=["!is_crouched_pressed"]
			})
	
		.transition_press("idle", "5l", {input="light"})
		.transition_press("5l", "idle", {input="light"})

		.transition_press("idle", "5m", {input="medium"})
		.transition_press("idle", "5h", {input="heavy"})
		
		.transition_press("crouch", "c5l", {input="light"})
		.transition_press("c5l", "crouch", {input="light"})
		
		.transition_sequence_global("236p", {sequence="236p"})
		.build()
	)
	
		## Combinations
	FrayInputMap.add_composite_input("grab", FrayCombinationInput.builder()
		.add_component_simple("light")
		.add_component_simple("medium")
		.mode_sync()
		# is virtual seems to cause issue here
		.build()
	)
	
	## Group inputs
	FrayInputMap.add_composite_input("roman_cancel", FrayGroupInput.builder()
		.add_component_simple("light")
		.add_component_simple("medium")
		.add_component_simple("heavy")
		.add_component_simple("special")
		.min_pressed(3)
		.build()
		)
	
	FrayInput.input_detected.connect(_on_FrayInput_input_detected)
	sequence_matcher.match_found.connect(_on_SequenceMatcher_match_found)
	
	
	sequence_tree.add("236p", FraySequenceBranch.builder().then("down").then("right").then("light").build())
	sequence_tree.add("214p", FraySequenceBranch.builder().then("down").then("left").then("light").build())
	## NOTE: figure out a way to do this
	sequence_tree.add("236grab", FraySequenceBranch.builder().then("down").then("left").then("light").then("medium").build())
	sequence_tree.add("236grab", FraySequenceBranch.builder().then("down").then("left").then("medium").then("light").build())
	sequence_tree.add("46charge", FraySequenceBranch.builder().first("left", 500).then("right").then("light").build())
	sequence_matcher.initialize(sequence_tree)
	
# NOTE: this only applies to sequences, so normal buttons wouldn't work!
func _on_SequenceMatcher_match_found(sequence_name: String) -> void:
	advancer.buffer_sequence(sequence_name)
	
	match sequence_name:
		"light":
			print("ai!!!!")
		"46charge":
			$"FrayHitStateManager2D/46charge".active_hitboxes = 1
		"236grab":
			print("wha")
		"236p":
			# NOTE: when activating one hitbox, while a hitbox from a different state is already active
			# it disables the previous state, only allowing one state with hitbox!
			$"FrayHitStateManager2D/236p".active_hitboxes = 1
		"214p":
			$"FrayHitStateManager2D/214p".active_hitboxes = 1

func _on_FrayInput_input_detected(input_event: FrayInputEvent) -> void:
	sequence_matcher.read(input_event)
	advancer.buffer_press(input_event.input, input_event.is_pressed())
	
	if input_event.input == "down" and input_event.is_pressed():
		is_crouched_pressed = true
	else:
		is_crouched_pressed = false



func _process(delta: float):
	if Input.is_action_just_pressed("ui_accept"):
		# NOTE: if a state has transition_press, this wouldnt advance state!
		# EXAMPLE:
		# .transition_press("a", "b", {input="light"})
		# .transition("a", "c")
		# this would only transition a to c
		state_machine.get_root().print_adj()
		print(is_crouched_pressed)


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


func _on_fray_state_machine_state_changed(from: StringName, to: StringName) -> void:
	print("State transitioned from '%s' to '%s'" % [from, to])
