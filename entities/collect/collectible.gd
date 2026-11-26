class_name Collectible extends Area2D
## Base class for fuel, oil and bribes. On pickup the item leaves the world and
## arcs up through the HUD into the multiplier line, which punches when it lands.

const POP_TIME: float = 0.08
const FLY_TIME: float = 0.5
## Max sideways bow of the flight arc, and bow relative to flight length
const ARC_BOW: float = 220.0
const ARC_BOW_RATIO: float = 0.6

## Colour of the item's effects; set by subclasses.
var burst_color: Color = Color.WHITE

var _game: Game = null
var _flyer: Sprite2D = null
var _arc_start: Vector2 = Vector2.ZERO
var _arc_control: Vector2 = Vector2.ZERO
var _arc_end: Vector2 = Vector2.ZERO

@onready var visibility_notifier: VisibleOnScreenNotifier2D = $VisibleOnScreenNotifier2D
@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var audio_stream_player: AudioStreamPlayer = $AudioStreamPlayer


func _ready() -> void:
	visibility_notifier.screen_exited.connect(_on_screen_exited)


func release(_ammount: int) -> void:
	# Called from inside area_entered: physics state must change deferred.
	set_deferred("monitorable", false)
	set_deferred("monitoring", false)
	audio_stream_player.play()

	_game = get_tree().get_first_node_in_group(Game.GROUP) as Game
	if _game == null:
		_fade_in_place()
		return

	# Stay alive (for the sound + tween) until the flight lands
	visibility_notifier.screen_exited.disconnect(_on_screen_exited)
	_fly_to_multiplier()


func _fly_to_multiplier() -> void:
	# Swap the world sprite for a HUD copy at the same spot on screen
	_flyer = Sprite2D.new()
	_flyer.texture = sprite_2d.texture
	_game.hud.add_child(_flyer)
	_flyer.position = get_global_transform_with_canvas().origin
	sprite_2d.visible = false

	# Quadratic bezier that bows out to the side the item came from
	_arc_start = _flyer.position
	_arc_end = _game.get_multiplier_anchor()
	var side: float = signf(_arc_start.x - _arc_end.x)
	if side == 0.0:
		side = 1.0 if randf() > 0.5 else -1.0
	var bow: float = minf(ARC_BOW, _arc_start.distance_to(_arc_end) * ARC_BOW_RATIO)
	_arc_control = _arc_start.lerp(_arc_end, 0.5) + Vector2(side * bow, 0.0)

	var tween: Tween = create_tween()
	# Pop off Santa
	tween.tween_property(_flyer, "scale", Vector2.ONE * 1.35, POP_TIME).set_trans(Tween.TRANS_SINE).set_ease(
		Tween.EASE_OUT
	)
	# Arc up, accelerating into the multiplier, spinning and shrinking
	tween.tween_method(_move_along_arc, 0.0, 1.0, FLY_TIME).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(_flyer, "scale", Vector2.ONE * 0.4, FLY_TIME).set_trans(Tween.TRANS_QUAD).set_ease(
		Tween.EASE_IN
	)
	tween.parallel().tween_property(_flyer, "rotation", TAU * side, FLY_TIME).set_trans(Tween.TRANS_QUAD).set_ease(
		Tween.EASE_IN
	)
	tween.tween_callback(_on_landed)


func _move_along_arc(t: float) -> void:
	_flyer.position = _arc_start.lerp(_arc_control, t).lerp(_arc_control.lerp(_arc_end, t), t)


func _on_landed() -> void:
	_game.on_multiplier_hit(burst_color)
	_flyer.queue_free()
	queue_free()


func _fade_in_place() -> void:
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(sprite_2d, "scale", Vector2(2, 2), 0.5)
	tween.tween_property(sprite_2d, "modulate:a", 0.0, 0.5)
	tween.finished.connect(queue_free)


func _on_screen_exited() -> void:
	queue_free()
