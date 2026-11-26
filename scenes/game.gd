class_name Game extends Node2D

const GROUP: StringName = &"game"
const FUEL_SCENE: PackedScene = preload("res://entities/collect/fuel.tscn")
const OIL_SCENE: PackedScene = preload("res://entities/collect/oil.tscn")
const BRIBE_SCENE: PackedScene = preload("res://entities/collect/bribe.tscn")
const MOB_SCENE: PackedScene = preload("res://entities/mob/mob.tscn")
const SMOKESTACKS_SCENE: PackedScene = preload("res://scenes/smokestacks.tscn")
const MAIN_MENU_SCENE: PackedScene = preload("res://scenes/menu.tscn")
const INTRO_SCENE: PackedScene = preload("res://scenes/intro.tscn")

# House textures for tier progression
const HOUSE_TEXTURES: Array[Texture2D] = [
	preload("res://assets/house5.png"),
	preload("res://assets/house2.png"),
	preload("res://assets/house4.png"),
	preload("res://assets/house1.png"),
	preload("res://assets/house3.png")
]

var left_limit_x: float = 150.0
var right_limit_x: float = 570.0
var spawn_collectible_interval_min: float = 0.5
var spawn_collectible_interval_max: float = 1.0
var spawn_enemy_interval_min: float = 3.0
var spawn_enemy_interval_max: float = 5.0
var smokestacks: Sprite2D = null
var menu: Menu = null
var intro: Intro = null
var has_game_started: bool = false
var stats_tween: Tween = null
var pending_stats: String = ""

@onready var boundaries: StaticBody2D = $Boundaries
@onready var stats: Label = %Stats
@onready var stats_game_over: Label = %StatsGameOver
@onready var spawn_collectible_timer: Timer = $SpawnCollectible
@onready var spawn_enemy_timer: Timer = $SpawnEnemy
@onready var message_bar: MessageBar = %MessageBar
@onready var hud: CanvasLayer = $HUD
@onready var snow: Sprite2D = %Snow
@onready var player: Player = $Player
@onready var power_up_animator: PowerUpAnimator = $HUD/PowerUpAnimator
@onready var elapsed_time: Label = %ElapsedTime
@onready var music: AudioStreamPlayer = $Music
@onready var houses: Parallax2D = $Houses
@onready var flash_overlay: ColorRect = $HUD/FlashOverlay


func _ready() -> void:
	add_to_group(GROUP)

	# Show menu at startup for language selection
	toggle_menu()

	GameManager.stats_updated.connect(_on_stats_updated)
	GameManager.tier_unlocked.connect(_on_tier_unlocked)

	# Calculate spawn boundaries from LeftLimit and RightLimit positions
	var left_limit: CollisionShape2D = boundaries.get_node("LeftLimit")
	var right_limit: CollisionShape2D = boundaries.get_node("RightLimit")
	left_limit_x = boundaries.position.x + left_limit.position.x + 64
	right_limit_x = boundaries.position.x + right_limit.position.x - 64

	# Setup timers
	spawn_collectible_timer.timeout.connect(_on_spawn_collectible_timer_timeout)
	spawn_enemy_timer.timeout.connect(_on_spawn_enemy_timer_timeout)
	_reset_spawn_collectible_timer()
	_reset_spawn_enemy_timer()
	spawn_collectible_timer.start()
	spawn_enemy_timer.start()

	# Preload smokestacks and add to HUD so they stay fixed on screen
	smokestacks = SMOKESTACKS_SCENE.instantiate()
	hud.add_child(smokestacks)

	# Initialize house textures
	_update_house_textures(0)


func _on_spawn_collectible_timer_timeout() -> void:
	spawn_collectible()
	_reset_spawn_collectible_timer()


func _on_spawn_enemy_timer_timeout() -> void:
	spawn_enemy()
	_reset_spawn_enemy_timer()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		toggle_menu()


func spawn_collectible() -> void:
	# Randomly choose a collectible type
	var collectible_scenes: Array[PackedScene] = [FUEL_SCENE, OIL_SCENE, BRIBE_SCENE]
	var random_scene: PackedScene = collectible_scenes[randi() % collectible_scenes.size()]
	var collectible: Area2D = random_scene.instantiate()

	var random_x: float = randf_range(left_limit_x, right_limit_x)
	collectible.global_position = Vector2(random_x, player.global_position.y + 1000)
	collectible.z_index = -9

	add_child(collectible)


func spawn_enemy() -> void:
	var mob: CharacterBody2D = MOB_SCENE.instantiate()
	var random_x: float = randf_range(left_limit_x, right_limit_x)
	mob.global_position = Vector2(random_x, player.global_position.y - 1000)
	add_child(mob)


func toggle_menu() -> void:
	if menu:
		hud.remove_child(menu)
		menu.queue_free()
		menu = null
		get_tree().paused = false
		# After menu closes for the first time, show intro (language is now set)
		if not has_game_started:
			show_intro()
	else:
		menu = MAIN_MENU_SCENE.instantiate()
		hud.add_child(menu)
		get_tree().paused = true


func show_intro() -> void:
	# Load and display intro with comics
	intro = INTRO_SCENE.instantiate()
	hud.add_child(intro)
	intro.intro_completed.connect(_on_intro_completed)
	get_tree().paused = true


func _on_intro_completed() -> void:
	# Intro finished, start the game
	intro = null
	get_tree().paused = false
	music.play()
	message_bar.set_text(tr("TIER") + " 0: " + tr("Solopreneur"))
	has_game_started = true


