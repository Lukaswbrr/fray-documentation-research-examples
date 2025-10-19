extends CanvasLayer

@onready var player1: FrayCharacter = $KFM
@onready var player2: FrayCharacter = $KFM2

const AXIS_DEADZONE := 0.30

var _allowed_states_flipside = ["idle", "crouch"]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	FrayInput.input_detected.connect(_on_FrayInput_input_detected)
	
	_setup_inputs()

func _physics_process(delta: float) -> void:
	var player1_state = player1.state_machine.get_root().get_current_state_name()
	var player2_state = player2.state_machine.get_root().get_current_state_name()
	
	if (player1.position.x > player2.position.x):
		if player1_state in _allowed_states_flipside and !player1._is_right_side:
			player1.flip_side()
		
		if player2_state in _allowed_states_flipside and player2._is_right_side:
			player2.flip_side()
	else:
		if player1_state in _allowed_states_flipside and player1._is_right_side:
			player1.flip_side()
		
		if player2_state in _allowed_states_flipside  and !player2._is_right_side:
			player2.flip_side()
	

func is_on_right(device: int):
	if device == $KFM.fray_device:
		return $KFM._is_right_side
	
	if device == $KFM2.fray_device:
		return $KFM2._is_right_side

func _setup_inputs() -> void:
	FrayInputMap.add_bind_joy_button("up", JOY_BUTTON_DPAD_UP)
	FrayInputMap.add_bind_joy_button("down", JOY_BUTTON_DPAD_DOWN)
	FrayInputMap.add_bind_joy_button("left", JOY_BUTTON_DPAD_LEFT)
	FrayInputMap.add_bind_joy_button("right", JOY_BUTTON_DPAD_RIGHT)
	FrayInputMap.add_bind_joy_button("light", JOY_BUTTON_X)
	FrayInputMap.add_bind_joy_button("medium", JOY_BUTTON_Y)
	FrayInputMap.add_bind_joy_button("heavy", JOY_BUTTON_B)
	FrayInputMap.add_bind_joy_button("special", JOY_BUTTON_A)
	
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

func _on_FrayInput_input_detected(input_event: FrayInputEvent) -> void:
	# NOTE: even if making this only detect device 1, it still counts on both sides.
	if $KFM.fray_device == input_event.device:
		$KFM.sequence_matcher.read(input_event)
		
		if not input_event.is_echo():
			$KFM.advancer.buffer_press(input_event.input, input_event.is_pressed())

	if $KFM2.fray_device == input_event.device:
		$KFM2.sequence_matcher.read(input_event)

		if not input_event.is_echo():
			$KF2.advancer.buffer_press(input_event.input, input_event.is_pressed())

# when opponent goes to idle state, when this character combo var is above 0, resets it
# should be connected on stage.
func _on_combo_reset():
	pass
