class_name Fx extends RefCounted
## Small, cheap "juice" helpers shared by gameplay entities.
## Positions are global (in the parent's canvas); parents may be Node2D or CanvasLayer.

static var _shrink_curve: Curve = null


## One-shot particle burst. Frees itself when done.
## With follow = true the particles move with the parent (e.g. stick to Santa).
static func burst(
	parent: Node, pos: Vector2, color: Color, amount: int = 16, speed: float = 220.0, follow: bool = false
) -> void:
	var particles := CPUParticles2D.new()
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.amount = amount
	particles.lifetime = 0.45
	particles.local_coords = follow
	particles.direction = Vector2(0, -1)
	particles.spread = 180.0
	particles.gravity = Vector2(0, 250)
	particles.initial_velocity_min = speed * 0.5
	particles.initial_velocity_max = speed
	particles.damping_min = speed * 0.5
	particles.damping_max = speed
	particles.scale_amount_min = 4.0
	particles.scale_amount_max = 8.0
	particles.scale_amount_curve = shrink_curve()

	var gradient := Gradient.new()
	gradient.set_color(0, color.lightened(0.4))
	gradient.set_color(1, Color(color, 0.0))
	particles.color_ramp = gradient

	particles.z_index = 3
	particles.finished.connect(particles.queue_free)
	parent.add_child(particles)
	particles.global_position = pos
	particles.emitting = true


## Spurt of fire sparks shooting out along `direction` (e.g. out of an exhaust).
## The emitter follows the parent, but sparks stay in the world and get left behind.
static func fire_sparks(parent: Node, pos: Vector2, direction: Vector2, amount: int = 32, z: int = 1) -> void:
	var sparks := CPUParticles2D.new()
	sparks.one_shot = true
	sparks.explosiveness = 0.6
	sparks.amount = amount
	sparks.lifetime = 0.6
	sparks.local_coords = false
	sparks.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	sparks.emission_sphere_radius = 10.0
	sparks.direction = direction
	sparks.spread = 30.0
	sparks.gravity = Vector2(0, 150)
	sparks.initial_velocity_min = 180.0
	sparks.initial_velocity_max = 420.0
	sparks.damping_min = 250.0
	sparks.damping_max = 450.0
	sparks.scale_amount_min = 2.0
	sparks.scale_amount_max = 5.0
	sparks.scale_amount_curve = shrink_curve()

	# White-hot -> yellow -> orange -> dying red
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.2, 0.55, 1.0])
	gradient.colors = PackedColorArray(
		[Color(1.0, 1.0, 0.85), Color(1.0, 0.85, 0.2), Color(1.0, 0.45, 0.05), Color(0.7, 0.1, 0.0, 0.0)]
	)
	sparks.color_ramp = gradient

	sparks.z_index = z
	sparks.finished.connect(sparks.queue_free)
	parent.add_child(sparks)
	sparks.global_position = pos
	sparks.emitting = true


## Floating text that pops in, drifts up and fades out. Frees itself when done.
static func popup_text(parent: Node, pos: Vector2, text: String, color: Color) -> void:
	var settings := LabelSettings.new()
	settings.font_size = 36
	settings.font_color = color
	settings.outline_size = 8
	settings.outline_color = Color.BLACK

	var label := Label.new()
	label.text = text
	label.label_settings = settings
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.size = Vector2(200, 60)
	label.pivot_offset = label.size / 2.0
	label.z_index = 4
	label.scale = Vector2.ZERO
	parent.add_child(label)
	label.global_position = pos - label.size / 2.0

	var tween := label.create_tween()
	tween.tween_property(label, "scale", Vector2.ONE * 1.2, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "scale", Vector2.ONE, 0.08)
	tween.tween_property(label, "position:y", label.position.y - 60.0, 0.6).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.35).set_delay(0.25)
	tween.finished.connect(label.queue_free)


## Shared 1 -> 0 curve for particles that shrink away.
static func shrink_curve() -> Curve:
	if _shrink_curve == null:
		_shrink_curve = Curve.new()
		_shrink_curve.add_point(Vector2(0.0, 1.0))
		_shrink_curve.add_point(Vector2(1.0, 0.0))
	return _shrink_curve
