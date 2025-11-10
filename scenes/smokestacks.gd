class_name Smokestacks extends Sprite2D

@export var animation_duration: float = 3.0

var start_y: float
var final_y: float


func _ready() -> void:
	# Center horizontally (viewport is 720 wide)
	position.x = 360.0

	# Start position: bottom edge of image at viewport bottom
	var viewport_height := get_viewport_rect().size.y
	start_y = viewport_height + 230.0  # Half of image height
	# Final position: full image height
	final_y = start_y - 458.0

	position.y = start_y
	z_index = -2
	visible = false


func animate_in() -> void:
	visible = true
	var tween := create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(self, "position:y", final_y, animation_duration)
