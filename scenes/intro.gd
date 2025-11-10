class_name Intro extends Control

signal intro_completed

var current_panel: int = 0
var panels: Array[TextureRect] = []
var comic_width: float = 720.0

@onready var color_rect: ColorRect = $ColorRect
@onready var comic_1: TextureRect = $Comic1
@onready var comic_2: TextureRect = $Comic2
@onready var button: Button = $Button


func _ready() -> void:
	panels = [comic_1, comic_2]

	# Make intro process even when paused
	process_mode = Node.PROCESS_MODE_ALWAYS

	# Center all comics horizontally for different screen widths
	var center_offset: float = (size.x - comic_width) / 2.0
	for panel in panels:
		panel.position.x = center_offset

	# Hide all panels except the first
	comic_1.visible = true
	comic_2.visible = false
	button.visible = true

	# Connect button signal
	button.pressed.connect(_on_button_pressed)

	button.grab_focus.call_deferred()


func _on_button_pressed() -> void:
	current_panel += 1

	if current_panel >= panels.size():
		# All comics shown, fade out before exiting
		_fade_out_and_exit()
	else:
		# Show next panel with slide animation
		_transition_to_panel(current_panel)


func _fade_out_and_exit() -> void:
	button.visible = false

	# Fade out comic_3 first, then color_rect, then exit
	var tween := create_tween()
	tween.set_ease(Tween.EASE_IN)
	tween.set_trans(Tween.TRANS_CUBIC)

	# Fade comic_3 first
	tween.tween_property(comic_2, "modulate:a", 0.0, 0.5)

	# Then fade the color_rect (black background)
	tween.tween_property(color_rect, "modulate:a", 0.0, 0.5)

	# Finally emit signal and cleanup
	tween.tween_callback(
		func() -> void:
			intro_completed.emit()
			queue_free()
	)


func _transition_to_panel(panel_index: int) -> void:
	var current_comic: TextureRect = panels[panel_index - 1]
	var next_comic: TextureRect = panels[panel_index]

	# Calculate center offset for 720px comics on potentially wider screens
	var center_offset: float = (size.x - comic_width) / 2.0

	# Position next comic off-screen to the right (centered)
	next_comic.position.x = size.x
	next_comic.visible = true

	# Create tween for slide animation
	var tween := create_tween()
	tween.set_parallel(true)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)

	# Slide current panel out to the left (off-screen)
	tween.tween_property(current_comic, "position:x", -comic_width, 0.5)

	# Slide next panel in to centered position
	tween.tween_property(next_comic, "position:x", center_offset, 0.5)

	# Hide the old panel after animation completes
	tween.chain().tween_callback(func() -> void: current_comic.visible = false)
