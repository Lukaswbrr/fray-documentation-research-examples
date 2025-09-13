extends CharacterBody2D

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

# TODO: add signals for side changes and when characters attacks
# for the attacks, make another signal when it stops attacking (non attack state)
# keep in mind of the block stuns, that only goes back to idle when the timer
# runs out! (which verifies by getting current frame time minus current frame it got hit

signal health_changed(health: int)
signal attacked(did: bool)

# import general functions fray
var fray = preload("res://addons/fray/src/fray.gd")

@export var right_side: bool
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

var _can_normal_jump: bool = true
# what frame in process frame this character got hit
var _hitstun_framehit: int
# how much hitstun this charracter currently has
var _hitstun_current: int
var _enemy_attacking: bool

@export var health: int = 1000:
	set(value):
		health = value
		emit_signal("health_changed", value)

func flip_side():
	_is_right_side = !_is_right_side
	sprites.set_flip_h(_is_right_side)
	
	$FrayHitStateManager2D.scale.x = -$FrayHitStateManager2D.scale.x


	
	# BUG: this always returns false. Maybe var is shared?
	# wait, i guess it makes sense!
	# since its not possible to add FrayInputMap once a input exists, it doesnt update
	# the condition, meaning, it only returns is_on_right from player 1!
	# huh, does that inputs should be created in map scene and not here?
	# needs more testing
	return _is_right_side


