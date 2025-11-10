class_name Fuel extends Area2D

@onready var visibility_notifier: VisibleOnScreenNotifier2D = $VisibleOnScreenNotifier2D
@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var audio_stream_player: AudioStreamPlayer = $AudioStreamPlayer


func _ready() -> void:
	visibility_notifier.screen_exited.connect(_on_screen_exited)


func release(_ammount: int) -> void:
	audio_stream_player.play()
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(sprite_2d, "scale", Vector2(2, 2), 0.5)
	tween.tween_property(sprite_2d, "modulate:a", 0.0, 0.5)
	tween.finished.connect(queue_free)


func _on_screen_exited() -> void:
	queue_free()
