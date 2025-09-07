extends CharacterBody2D

# NOTE: wip 2d fighting game character example

# TODO:
# - implement buffer cancels 5l > 5m > 5h as if hitting a opponent (dont make it cancel instantly
# before hitbox appear, maybe the animation player sets a variable that its possible to do it?
# if so, the state machine checks if it hit the opponent and if the variable is true (or just make it
# so if the hitbox hits, sets the variable to true and when it  goes to the next state, its set to
# false.
# (if it still happens anyway, make the animationplayer set a certain variable and when the state
# machines go another state, it resets the variable)

# TODO: combo system and hurt states
# if the opponent goes back to idle, it emits a signal that it gone back to idle
# which resets combo counter

signal health_changed(health: int)

@export var fray_device: int # What controller does this use (player 1, 2, etc)
@export var ai_controlled: bool # if ai controlled, ignores fray device
@export var ai_level: int # how difficult is the ai (1 very easy, 10 expert)

@onready var state_machine = $FrayStateMachine
@onready var advancer = $FrayStateMachine/FrayBufferedInputAdvancer
@onready var anim = $AnimatedSprite2D/AnimationPlayer
@onready var sprites = $AnimatedSprite2D

const SPEED = 300.0
const JUMP_VELOCITY = -400.0

var sequence_matcher := FraySequenceMatcher.new()
var sequence_tree := FraySequenceTree.new()

var is_crouched_pressed: bool
# if on right side, sets to true
# NOTE: maybe to flip the hitboxes, set transform size to -1?
var _is_right_side: bool

var health: int = 100:
	set(value):
		health = value
		emit_signal("health_changed", value)

func flip_side():
	_is_right_side = !_is_right_side
	sprites.set_flip_h(_is_right_side)

func is_on_right(device: int):
	return _is_right_side

