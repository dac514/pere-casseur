extends Label

@export var gifts_counter: float = 0.0:
	set(value):
		gifts_counter = value
		_update_display()

@export var count_per_second: int = 1

var is_finished: bool = false


func _ready() -> void:
	# Initialize gifts_counter from GameManager constant
	if gifts_counter == 0.0:
		gifts_counter = GameManager.gifts_counter

	_update_display()


func _process(delta: float) -> void:
	# If we are finished, do nothing
	if is_finished:
		return

	# Get dynamic delivery rate from GameManager
	var current_rate := GameManager.get_delivery_rate()
	var decrement_amount: float = current_rate * delta

	# Decrement and use max(0.0, ...) to ensure it doesn't go negative
	gifts_counter = max(0.0, gifts_counter - decrement_amount)

	# Update the display
	_update_display()

	# Check for completion
	if gifts_counter <= 0.0:
		_finish_countdown()

	if gifts_counter >= 0.0:
		GameManager.gifts_counter = gifts_counter


func _update_display() -> void:
	text = _format_number(gifts_counter)
	queue_redraw()


func _finish_countdown() -> void:
	GameManager.gifts_counter = 0.0
	is_finished = true
	set_process(false)


# Helper function to format a number with commas as thousands separators
func _format_number(num: float) -> String:
	var s: String = str(int(num))
	var result: String = ""
	var i: int = s.length() - 1
	var count: int = 0
	while i >= 0:
		result = s[i] + result
		count += 1
		if count % 3 == 0 and i > 0:
			result = "," + result
		i -= 1
	return result
