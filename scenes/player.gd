class_name Player extends CharacterBody2D

const GIFT_SCENE = preload("res://entities/gift/gift.tscn")

const FRICTION: float = 0.925
const MAX_FALL_SPEED: float = 420.0
const HORIZONTAL_ACCEL: float = 1800.0
const KNOCKBACK_SPEED: float = 350.0
const KNOCKBACK_DECAY: float = 1400.0
const SHAKE_STRENGTH: float = 12.0
const HIT_COLOR: Color = Color(1.0, 0.25, 0.25)

var fall_speed: float = 150.0
var horizontal_speed: float = 300.0
var throw_speed: float = 500.0
var throw_angle: float = -500.0
var gift_interval: float = 1.0
var gift_ammount: int = 1
var default_smoke_amount: float = 0.1
var default_smoke_lifetime: float = 3.0
var default_fall_speed: float = 150.0
var elapsed_time: float = 0.0
var target_x: float = -1.0
var knockback_x: float = 0.0
var pickup_tween: Tween = null
var hit_tween: Tween = null
var shake_tween: Tween = null

@onready var hit_zone: Area2D = $Area2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var boost_timer: Timer = $BoostTimer
@onready var gift_timer: Timer = $GiftTimer
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var smoke: GPUParticles2D = $Smoke
@onready var camera: Camera2D = $Camera2D


func _ready() -> void:
	gift_timer.start(gift_interval)
	hit_zone.area_entered.connect(_on_collectible_collected)
	GameManager.tier_unlocked.connect(_on_tier_unlocked)


func _input(event: InputEvent) -> void:
	if (
		event is InputEventMouseButton
		and (event as InputEventMouseButton).pressed
		and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT
	):
		var mouse_pos := get_viewport().get_mouse_position()
		var screen_size := get_viewport_rect().size
		target_x = clamp(mouse_pos.x, 0, screen_size.x)
	elif event is InputEventScreenTouch and (event as InputEventScreenTouch).pressed:
		var screen_size := get_viewport_rect().size
		target_x = clamp((event as InputEventScreenTouch).position.x, 0, screen_size.x)


func _physics_process(delta: float) -> void:
	var direction: float = Input.get_axis("ui_left", "ui_right")

	if direction != 0:
		target_x = -1.0
		velocity.x = direction * horizontal_speed
	elif target_x >= 0:
		# Player is using mouse or touch
		var dir: float = sign(target_x - global_position.x)
		velocity.x = dir * horizontal_speed
		if abs(global_position.x - target_x) < 5.0:
			target_x = -1.0
			velocity.x = 0.0
	else:
		velocity.x = 0.0

	# Update sprite flip based on movement direction
	if velocity.x < 0:
		sprite.flip_h = false
		smoke.position = Vector2(50, 0)
	elif velocity.x > 0:
		sprite.flip_h = true
		smoke.position = Vector2(-50, 0)

	# Knockback from elf hits (applied after facing so Santa doesn't flip)
	velocity.x += knockback_x
	knockback_x = move_toward(knockback_x, 0.0, KNOCKBACK_DECAY * delta)

	velocity.y = fall_speed

	move_and_slide()

	elapsed_time += delta


func throw_gift() -> void:
	var gift: Gift = GIFT_SCENE.instantiate()
	var throw_direction: int = -1 if sprite.flip_h else 1

	# Create circular spread behind player
	var angle: float = randf_range(45, 315) if throw_direction == -1 else randf_range(-45, 225)

	# Scale with amount
	var radius: float = randf_range(30.0, 100.0 + gift_ammount * 3.0)
	var spawn_offset: Vector2 = Vector2(cos(deg_to_rad(angle)) * radius, sin(deg_to_rad(angle)) * radius - 50)

	if gift_ammount == 1:
		# Override, centered to player
		spawn_offset = Vector2(-30 * throw_direction, -10)

	gift.global_position = global_position + spawn_offset
	gift.z_index = -2

	var angle_variation: float = randf_range(-100, 0)
	var speed_variation: float = randf_range(-50, 100)
	var final_throw_speed: float = throw_speed + speed_variation

	gift.initial_velocity = Vector2(final_throw_speed * throw_direction, throw_angle + angle_variation)
	get_parent().add_child(gift)


func game_over() -> void:
	gift_timer.stop()
	boost_timer.stop()


func _on_gift_timer_timeout() -> void:
	for i in range(gift_ammount):
		throw_gift()


func _on_collectible_collected(area: Area2D) -> void:
	if not area is Collectible:
		return
	var collectible: Collectible = area as Collectible

	# Check what type of collectible was collected
	if collectible is Fuel:
		GameManager.collect_fuel(collectible as Fuel)
		_smoke_boost(1.0, 0.7, 1.7)
		_play_pickup_feedback(collectible.burst_color, "+10%")
	elif collectible is Oil:
		GameManager.collect_oil(collectible as Oil)
		_smoke_boost(1.0, 0.9, 2.0)
		_play_pickup_feedback(collectible.burst_color, "+25%")
	elif collectible is Bribe:
		GameManager.collect_bribe(collectible as Bribe)
		_smoke_boost(default_smoke_amount, default_smoke_lifetime, 1.5)
		_play_pickup_feedback(collectible.burst_color, "+50%")


