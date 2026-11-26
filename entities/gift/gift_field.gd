class_name GiftField extends Node2D
## Moves and draws every gift Santa throws in a single MultiMesh: no per-gift nodes or
## physics bodies. Late tiers keep ~1,700 gifts alive at once, which as RigidBody2D
## scenes meant ~9k nodes and thousands of instantiations per second on phones.
##
## Motion matches the RigidBody2D gift scene it replaces (gravity scale 2.5, project
## default gravity and linear damp, integrated each physics tick), but is computed
## explicitly so it behaves the same on every renderer, platform and frame rate.
## Gifts are dropped when they leave the screen. Draw order is preserved (newest on
## top) by compacting in place rather than swap-removing.
##
## Works in the world (Santa's gifts) or inside a CanvasLayer (power-up gifts):
## positions and culling use the canvas the field is drawn on.

const GIFT_TEXTURE: Texture2D = preload("res://entities/gift/gift1.png")
const GRAVITY_SCALE: float = 2.5
const CULL_MARGIN: float = 17.0  # half the gift size, as the old notifier rect
const INITIAL_CAPACITY: int = 4096
const FLOATS_PER_INSTANCE: int = 8  # Transform2D layout in a 2D MultiMesh buffer

## Number of live gifts.
var count: int = 0

var _capacity: int = 0
## Gifts at or after this index were spawned since the last physics tick. Like a freshly
## added RigidBody2D, they hold still for that first tick.
var _fresh_from: int = 0
var _dirty: bool = false
var _positions: PackedVector2Array = PackedVector2Array()
var _velocities: PackedVector2Array = PackedVector2Array()
var _buffer: PackedFloat32Array = PackedFloat32Array()
var _multimesh: MultiMesh = null
var _gravity: Vector2 = Vector2.ZERO
var _linear_damp: float = 0.0


func _init(initial_capacity: int = INITIAL_CAPACITY) -> void:
	name = "GiftField"
	# Positions are in the canvas's space (world, or screen in a CanvasLayer);
	# ignore any parent transform
	top_level = true
	z_index = -2

	var gravity_dir: Vector2 = ProjectSettings.get_setting("physics/2d/default_gravity_vector", Vector2.DOWN)
	var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity", 980.0)
	_gravity = gravity_dir * gravity * GRAVITY_SCALE
	_linear_damp = ProjectSettings.get_setting("physics/2d/default_linear_damp", 0.1)

	_multimesh = MultiMesh.new()
	_multimesh.transform_format = MultiMesh.TRANSFORM_2D
	_multimesh.mesh = _make_quad(GIFT_TEXTURE.get_size())
	_allocate(maxi(initial_capacity, 1))

	var drawer := MultiMeshInstance2D.new()
	drawer.multimesh = _multimesh
	drawer.texture = GIFT_TEXTURE
	add_child(drawer)


## Throw a gift from a world position with an initial velocity (px/s).
func spawn(pos: Vector2, velocity: Vector2) -> void:
	if count == _capacity:
		_allocate(_capacity * 2)
	_positions[count] = pos
	_velocities[count] = velocity
	var base: int = count * FLOATS_PER_INSTANCE
	_buffer[base + 3] = pos.x
	_buffer[base + 7] = pos.y
	count += 1
	_dirty = true


func _physics_process(delta: float) -> void:
	if count == 0:
		return

	# Same per-tick integration as a RigidBody2D: damping, then gravity, then move
	var damp_factor: float = maxf(1.0 - delta * _linear_damp, 0.0)
	var gravity_step: Vector2 = _gravity * delta
	var view: Rect2 = _visible_world_rect().grow(CULL_MARGIN)

	var write: int = 0
	for read in count:
		var pos: Vector2 = _positions[read]
		var velocity: Vector2 = _velocities[read]
		if read < _fresh_from:
			velocity = velocity * damp_factor + gravity_step
			pos += velocity * delta
		if not view.has_point(pos):
			continue
		_velocities[write] = velocity
		_positions[write] = pos
		var base: int = write * FLOATS_PER_INSTANCE
		_buffer[base + 3] = pos.x
		_buffer[base + 7] = pos.y
		write += 1
	count = write
	_fresh_from = count
	_dirty = true


## Upload once per rendered frame (also shows gifts thrown this frame right away).
func _process(_delta: float) -> void:
	if not _dirty:
		return
	_dirty = false
	_multimesh.buffer = _buffer
	_multimesh.visible_instance_count = count
	# Live gifts are all on screen, so the screen rect bounds them (skips an AABB recompute)
	var view: Rect2 = _visible_world_rect().grow(CULL_MARGIN)
	_multimesh.custom_aabb = AABB(Vector3(view.position.x, view.position.y, -1.0), Vector3(view.size.x, view.size.y, 2.0))


## Visible area in this field's canvas: the camera view in the world, the screen in a CanvasLayer.
func _visible_world_rect() -> Rect2:
	return get_canvas_transform().affine_inverse() * Rect2(Vector2.ZERO, get_viewport_rect().size)


func _allocate(new_capacity: int) -> void:
	_positions.resize(new_capacity)
	_velocities.resize(new_capacity)

	# Changing instance_count resets the GPU buffer, so rebuild it with identity bases
	_buffer.resize(new_capacity * FLOATS_PER_INSTANCE)
	for i in range(_capacity, new_capacity):
		var base: int = i * FLOATS_PER_INSTANCE
		_buffer[base] = 1.0  # x.x
		_buffer[base + 5] = 1.0  # y.y
	_capacity = new_capacity
	_multimesh.instance_count = new_capacity
	_multimesh.buffer = _buffer
	_multimesh.visible_instance_count = count


## Centered textured quad, UVs oriented for 2D (y down).
func _make_quad(size: Vector2) -> ArrayMesh:
	var half: Vector2 = size / 2.0
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = PackedVector2Array(
		[Vector2(-half.x, -half.y), Vector2(half.x, -half.y), Vector2(half.x, half.y), Vector2(-half.x, half.y)]
	)
	arrays[Mesh.ARRAY_TEX_UV] = PackedVector2Array([Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)])
	arrays[Mesh.ARRAY_INDEX] = PackedInt32Array([0, 1, 2, 0, 2, 3])
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh
