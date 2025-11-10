class_name Gift extends RigidBody2D

var initial_velocity: Vector2 = Vector2.ZERO

@onready var notifier: VisibleOnScreenEnabler2D = $VisibleOnScreenEnabler2D


func _ready() -> void:
	notifier.screen_exited.connect(_on_screen_exited)
	apply_central_impulse(initial_velocity)


func _on_screen_exited() -> void:
	queue_free()
