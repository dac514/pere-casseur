class_name PowerUpAnimator extends Node

# Preload all power-up texture scenes
const POWER_SCENES: Array[PackedScene] = [
	preload("res://entities/power/power1-texture.tscn"),
	preload("res://entities/power/power2-texture.tscn"),
	preload("res://entities/power/power3-texture.tscn"),
	preload("res://entities/power/power4-texture.tscn"),
	preload("res://entities/power/power5-texture.tscn"),
	preload("res://entities/power/power6-texture.tscn"),
	preload("res://entities/power/power7-texture.tscn"),
	preload("res://entities/power/power8-texture.tscn"),
	preload("res://entities/power/power9-texture.tscn"),
	preload("res://entities/power/power10-texture.tscn"),
]

# Van driving towards the right texture
const POWER2B := preload("res://entities/power/power2b.png")

# Preload particle scene for better performance
const PARTICLE_TRAIL: PackedScene = preload("res://entities/power/particle_trail.tscn")

const GIFT_SCENE = preload("res://entities/gift/gift.tscn")

# Pool of unlocked power-ups (indices into POWER_SCENES)
var unlocked_powers: Array[int] = []

# Timer for spawning animations
var spawn_timer: Timer

# Track newly unlocked power-up to showcase it
var newly_unlocked_power: int = -1
var showcase_count: int = 0

# Reference to parent container where animations will spawn
@onready var animation_container: CanvasLayer = get_parent()
@onready var audio_stream_player: AudioStreamPlayer = $AudioStreamPlayer


func _ready() -> void:
	# Connect to GameManager
	GameManager.tier_unlocked.connect(_on_tier_unlocked)

	# Create and configure timer
	spawn_timer = Timer.new()
	spawn_timer.one_shot = false
	spawn_timer.timeout.connect(_spawn_random_power)
	add_child(spawn_timer)


func _on_tier_unlocked(tier_number: int, _tier_name: String) -> void:
	audio_stream_player.play()
	if tier_number >= 1 and tier_number <= 10:
		var power_index := tier_number - 1

		if power_index not in unlocked_powers:
			unlocked_powers.append(power_index)

			# Set this as the newly unlocked power to showcase
			newly_unlocked_power = power_index
			showcase_count = 0

		# Start timer if this is the first unlock
		if unlocked_powers.size() == 1:
			_reset_spawn_timer()
			spawn_timer.start()


func _reset_spawn_timer() -> void:
	spawn_timer.wait_time = randf_range(3.0, 6.0)


func _spawn_random_power() -> void:
	if unlocked_powers.is_empty():
		return

	# Pick power: showcase newly unlocked for first 3 times, then random
	var selected_index: int
	if newly_unlocked_power >= 0 and showcase_count < 3:
		selected_index = newly_unlocked_power
		showcase_count += 1
		if showcase_count >= 3:
			newly_unlocked_power = -1  # Done showcasing
	else:
		selected_index = unlocked_powers[randi() % unlocked_powers.size()]

	var power_scene := POWER_SCENES[selected_index]
	var power_instance: TextureRect = power_scene.instantiate()

	# Store tier number for gift dropping
	var tier_number := selected_index + 1
	power_instance.set_meta("tier_number", tier_number)

	# Random direction (true = left to right, false = right to left)
	var left_to_right := randf() > 0.5

	# Random vertical position between 400 and 1100 to avoid VBoxContainer
	var random_y := randf_range(400.0, 1100.0)

	# Setup starting position and direction - go further offscreen to avoid edge glitch
	var viewport_width: float = get_viewport().get_visible_rect().size.x
	var start_x: float = -200.0 if left_to_right else viewport_width + 200.0
	var end_x: float = viewport_width + 200.0 if left_to_right else -200.0

	power_instance.position = Vector2(start_x, random_y)
	power_instance.z_index = -1

	# Flip for some textures
	if tier_number == 2 and not left_to_right:
		power_instance.texture = POWER2B
	elif tier_number == 7 and left_to_right:
		power_instance.flip_h = true

	# Add particle effects
	_add_particle_trail(power_instance, left_to_right)

	animation_container.add_child(power_instance)

	# Animate across screen
	_animate_power_across_screen(power_instance, end_x)

	# Reset timer for next spawn
	_reset_spawn_timer()


func _add_particle_trail(power: TextureRect, left_to_right: bool) -> void:
	# Instantiate pre-configured particle scene for better performance
	var particles: CPUParticles2D = PARTICLE_TRAIL.instantiate()

	# Position particles at the center of the TextureRect
	particles.position = power.size / 2.0

	# Direction - particles trail behind movement (opposite of travel direction)
	var direction := Vector2(-1, 0) if left_to_right else Vector2(1, 0)
	particles.direction = direction

	power.add_child(particles)
	particles.emitting = true


func _animate_power_across_screen(power: TextureRect, target_x: float) -> void:
	var duration := randf_range(4.0, 7.0)  # Random flight duration

	# Get tier number from metadata
	var tier_number: int = power.get_meta("tier_number", 1)

	var tween := create_tween()
	tween.set_parallel(true)

	# Move horizontally
	tween.tween_property(power, "position:x", target_x, duration)

	# Add slight vertical bobbing (sine wave pattern)
	var bob_offset := randf_range(-30, 30)
	tween.tween_property(power, "position:y", power.position.y + bob_offset, duration * 0.5)
	tween.chain().tween_property(power, "position:y", power.position.y, duration * 0.5)

	# Slight rotation wobble
	var rotation_amount := randf_range(-20, 20)
	tween.tween_property(power, "rotation_degrees", rotation_amount, duration * 0.5)
	tween.chain().tween_property(power, "rotation_degrees", -rotation_amount * 0.5, duration * 0.5)

	# Pulse scale effect
	tween.tween_property(power, "scale", Vector2(1.1, 1.1), duration * 0.25)
	tween.chain().tween_property(power, "scale", Vector2(0.9, 0.9), duration * 0.25)
	tween.chain().tween_property(power, "scale", Vector2(1.05, 1.05), duration * 0.25)
	tween.chain().tween_property(power, "scale", Vector2(1.0, 1.0), duration * 0.25)

	# Setup gift dropping based on power tier
	_setup_gift_dropping(power, tier_number)

	# Clean up after animation
	tween.finished.connect(func() -> void: power.queue_free())


func _setup_gift_dropping(power: TextureRect, tier_number: int) -> void:
	# Tier N drops N gifts per second
	if tier_number <= 0:
		return

	var gifts_per_second: int = tier_number
	var interval: float = 1.0 / gifts_per_second  # Time between each gift

	# Create a repeating timer that drops gifts until power is destroyed
	var drop_timer := Timer.new()
	drop_timer.wait_time = interval
	drop_timer.one_shot = false
	drop_timer.timeout.connect(func() -> void: _drop_gift(power))

	power.add_child(drop_timer)
	drop_timer.start()


func _drop_gift(power: TextureRect) -> void:
	var gift: Gift = GIFT_SCENE.instantiate()

	# Set initial velocity BEFORE adding to scene (Gift applies it in _ready())
	var horizontal_variation: float = randf_range(-100, 100)
	gift.initial_velocity = Vector2(horizontal_variation, 300)

	# Position particles at the center of the TextureRect
	gift.position = power.size / 2.0

	# Add gift to game scene
	power.add_child(gift)
