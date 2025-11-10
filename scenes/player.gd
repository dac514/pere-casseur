class_name Player extends CharacterBody2D

const GIFT_SCENE = preload("res://entities/gift/gift.tscn")

const FRICTION: float = 0.925
const MAX_FALL_SPEED: float = 420.0
const HORIZONTAL_ACCEL: float = 1800.0

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

@onready var hit_zone: Area2D = $Area2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var boost_timer: Timer = $BoostTimer
@onready var gift_timer: Timer = $GiftTimer
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var smoke: GPUParticles2D = $Smoke


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
	# Check what type of collectible was collected
	var scene_path: String = area.scene_file_path
	if scene_path == "res://entities/collect/fuel.tscn":
		GameManager.collect_fuel(area)
		_smoke_boost(1.0, 0.7, 1.7)
	elif scene_path == "res://entities/collect/oil.tscn":
		GameManager.collect_oil(area)
		_smoke_boost(1.0, 0.9, 2.0)
	elif scene_path == "res://entities/collect/bribe.tscn":
		GameManager.collect_bribe(area)
		_smoke_boost(default_smoke_amount, default_smoke_lifetime, 1.5)


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