func _ready() -> void:
	if right_side:
		flip_side()
	# BUG: when using fray device 0 and 1, with two controllers connected, the
	# both of the characters get controlled at the same time.
	# could it be that the state machine cant differeate the inputs?
	if fray_device > 0 and fray_device + 1 > FrayInput.get_connected_devices().size():
		FrayInput._device_state_by_id[fray_device] = FrayInput.create_virtual_device()
		FrayInput._connect_device(fray_device)
	
	print(FrayInput._device_state_by_id)
	
	#FrayInputMap.add_bind_action("right", "ui_right")
	#FrayInputMap.add_bind_action("left", "ui_left")
	#FrayInputMap.add_bind_action("up", "ui_up")
	#FrayInputMap.add_bind_action("down", "ui_down")
	#FrayInputMap.add_bind_action("light", "light")
	#FrayInputMap.add_bind_action("medium", "medium")
	#FrayInputMap.add_bind_action("heavy", "heavy")
	#FrayInputMap.add_bind_action("special", "special")
	# NOTE: instead of using godot actions, maybe find the godot action
	# and check the inputs that it uses?
	# NOTE: maybe use fray input action thing to allow multiple inputs??
	
	

	state_machine.initialize({}, FrayCompoundState.builder()
		.register_conditions({
			# condition that checks if FrayInput is pressed down
			# NOTE: testing to see if it works so vars wouldnt be necessary if possible
			"is_crouched_pressed" = func(): return FrayInput.is_pressed("down", fray_device),
			"is_able_block" = func(): 
				# TODO: checks if enemy current state has a tag of normal, special or super
				#print(_enemy_attacking)
				# BUG: somehow, if hit on a perfect frame in idle, the player gets hit
				# despite holding back
				return _enemy_attacking,
			"is_pressing_up" = func():
				# NOTE: apparently, this works without buffering presses to the
				# advancer. damn
				return FrayInput.is_pressed("up", fray_device) and _can_normal_jump,
			"is_pressing_back" = func():
				# INFO: something i found during testing thing
				# somehow, transitions are prioriotized over transitions_presses
				# despite setting priority argument like, 10 or -1
				return FrayInput.is_pressed("back", fray_device),
			"is_pressing_forward" = func():
				return FrayInput.is_pressed("forward", fray_device),
			"is_on_ground" = func():
				return is_on_floor(),
			"is_hitstun_done" = func():
				if ( Engine.get_process_frames() - _hitstun_framehit ) > _hitstun_current:
					_hitstun_current = 0
					return true
				
				return false})
		
		.tag_multi(["idle", "walk_forward", "walk_backward"], ["movement"])
		.tag_multi(["jump", "jump_forward", "jump_backward", "superjump"], ["air_movement"])
		.tag("crouch", ["crouch_movement"])
		.tag_multi(["5l", "5m", "5h"], ["normal"])
		.tag("236p", ["special"])
		
		.add_rule("movement", "normal")
		.add_rule("movement", "special")
		.add_rule("crouch_movement", "special")
		.add_rule("movement", "air_movement")
		.add_rule("movement", "crouch_movement")
		.add_rule("normal", "special")
		
		.add_state("hitstun")
		
		.transition("hitstun", "hurt_h", {
			auto_advance=true,
			advance_conditions=["is_hitstun_done"]
		})
		
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
		.transition("block", "idle", {
			auto_advance=true,
			advance_conditions=["!is_able_block"]
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
		
		.transition("block", "walk_backward", {
			auto_advance=true,
			advance_conditions=["is_pressing_back", "!is_able_block"]
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
		
		.transition("walk_backward", "block", {
			auto_advance=true,
			advance_conditions=["is_able_block"]
		})
		
		
		# NOTE: in order to maybe be able to do directional jumps with
		# different states, maybe add small delay? (like jump delay, decides
		# what state to go which button was pressed)
		.transition_sequence("idle", "superjump", {sequence="superjump"})
		.transition_sequence("crouch", "superjump", {sequence="superjump"})
		
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
	
	
	# maybe is this causing the issue?
	#FrayInput.input_detected.connect(_on_FrayInput_input_detected)
	sequence_matcher.match_found.connect(_on_SequenceMatcher_match_found)
	
	# movement
	sequence_tree.add("superjump", FraySequenceBranch.builder().first("down").then("up", 1000).build())
	sequence_tree.add("dash", FraySequenceBranch.builder().then("forward").then("forward").build())
	
	# specials
	sequence_tree.add("236p", FraySequenceBranch.builder().first("down").then("down_forward").then("forward").then("light").build())
	sequence_tree.add("236p", FraySequenceBranch.builder().first("down").then("forward").then("light").build())
	sequence_tree.add("214p", FraySequenceBranch.builder().then("down").then("back").then("light").build())
	## NOTE: figure out a way to do this
	sequence_tree.add("236grab", FraySequenceBranch.builder().then("down").then("back").then("light").then("medium").build())
	sequence_tree.add("236grab", FraySequenceBranch.builder().then("down").then("back").then("medium").then("light").build())
	sequence_tree.add("46charge", FraySequenceBranch.builder().first("back", 500).then("forward").then("light").build())
	sequence_matcher.initialize(sequence_tree)
	
	state_machine.goto_start()
	
# NOTE: this only applies to sequences, so normal buttons wouldn't work!
func _on_SequenceMatcher_match_found(sequence_name: String) -> void:
	# this is to prevent the .transition("idle", "jump") work due to
	# auto pressing up
	if sequence_name == "superjump":
		_can_normal_jump = false
		$NormalJumpReset.start()
	
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
	if not FrayInput.is_device_connected(fray_device):
		return
	
	# NOTE: even if making this only detect device 1, it still counts on both sides.
	if input_event.device == 1 and not input_event.is_echo():
		advancer.buffer_press(input_event.input, input_event.is_pressed())
	
	#sequence_matcher.read(input_event)

	#if not input_event.is_echo():
	#	advancer.buffer_press(input_event.input, input_event.is_pressed())


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
	

func damage(hit_attribute: HitboxAttribute, hurt_attribute: HurtboxAttribute, target):
	var hit_damage = hit_attribute.get_damage()
	var hitstun = hit_attribute.get_hitstun_frames()
	var target_root = target.state_machine.get_root()
	var target_current_state: String = target_root.get_current_state_name()
	
	if not target_current_state == "block":
		if ( target_current_state == "idle" or target_current_state == "walk_backwards" ) and target_root.is_condition_true("is_pressing_back"):
			# NOTE: sometimes, its possible to hit enemies, despite pressing back.
			# this makes sure it doesnt hit and go to block instantly
			# (change to block stun once i add that state)
			# NOTE: maybe this condition is unnecssary since i fixed it!
			# it was probably the way i setup transitions of idle to walk backwards
			# causing error
			print("perfect frame!")
			target.state_machine.goto("block")
			return
		damage_health(hit_damage, hitstun, target)
	pass

func damage_health(value: int, hitstun: int, target):
	target.health -= value
	# NOTE: should the hitbox send the target statemachine to hitstun or
	# should the opponent's state machine automatically go to hitstun?
	# unsure
	target._hitstun_current = hitstun
	target._hitstun_framehit = Engine.get_process_frames()
	target.state_machine.goto("hitstun")

func _on_fray_hit_state_manager_2d_hitbox_intersected(detector_hitbox: FrayHitbox2D, detected_hitbox: FrayHitbox2D) -> void:
	var hit_attribute = detector_hitbox.attribute
	var hurt_attribute = detected_hitbox.attribute
	var state: FrayHitState2D = $FrayHitStateManager2D.get_current_state_obj()
	
	damage(hit_attribute, hurt_attribute, detected_hitbox.source)
	
	if state._is_active:
		#print("it is..")
		pass
	
	#print(state)


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
	var attacks = ["5l", "5m", "5h"]
	# NOTE: maybe use state tags or animation player?
	if to in attacks:
		emit_signal("attacked", true)
	else:
		emit_signal("attacked", false)
	
	match to:
		# attacks
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
		"hitstun":
			# wait until frame time passes to go to the hurt state
			pass
		_:
			if state_machine.get_root().is_condition_true("is_crouched_pressed"):
				state_machine.goto("crouch")
				return
			
			state_machine.goto_start()


func _on_normal_jump_reset_timeout() -> void:
	_can_normal_jump = true


func _on_attacked(did: bool) -> void:
	#print(did)
	pass

# connect this via stage script
func _on_enemy_attack(did: bool) -> void:
	pass


func _on_dual_shiki_attacked(did: bool) -> void:
	_enemy_attacking = did
	pass