func _ready() -> void:
	#flip_side()
	
	FrayInputMap.add_bind_action("right", "ui_right")
	FrayInputMap.add_bind_action("left", "ui_left")
	FrayInputMap.add_bind_action("up", "ui_up")
	FrayInputMap.add_bind_action("down", "ui_down")
	FrayInputMap.add_bind_action("light", "light")
	FrayInputMap.add_bind_action("medium", "medium")
	FrayInputMap.add_bind_action("heavy", "heavy")
	FrayInputMap.add_bind_action("special", "special")
	

	state_machine.initialize({}, FrayCompoundState.builder()
		.register_conditions({
			# condition that checks if FrayInput is pressed down
			# NOTE: testing to see if it works so vars wouldnt be necessary if possible
			"is_crouched_pressed" = func(): return FrayInput.is_pressed("down"),
			"is_able_block" = func(): 
				# TODO: checks if enemy current state has a tag of normal, special or super
				var enemy_attacking = false
				return enemy_attacking,
			"is_pressing_up" = func():
				return FrayInput.is_pressed("up"),
			"is_pressing_back" = func():
				# fray input is pressed down prevents 
				return FrayInput.is_pressed("back"),
			"is_pressing_forward" = func():
				return FrayInput.is_pressed("forward"),
			"is_on_ground" = func():
				return is_on_floor()})
		
		.tag_multi(["idle", "walk_forward", "walk_backward"], ["movement"])
		.tag_multi(["jump", "jump_forward", "jump_backward"], ["air_movement"])
		.tag("crouch", ["crouch_movement"])
		.tag_multi(["5l", "5m", "5h"], ["normal"])
		.tag("236p", ["special"])
		
		.add_rule("movement", "normal")
		.add_rule("movement", "special")
		.add_rule("crouch_movement", "special")
		.add_rule("movement", "air_movement")
		.add_rule("movement", "crouch_movement")
		.add_rule("normal", "special")
		
		# movement
		.transition_press("idle", "crouch", {input="down"})
		.transition_press("idle", "block", {
			input="back",
			prereqs=["is_able_block"]
		})
		#.transition("block", "idle", {
		#	auto_advance=true,
		#	advance_conditions=["!is_pressing_back"]
		#})
		# NOTE: not sure if this is gonna work in situations when getting hit
		# during block stun
		.transition_press("block", "idle", {
			input="back",
			is_triggered_on_release=true
		})
		# INFO: seems redutant compared to transition, not using
		#.transition_press("idle", "walk_forward", {
		#	input="right"
		#})
		# NOTE: makes it so it goes to walk, even if holding
		.transition("idle", "walk_forward", {
			auto_advance=true,
			advance_conditions=["is_pressing_forward"]
		})
		
		.transition("idle", "walk_backward", {
			auto_advance=true,
			advance_conditions=["is_pressing_back"]
		})
		
		.transition_press("walk_forward", "idle", {
			input="forward",
			is_triggered_on_release=true
		})
		
		.transition_press("walk_backward", "idle", {
			input="back",
			is_triggered_on_release=true
		})
		
		
		# NOTE: in order to maybe be able to do directional jumps with
		# different states, maybe add small delay? (like jump delay, decides
		# what state to go which button was pressed)
		.transition_press("idle", "jump", {input="up"})
		# NOTE: for higher priorities transitions, like is crouched pressed and on ground
		# put it on top of previous conditions transitions
		# otherwise it wouldnt trigger!
		.transition("jump", "crouch", {
			auto_advance=true,
			advance_conditions=["is_on_ground", "is_crouched_pressed"]
		})
		.transition("jump_forward", "crouch", {
			auto_advance=true,
			advance_conditions=["is_on_ground", "is_crouched_pressed"]
		})
		.transition("jump_backward", "crouch", {
			auto_advance=true,
			advance_conditions=["is_on_ground", "is_crouched_pressed"]
		})
		.transition("jump", "idle", {
			auto_advance=true,
			advance_conditions=["is_on_ground"]
		})
		.transition("jump_forward", "idle", {
			auto_advance=true,
			advance_conditions=["is_on_ground"]
		})
		.transition("jump_backward", "idle", {
			auto_advance=true,
			advance_conditions=["is_on_ground"]
		})
	
		.transition_sequence("jump", "airdash", {sequence="dash"})
		.transition("airdash", "idle", {
			auto_advance=true,
			advance_conditions=["is_on_ground"]
		})
		.transition_press("crouch", "superjump", {input="up"})
		.transition("superjump", "idle", {
			auto_advance=true,
			advance_conditions=["is_on_ground"]
		})
		.transition("crouch", "idle", {
			auto_advance=true,
			advance_conditions=["!is_crouched_pressed"]
		})
		
		.transition_sequence_global("236p", {sequence="236p"})
		
		.transition_press_global("5l", {input="light"})

		.transition_press_global("5m", {input="medium"})
		.transition_press_global("5h", {input="heavy"})
		
		# NOTE: makes it so it jumps, even when holding
		.transition("idle", "jump", {
			auto_advance=true,
			advance_conditions=["is_pressing_up"]
		})
		.transition("walk_forward", "jump_forward", {
			auto_advance=true,
			advance_conditions=["is_pressing_up"]
		})
		.transition("walk_backward", "jump_backward", {
			auto_advance=true,
			advance_conditions=["is_pressing_up"]
		})
		
		.transition_press_global("crouch", {input="down"})
		
		.transition_press("crouch", "c5l", {input="light"})
		
		.transition_sequence_global("236p", {sequence="236p"})
		.build()
	)
	
		## Combinations
	FrayInputMap.add_composite_input("grab", FrayCombinationInput.builder()
		.add_component_simple("light")
		.add_component_simple("medium")
		.mode_sync()
		.build()
	)
	
	FrayInputMap.add_composite_input("forward", FrayConditionalInput.builder()
		.add_component_simple("right")
		.add_component_simple("left").use_condition(is_on_right)
		.is_virtual()
		.build()
	)
	
	FrayInputMap.add_composite_input("back", FrayConditionalInput.builder()
		.add_component_simple("left")
		.add_component_simple("right").use_condition(is_on_right)
		.is_virtual()
		.build()
	)
	
	FrayInputMap.add_composite_input("down_forward", FrayConditionalInput.builder()
		.add_component(FrayCombinationInput.builder()
			.add_component_simple("down")
			.add_component_simple("right")
			.mode_async()
			.build()
		)
		.add_component(FrayCombinationInput.builder()
			.add_component_simple("down")
			.add_component_simple("left")
			.mode_async()
			.build()
		).use_condition(is_on_right)
		.is_virtual()
		# NOTE: without priority, this doesnt work on 236p!
		.priority(1)
		.build()
	)
	
	FrayInputMap.add_composite_input("down_back", FrayConditionalInput.builder()
		.add_component(FrayCombinationInput.builder()
			.add_component_simple("down")
			.add_component_simple("left")
			.mode_async()
			.build()
		)
		.add_component(FrayCombinationInput.builder()
			.add_component_simple("down")
			.add_component_simple("right")
			.mode_async()
			.build()
		).use_condition(is_on_right)
		.is_virtual()
		.priority(1)
		.build()
	)
	
	FrayInputMap.add_composite_input("up_forward", FrayConditionalInput.builder()
		.add_component(FrayCombinationInput.builder()
			.add_component_simple("up")
			.add_component_simple("right")
			.mode_async()
			.build()
		)
		.add_component(FrayCombinationInput.builder()
			.add_component_simple("up")
			.add_component_simple("left")
			.mode_async()
			.build()
		).use_condition(is_on_right)
		.is_virtual()
		.priority(1)
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
	
	sequence_tree.add("236p", FraySequenceBranch.builder().first("down").then("down_forward").then("forward").then("light").build())
	sequence_tree.add("236p", FraySequenceBranch.builder().first("down").then("forward").then("light").build())
	sequence_tree.add("214p", FraySequenceBranch.builder().then("down").then("back").then("light").build())
	## NOTE: figure out a way to do this
	sequence_tree.add("236grab", FraySequenceBranch.builder().then("down").then("back").then("light").then("medium").build())
	sequence_tree.add("236grab", FraySequenceBranch.builder().then("down").then("back").then("medium").then("light").build())
	sequence_tree.add("46charge", FraySequenceBranch.builder().first("back", 500).then("forward").then("light").build())
	sequence_tree.add("dash", FraySequenceBranch.builder().then("forward").then("forward").build())
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
#			$"FrayHitStateManager2D/236p".active_hitboxes = 1
			print("hey?")
		"214p":
			$"FrayHitStateManager2D/214p".active_hitboxes = 1

func _on_FrayInput_input_detected(input_event: FrayInputEvent) -> void:
	sequence_matcher.read(input_event)

	if not input_event.is_echo():
		advancer.buffer_press(input_event.input, input_event.is_pressed())


func _process(delta: float):
	if Input.is_action_just_pressed("ui_accept"):
		state_machine.get_root().print_adj()
		flip_side()


func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction := Input.get_axis("ui_left", "ui_right")
	
	match state_machine.get_root().get_current_state_name():
		"airdash":
			if _is_right_side:
				velocity.x = -SPEED * 2
			else:
				velocity.x = SPEED * 2
		"jump_forward":
			if _is_right_side:
				velocity.x = -SPEED * 2
			else:
				velocity.x = SPEED * 2
		"jump_backward":
			if _is_right_side:
				velocity.x = SPEED * 2
			else:
				velocity.x = -SPEED * 2
		"idle", "block", "crouch":
			velocity.x = 0
		"walk_forward": 
			if _is_right_side:
				velocity.x = -SPEED
			else:
				velocity.x = SPEED
		"walk_backward":
			# NOTE: flips velocity if on right side 
			# this doesnt use 
			if _is_right_side:
				velocity.x = SPEED
			else:
				velocity.x = -SPEED
		_:
			velocity.x = 0
	
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
	$State.set_text(to)
	
	# anim match to
	match to:
		"jump", "superjump":
			anim.play("jump_neutral")
		_:
			anim.play(to)
	
	# NOTE: maybe make it so when changing to states, it triggers vars
	# on physics process to make them move??
	# could be a way to fix idle moving to block
	# would require every state to be manual
	match to:
		"jump", "jump_forward", "jump_backward":
			velocity.y = JUMP_VELOCITY
		"superjump":
			velocity.y = JUMP_VELOCITY * 2


func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	# NOTE: only root states has conditions and not state machine, keep that in mind!
	match anim_name:
		# WARNING: this uses animation to detect the what state it uses, not the actual state machine!
		"jump_neutral", "jump_forward", "jump_backward":
			# makes it not go to start state (idle), waits for auto transition
			pass
		_:
			if state_machine.get_root().is_condition_true("is_crouched_pressed"):
				state_machine.goto("crouch")
				return
			
			state_machine.goto_start()
