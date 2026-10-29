extends Node3D
class_name GrabbingCrane

signal gremlin_picked_up(gremlin: Node3D)
signal gremlin_released(gremlin: Node3D)

@export_group("Targets")
@export var wait_target: Marker3D
@export var drop_target: Marker3D
@export var pickup_target: Marker3D

@export_group("Movement")
@export var start_disabled = false
@export var horizontal_speed: float = 2
@export var vertical_speed: float = 1

@export_group("Pickup")
@export var look_up_delay: float = 0.3

var busy := false
var held_gremlin: CharacterBody3D = null
var home_height: float



func enable_crane() -> void:
	set_process(true)
	set_physics_process(true)
	visible = true
	
func disable_crane() -> void:
	set_process(false)
	set_physics_process(false)
	visible = false

func _ready() -> void:
	home_height = global_position.y
	global_position = wait_target.global_position
	
	if start_disabled:
		disable_crane()


func _process(_delta: float) -> void:
	if is_instance_valid(held_gremlin):
		held_gremlin.global_position = pickup_target.global_position


func _physics_process(_delta: float) -> void:
	if busy:
		return

	var target := find_normal_gremlin()

	if target != null:
		busy = true
		handle_gremlin(target)


func find_normal_gremlin() -> CharacterBody3D:
	var gremlins := get_tree().get_nodes_in_group("normal_gremlin")
	var nearest: CharacterBody3D = null
	var nearest_distance := INF

	for node in gremlins:
		if not is_instance_valid(node):
			continue
		if not node is CharacterBody3D:
			continue
		if node.get("is_targeted") == null:
			continue
		if node.is_targeted:
			continue

		var distance := global_position.distance_to(node.global_position)

		if distance < nearest_distance:
			nearest_distance = distance
			nearest = node

	return nearest


func handle_gremlin(gremlin: CharacterBody3D) -> void:
	if not is_instance_valid(gremlin):
		await return_to_wait()
		busy = false
		return

	var claw_offset := pickup_target.position

	# 1. Move above the Gremlin using X/Z only.
	var above_gremlin := Vector3(
		gremlin.global_position.x - claw_offset.x,
		home_height,
		gremlin.global_position.z - claw_offset.z
	)
	await move_horizontal(above_gremlin)

	if not is_instance_valid(gremlin):
		await return_to_wait()
		busy = false
		return

	# 2. Freeze the Gremlin before lowering the claw.
	# This stops it wandering away during the descent.
	gremlin.is_targeted = true
	gremlin.velocity = Vector3.ZERO

	# Optional pause for a future look-up animation.
	if look_up_delay > 0.0:
		await get_tree().create_timer(look_up_delay).timeout

	if not is_instance_valid(gremlin):
		await return_to_wait()
		busy = false
		return

	# 3. Lower the claw to the stationary Gremlin.
	var pickup_y := gremlin.global_position.y - claw_offset.y
	await move_vertical(pickup_y)

	if not is_instance_valid(gremlin):
		await return_to_wait()
		busy = false
		return

	# 4. Attach the Gremlin to the claw.
	gremlin.is_held = true
	held_gremlin = gremlin
	held_gremlin.global_position = pickup_target.global_position
	gremlin_picked_up.emit(gremlin)

	# 5. Lift the Gremlin back to the crane's home height.
	await move_vertical(home_height)

	# 6. Carry it horizontally above the hopper.
	# Keep the claw at home height during this movement.
	var drop_position := Vector3(
		drop_target.global_position.x - claw_offset.x,
		home_height,
		drop_target.global_position.z - claw_offset.z
	)
	await move_horizontal(drop_position)

	# 7. Release at the hovering height.
	# The Gremlin falls into the hopper under gravity.
	if is_instance_valid(held_gremlin):
		var released_gremlin := held_gremlin
		held_gremlin = null

		released_gremlin.is_targeted = false
		released_gremlin.is_held = false
		released_gremlin.velocity = Vector3.ZERO
		gremlin_released.emit(released_gremlin)

	# 8. Return horizontally to the waiting position.
	# No extra vertical lift after releasing the Gremlin.
	await move_horizontal(wait_target.global_position)

	busy = false


func move_horizontal(target: Vector3) -> void:
	var destination := Vector3(
		target.x,
		global_position.y,
		target.z
	)

	var distance := Vector2(
		destination.x - global_position.x,
		destination.z - global_position.z
	).length()

	if distance < 0.01:
		return

	var duration := distance / maxf(horizontal_speed, 0.01)
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "global_position", destination, duration)

	await tween.finished


func move_vertical(target_y: float) -> void:
	var destination := Vector3(
		global_position.x,
		target_y,
		global_position.z
	)

	var distance := absf(target_y - global_position.y)

	if distance < 0.01:
		return

	var duration := distance / maxf(vertical_speed, 0.01)
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "global_position", destination, duration)

	await tween.finished


func return_to_wait() -> void:
	await move_vertical(home_height)
	await move_horizontal(wait_target.global_position)
	
func apply_speed_upgrade(amount: float = 1.0) -> void:
	horizontal_speed += amount
	vertical_speed += amount
	print(horizontal_speed , vertical_speed)
