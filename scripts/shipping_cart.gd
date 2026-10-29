extends Node3D
class_name ShippingCart

enum CartState {
	WAITING,
	DRIVING_OUT,
	RETURNING
}

@export_group("Cart Movement")
@export var wait_target: Marker3D
@export var destination: Marker3D
@export var drive_speed: float = 4.0

@export_group("Loading")
@export var minimum_wait_time: float = 5.0
var departure_timer: float = 0.0
@export var container_area: Area3D
@export var loaded_box_visuals: Array[Node3D] = []
@export var max_loaded_boxes: int = 4
@export var load_interval: float = 1.0

@onready var game_manager: GameManager = %GameManager
@onready var process_timer: ProcessTimer = %ProcessTimer

var loaded_count: int = 0
var is_loading: bool = false
var cart_state: CartState = CartState.WAITING


func _ready() -> void:
	if wait_target == null or destination == null:
		push_error("ShippingCart: Assign wait_target and destination.")
		set_process(false)
		return

	if container_area == null:
		push_error("ShippingCart: Assign the storage Container Area3D.")
		set_process(false)
		return

	# Start at the loading position.
	global_position = wait_target.global_position

	# Start with all cart box visuals hidden.
	for visual in loaded_box_visuals:
		if is_instance_valid(visual):
			visual.visible = false

	max_loaded_boxes = mini(max_loaded_boxes, loaded_box_visuals.size())

	if max_loaded_boxes <= 0:
		push_error("ShippingCart: Add at least one box visual slot.")
		set_process(false)
		return


func _process(delta: float) -> void:
	match cart_state:
		CartState.WAITING:
			if not is_loading and loaded_count < max_loaded_boxes:
				_load_boxes()

			# Only count down when the cart has at least one box.
			if loaded_count > 0:
				departure_timer += delta

				# Depart immediately if full, or when the timer expires.
				if loaded_count >= max_loaded_boxes \
				or departure_timer >= minimum_wait_time:
					is_loading = false
					cart_state = CartState.DRIVING_OUT
			else:
				# No boxes means no timer progress.
				departure_timer = 0.0

		CartState.DRIVING_OUT:
			_move_cart_toward(destination.global_position.x, delta)

			if is_equal_approx(global_position.x, destination.global_position.x):
				_unload_cart()
				departure_timer = 0.0
				cart_state = CartState.RETURNING

		CartState.RETURNING:
			_move_cart_toward(wait_target.global_position.x, delta)

			if is_equal_approx(global_position.x, wait_target.global_position.x):
				cart_state = CartState.WAITING


func _move_cart_toward(target_x: float, delta: float) -> void:
	global_position.x = move_toward(
		global_position.x,
		target_x,
		drive_speed * delta
	)



func _load_boxes() -> void:
	if is_loading or cart_state != CartState.WAITING:
		return

	is_loading = true

	while loaded_count < max_loaded_boxes:
		if cart_state != CartState.WAITING:
			break

		# Stop loading if the cart is full or its wait time has expired.
		if loaded_count >= max_loaded_boxes \
		or (loaded_count > 0 and departure_timer >= minimum_wait_time):
			break

		var box := _find_box_in_container()

		if box == null:
			break

		box.remove_from_group("physics_gremlin_box")
		box.queue_free()

		loaded_box_visuals[loaded_count].visible = true
		loaded_count += 1

		# A full cart departs immediately.
		if loaded_count >= max_loaded_boxes:
			break

		await get_tree().create_timer(load_interval).timeout

	is_loading = false



func _find_box_in_container() -> RigidBody3D:
	if container_area == null:
		return null

	for body in container_area.get_overlapping_bodies():
		if not is_instance_valid(body):
			continue

		if body.is_queued_for_deletion():
			continue

		if body is RigidBody3D and body.is_in_group("physics_gremlin_box"):
			return body as RigidBody3D

	return null



func _unload_cart() -> void:
	var boxes_to_sell := loaded_count

	if boxes_to_sell > 0:
		game_manager.sell_boxes(boxes_to_sell)
		process_timer.sell_oldest_gremlins(boxes_to_sell)

	for visual in loaded_box_visuals:
		if is_instance_valid(visual):
			visual.visible = false

	loaded_count = 0

func apply_speed_upgrade(amount: float = 1.0) -> void:
	drive_speed += amount
	load_interval -= 0.1
