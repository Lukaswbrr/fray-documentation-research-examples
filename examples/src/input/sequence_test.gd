extends CanvasLayer

# TODO: research more about sequence matcher via this experiment.

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
	sequence_tree.add("236grab", FraySequenceBranch.builder().then("down").then("left").then("grab").build())
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
			print("sonic boom!!!")
		"236grab":
			print("wha")
		"236p":
			print("236p!")
		"214p":
			print("214p...")
