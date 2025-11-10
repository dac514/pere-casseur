class_name Mob extends CharacterBody2D

@onready var hit_zone: Area2D = $Area2D
@onready var sprite_2d: AnimatedSprite2D = $Sprite2D
@onready var visibility_notifier: VisibleOnScreenNotifier2D = $VisibleOnScreenNotifier2D
@onready var audio_stream_player: AudioStreamPlayer = $AudioStreamPlayer


func _ready() -> void:
	visibility_notifier.screen_exited.connect(_on_screen_exited)
	hit_zone.area_entered.connect(_hit_something)


func _physics_process(delta: float) -> void:
	velocity += get_gravity() * delta * 0.25
	velocity.y = min(750, velocity.y)
	move_and_slide()


func _on_screen_exited() -> void:
	queue_free()


func _hit_something(area: Area2D) -> void:
	if area.get_parent() is Player:
		GameManager.mob_hit()
		audio_stream_player.play()
		audio_stream_player.finished.connect(audio_stream_player.queue_free)
		remove_child(audio_stream_player)
		get_parent().add_child(audio_stream_player)
		queue_free()
