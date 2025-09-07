extends CharacterBody2D

signal health_changed(health: int)

const SPEED = 300.0
const JUMP_VELOCITY = -400.0

var health: int = 100:
	set(value):
		health = value
		emit_signal("health_changed", value)

var sequence_matcher := FraySequenceMatcher.new()
var sequence_tree := FraySequenceTree.new()

func _ready() -> void:
	FrayInputMap.add_bind_action("right", "ui_right")
	FrayInputMap.add_bind_action("left", "ui_left")
	FrayInputMap.add_bind_action("up", "ui_up")
	FrayInputMap.add_bind_action("down", "ui_down")
	FrayInputMap.add_bind_action("light", "light")
	FrayInputMap.add_bind_action("medium", "medium")
	FrayInputMap.add_bind_action("heavy", "heavy")
	FrayInputMap.add_bind_action("special", "special")

	
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
	
	#print(sequence_matcher._root._next_nodes)
	

func _on_FrayInput_input_detected(input_event: FrayInputEvent) -> void:
	sequence_matcher.read(input_event)

# NOTE: this only applies to sequences, so normal buttons wouldn't work!
func _on_SequenceMatcher_match_found(sequence_name: String) -> void:
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



func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_up") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction := Input.get_axis("ui_left", "ui_right")
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()


func _on_fray_hit_state_manager_2d_hitbox_intersected(detector_hitbox: FrayHitbox2D, detected_hitbox: FrayHitbox2D) -> void:
	
	print(detected_hitbox)
	print(detector_hitbox.attribute._get_damage())
