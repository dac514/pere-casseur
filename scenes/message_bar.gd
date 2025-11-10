class_name MessageBar extends Control

const WAIT_TIME: float = 6.0

# Message queue and tracking
var message_queue: Array[String] = []
var current_message: String = ""
var is_animating: bool = false
var current_tween: Tween

@onready var background: ColorRect = $ColorRect
@onready var label: Label = $ColorRect/Label


func _ready() -> void:
	modulate.a = 0.0
	# Start hidden to the left (anchors handle vertical positioning)
	position.x = -get_size().x


func set_text(text: String) -> void:
	# Don't add duplicate messages to queue
	if text == current_message:
		return

	# Don't add if message is already in queue
	if text in message_queue:
		return

	# Add to queue
	message_queue.append(text)

	# Process queue if not currently animating
	if not is_animating:
		_process_message_queue()


func _process_message_queue() -> void:
	if message_queue.is_empty() or is_animating:
		return

	# Get next message from queue
	var next_message: String = message_queue.pop_front()
	current_message = next_message
	label.text = next_message

	# Start animation
	is_animating = true
	_show_and_hide_message()


func _show_and_hide_message() -> void:
	# Kill any existing tween
	if current_tween:
		current_tween.kill()

	current_tween = create_tween()

	# Get viewport dimensions
	var viewport_rect: Rect2 = get_viewport_rect()
	var center_x: float = viewport_rect.size.x / 2.0 - get_size().x / 2.0
	var left_hidden_x: float = -get_size().x
	var right_hidden_x: float = viewport_rect.size.x

	# Ensure we start from the left
	position.x = left_hidden_x
	modulate.a = 1.0

	# Slide in from left
	current_tween.tween_property(self, "position:x", center_x, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	# Wait for message to be read
	current_tween.tween_interval(WAIT_TIME)

	# Slide out to the right
	current_tween.tween_property(self, "position:x", right_hidden_x, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

	# Wait for animation to complete
	await current_tween.finished

	# Reset state
	is_animating = false
	current_message = ""

	# Process next message in queue if any
	_process_message_queue()
