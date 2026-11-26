class_name Mob extends CharacterBody2D

const IMPACT_COLOR: Color = Color(1.0, 0.95, 0.6)
const RICOCHET_TIME: float = 0.6
const MAX_FALL_SPEED: float = 750.0
# Barreling slide: the tube wobbles harder and stretches as it picks up speed
const WOBBLE_DEGREES: float = 9.0
const WOBBLE_SPEED: float = 9.0
const BUMP_SPEED: float = 23.0
const BUMP_HEIGHT: float = 2.5
const MAX_STRETCH: float = 0.18

var is_hit: bool = false
var slide_time: float = randf() * TAU
var snow_spray: CPUParticles2D = null

@onready var hit_zone: Area2D = $Area2D
@onready var sprite_2d: AnimatedSprite2D = $Sprite2D
@onready var visibility_notifier: VisibleOnScreenNotifier2D = $VisibleOnScreenNotifier2D
@onready var audio_stream_player: AudioStreamPlayer = $AudioStreamPlayer


func _ready() -> void:
	visibility_notifier.screen_exited.connect(_on_screen_exited)
	hit_zone.area_entered.connect(_hit_something)
	snow_spray = _make_snow_spray()
	add_child(snow_spray)


func _physics_process(delta: float) -> void:
	velocity += get_gravity() * delta * 0.25
	velocity.y = min(MAX_FALL_SPEED, velocity.y)
	move_and_slide()
	_animate_slide(delta)


func _animate_slide(delta: float) -> void:
	slide_time += delta
	var speed_ratio: float = clampf(velocity.y / MAX_FALL_SPEED, 0.0, 1.0)

	# Inner tube fishtails, wilder the faster it goes
	sprite_2d.rotation = deg_to_rad(WOBBLE_DEGREES) * (0.4 + speed_ratio) * sin(slide_time * WOBBLE_SPEED)
	# Stretch along the direction of travel
	var stretch: float = MAX_STRETCH * speed_ratio
	sprite_2d.scale = Vector2(1.0 - stretch * 0.5, 1.0 + stretch)
	# Bumpy snow
	sprite_2d.position.y = sin(slide_time * BUMP_SPEED) * BUMP_HEIGHT * speed_ratio


## Snow kicked up by the tube. World-space particles, so they get left behind as a wake.
func _make_snow_spray() -> CPUParticles2D:
	var spray := CPUParticles2D.new()
	spray.amount = 48
	spray.lifetime = 0.5
	spray.local_coords = false
	spray.position = Vector2(0, 38)
	spray.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	spray.emission_rect_extents = Vector2(30, 4)
	spray.direction = Vector2(0, -1)
	spray.spread = 75.0
	spray.gravity = Vector2(0, 300)
	spray.initial_velocity_min = 60.0
	spray.initial_velocity_max = 220.0
	spray.damping_min = 80.0
	spray.damping_max = 150.0
	spray.scale_amount_min = 3.0
	spray.scale_amount_max = 7.0
	spray.scale_amount_curve = Fx.shrink_curve()

	var gradient := Gradient.new()
	gradient.set_color(0, Color.WHITE)
	gradient.set_color(1, Color(0.8, 0.9, 1.0, 0.0))
	spray.color_ramp = gradient

	spray.z_index = -1
	return spray


func _on_screen_exited() -> void:
	queue_free()


func _hit_something(area: Area2D) -> void:
	if is_hit:
		return
	var player: Player = area.get_parent() as Player
	if player == null:
		return

	# Only hit once: the elf stays alive while it tumbles away
	is_hit = true
	hit_zone.set_deferred("monitoring", false)

	GameManager.mob_hit()
	audio_stream_player.play()
	audio_stream_player.finished.connect(audio_stream_player.queue_free)
	remove_child(audio_stream_player)
	get_parent().add_child(audio_stream_player)

	player.take_hit(global_position)
	Fx.burst(get_parent() as Node2D, global_position.lerp(player.global_position, 0.5), IMPACT_COLOR, 22, 320.0)
	_ricochet(player.global_position)


func _ricochet(from_pos: Vector2) -> void:
	set_physics_process(false)
	snow_spray.emitting = false

	var dir: float = signf(global_position.x - from_pos.x)
	if dir == 0.0:
		dir = 1.0 if randf() > 0.5 else -1.0

	var tween: Tween = create_tween()

	# Impact squash + white flash
	tween.tween_property(sprite_2d, "scale", Vector2(1.4, 0.6), 0.06)
	tween.parallel().tween_property(sprite_2d, "modulate", Color(2.5, 2.5, 2.5), 0.06)

	# Ricochet: fling up and away, spinning, shrinking, fading
	var fling_to: Vector2 = global_position + Vector2(dir * 260.0, -220.0)
	tween.tween_property(self, "global_position", fling_to, RICOCHET_TIME).set_trans(Tween.TRANS_QUAD).set_ease(
		Tween.EASE_OUT
	)
	tween.parallel().tween_property(self, "rotation", rotation + dir * TAU * 2.0, RICOCHET_TIME)
	tween.parallel().tween_property(sprite_2d, "scale", Vector2(0.6, 0.6), RICOCHET_TIME)
	tween.parallel().tween_property(sprite_2d, "modulate", Color.WHITE, 0.2)
	tween.parallel().tween_property(self, "modulate:a", 0.0, 0.25).set_delay(RICOCHET_TIME - 0.25)
	tween.finished.connect(queue_free)