func _play_pickup_feedback(color: Color, text: String) -> void:
	# Instant impact on contact; the item itself then flies to the multiplier
	Fx.burst(self, global_position, color, 18, 220.0, true)
	# Fire sparks blast out of the exhaust (smoke sits behind Santa, on the side he's leaving)
	var exhaust_dir := Vector2(signf(smoke.position.x), -0.35).normalized()
	Fx.fire_sparks(self, smoke.global_position, exhaust_dir)
	Fx.popup_text(get_parent() as Node2D, global_position + Vector2(0, -70), text, color.lightened(0.3))

	# Don't stomp on the hit reaction
	if hit_tween and hit_tween.is_running():
		return

	if pickup_tween:
		pickup_tween.kill()
	pickup_tween = create_tween()
	pickup_tween.set_parallel(true)
	pickup_tween.tween_property(sprite, "scale", Vector2(1.25, 0.8), 0.06)
	pickup_tween.tween_property(sprite, "modulate", color.lightened(0.5), 0.06)
	pickup_tween.chain().tween_property(sprite, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_ELASTIC).set_ease(
		Tween.EASE_OUT
	)
	pickup_tween.tween_property(sprite, "modulate", Color.WHITE, 0.25)


## Called by Mob when an elf slams into Santa.
func take_hit(from_pos: Vector2) -> void:
	var away: float = signf(global_position.x - from_pos.x)
	if away == 0.0:
		away = 1.0 if randf() > 0.5 else -1.0
	knockback_x = away * KNOCKBACK_SPEED

	Fx.popup_text(get_parent() as Node2D, global_position + Vector2(0, -70), "-5%", HIT_COLOR)

	# Hit always wins over the pickup squash
	if pickup_tween:
		pickup_tween.kill()
	if hit_tween:
		hit_tween.kill()

	hit_tween = create_tween()
	hit_tween.set_parallel(true)
	# Impact: tilt + shove away from the elf, squash
	hit_tween.tween_property(sprite, "rotation", deg_to_rad(20.0) * away, 0.06)
	hit_tween.tween_property(sprite, "position:x", 20.0 * away, 0.06)
	hit_tween.tween_property(sprite, "scale", Vector2(0.8, 1.2), 0.06)
	# Recover with a wobble while flickering red
	hit_tween.chain().tween_property(sprite, "rotation", 0.0, 0.5).set_trans(Tween.TRANS_ELASTIC).set_ease(
		Tween.EASE_OUT
	)
	hit_tween.tween_property(sprite, "position:x", 0.0, 0.5).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	hit_tween.tween_property(sprite, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	hit_tween.tween_method(_hit_flicker, 0.0, 1.0, 0.4)
	hit_tween.chain().tween_property(sprite, "modulate", Color.WHITE, 0.0)

	if shake_tween:
		shake_tween.kill()
	shake_tween = create_tween()
	shake_tween.tween_method(_shake_camera, 1.0, 0.0, 0.3)
	shake_tween.tween_property(camera, "offset", Vector2.ZERO, 0.0)


func _hit_flicker(t: float) -> void:
	sprite.modulate = HIT_COLOR if int(t * 6.0) % 2 == 0 else Color.WHITE


func _shake_camera(strength: float) -> void:
	camera.offset = Vector2(randf_range(-1.0, 1.0) * 0.5, randf_range(-1.0, 1.0)) * SHAKE_STRENGTH * strength


func _smoke_boost(amount_ratio: float, lifetime: float, fall_speed_multiplier: float) -> void:
	smoke.amount_ratio = amount_ratio
	smoke.lifetime = lifetime
	fall_speed = min(MAX_FALL_SPEED, fall_speed * fall_speed_multiplier)
	boost_timer.start(4.0)


func _on_boost_timeout() -> void:
	smoke.amount_ratio = default_smoke_amount
	smoke.lifetime = default_smoke_lifetime

	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "fall_speed", default_fall_speed, 1.0)


func _on_tier_unlocked(tier_number: int, _tier_name: String) -> void:
	if tier_number == 1:  # Amazon Fulfillment Deal
		gift_interval = 0.9
		gift_ammount = 10
	elif tier_number == 2:  # Overtime Scab Workers
		gift_interval = 0.8
		gift_ammount = 20
	elif tier_number == 3:  # Oil Baron's Pact
		gift_interval = 0.6
		gift_ammount = 30
	elif tier_number == 4:  # Plastic Wonderland
		gift_interval = 0.4
		gift_ammount = 40
	elif tier_number == 5:  # Coal-Powered Christmas
		gift_interval = 0.05
		gift_ammount = 5
	elif tier_number == 6:  # Fast Fashion Frenzy
		gift_interval = 0.05
		gift_ammount = 10
	elif tier_number == 7:  # Military Logistics Contract
		gift_interval = 0.05
		gift_ammount = 25
	elif tier_number == 8:  # Crypto Christmas
		gift_interval = 0.05
		gift_ammount = 45
	elif tier_number == 9:  # SpaceX Sleigh Launch
		gift_interval = 0.025
		gift_ammount = 55

	gift_timer.start(gift_interval)
