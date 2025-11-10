extends Label

var elapsed_time: float = 0.0


func _process(delta: float) -> void:
	# Accumulate the time passed since the last frame
	elapsed_time += delta

	# Calculate minutes and seconds
	var total_seconds: int = int(elapsed_time)
	var minutes: int = int(total_seconds / 60.0)
	var seconds: int = total_seconds % 60

	# Update the Label's text using formatted string for MM:SS
	# "%02d" ensures leading zeroes (e.g., 05 instead of 5)
	text = "%02d:%02d" % [minutes, seconds]