func _reset_spawn_collectible_timer() -> void:
	spawn_collectible_timer.wait_time = randf_range(spawn_collectible_interval_min, spawn_collectible_interval_max)


func _reset_spawn_enemy_timer() -> void:
	spawn_enemy_timer.wait_time = randf_range(spawn_enemy_interval_min, spawn_enemy_interval_max)


func _on_stats_updated(info: String) -> void:
	if info.begins_with("+"):
		# Collectible: revealed when the item lands on the multiplier (see on_multiplier_hit)
		pending_stats = info
		return
	# Elf hit: show right away, and drop any older "+Item" text still in flight
	pending_stats = ""
	stats.text = info
	punch_stats(1.15, Player.HIT_COLOR)


## Screen-space point that collected items fly into.
func get_multiplier_anchor() -> Vector2:
	return stats.get_global_rect().get_center()


## Called by a Collectible when its flight reaches the multiplier.
func on_multiplier_hit(color: Color) -> void:
	if not pending_stats.is_empty():
		stats.text = pending_stats
		pending_stats = ""
	punch_stats(1.3, color.lightened(0.3))
	Fx.burst(hud, get_multiplier_anchor(), color, 14, 260.0)


func punch_stats(strength: float, color: Color) -> void:
	if stats_tween:
		stats_tween.kill()
	stats.pivot_offset = stats.size / 2.0
	stats.scale = Vector2.ONE * strength
	stats.modulate = color
	stats_tween = create_tween()
	stats_tween.set_parallel(true)
	stats_tween.tween_property(stats, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	stats_tween.tween_property(stats, "modulate", Color.WHITE, 0.3)


func _update_house_textures(tier: int) -> void:
	var num_houses: int = 12
	if tier > 0 and flash_overlay:
		var tween := create_tween()
		tween.set_ease(Tween.EASE_IN_OUT)
		tween.set_trans(Tween.TRANS_SINE)
		tween.tween_property(flash_overlay, "color", Color(1.0, 1.0, 1.0, 1.0), 0.15)
		tween.tween_callback(_apply_house_textures.bind(tier, num_houses))
		tween.tween_property(flash_overlay, "color", Color(1.0, 1.0, 1.0, 0.0), 0.3)
	else:
		_apply_house_textures(tier, num_houses)


func _apply_house_textures(tier: int, num_houses: int) -> void:
	var texture_index: int = tier % HOUSE_TEXTURES.size()
	var texture: Texture2D = HOUSE_TEXTURES[texture_index]

	for i in range(1, num_houses + 1):
		var house: Sprite2D = houses.get_node("House" + str(i))
		if house:
			house.texture = texture


func _on_tier_unlocked(tier_number: int, tier_name: String) -> void:
	# Announce the TIER using the mssage bar
	message_bar.set_text("%s %d: %s" % [tr("TIER"), tier_number, tr(tier_name)])

	# Update house textures based on tier
	_update_house_textures(tier_number)

	# Darken the snow background based on tier progression
	var progress := float(tier_number) / float(GameManager.NUM_TIERS - 1)
	var start_color := Color.WHITE
	var end_color := Color(0.2, 0.2, 0.2)  # Dark gray

	var tween := create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_SINE)
	tween.tween_property(snow, "modulate", start_color.lerp(end_color, progress), 2.0)

	# Transition rain_color from white (tier 0) to black (tier 10)
	if tier_number >= 5:
		var rain_start_color := Color.WHITE
		var rain_end_color := Color.BLACK
		var rain_color := rain_start_color.lerp(rain_end_color, progress)
		if flash_overlay and flash_overlay.material is ShaderMaterial:
			var shader_mat: ShaderMaterial = flash_overlay.material as ShaderMaterial
			shader_mat.set_shader_parameter("rain_color", rain_color)

	if tier_number == 1:
		music.pitch_scale = 1.01
	if tier_number == 2:
		music.pitch_scale = 1.02
	if tier_number == 3:
		music.pitch_scale = 1.03
	if tier_number == 4:
		music.pitch_scale = 1.04
	if tier_number == 5:
		music.pitch_scale = 1.05
		if smokestacks:
			# Trigger smokestacks animation at Tier 5 (Coal-Powered Christmas)
			(smokestacks as Smokestacks).animate_in()
	if tier_number == 6:
		music.pitch_scale = 1.06
	if tier_number == 7:
		music.pitch_scale = 1.07
	if tier_number == 8:
		music.pitch_scale = 1.08
	elif tier_number == 9:
		music.pitch_scale = 1.09
	elif tier_number == 9:
		music.pitch_scale = 1.1
	elif tier_number == 10:
		music.pitch_scale = 0.25
		game_over()


# Game over
func game_over() -> void:
	message_bar.set_text(tr("Christmas saved!"))

	GameManager.stats_updated.disconnect(_on_stats_updated)

	var game_stats: String = ""
	game_stats += tr("8.3B gifts in") + " " + elapsed_time.text + "\n"
	game_stats += tr("Fuel collected") + ": " + str(GameManager.fuel_collected) + "\n"
	game_stats += tr("Oil collected") + ": " + str(GameManager.oil_collected) + "\n"
	game_stats += tr("Bribes collected") + ": " + str(GameManager.bribes_collected) + "\n"
	game_stats += tr("Mob hits") + ": " + str(GameManager.mob_hits)

	stats.text = ""
	pending_stats = ""
	stats_game_over.text = game_stats
	stats_game_over.visible = true

	# Stop the game
	player.game_over()
	spawn_enemy_timer.stop()
	spawn_collectible_timer.stop()
	power_up_animator.spawn_timer.stop()
	elapsed_time.set_process(false)
