
extends Node3D

@export var camera: Camera3D
@export var return_area: GremlinReturnArea
@export var game_manager: GameManager

@export_group("Dragging")
@export var lift_height: float = 2
@export var ray_length: float = 200.0

var held_gremlin: RunningGremlin = null
var ground_height: float = 0.0


func _physics_process(_delta: float) -> void:
		
	if not is_instance_valid(held_gremlin):
		held_gremlin = null

		if Input.is_action_just_pressed("mouse_click"):
			try_pick_up()

		return

	if Input.is_action_pressed("mouse_click"):
		move_held_gremlin()

	elif Input.is_action_just_released("mouse_click"):
		try_drop_gremlin()


func get_mouse_ground_position() -> Variant:
	if camera == null:
		return null

	var mouse_position := get_viewport().get_mouse_position()
	var ray_origin := camera.project_ray_origin(mouse_position)
	var ray_direction := camera.project_ray_normal(mouse_position)

	# Always intersect the same ground-height plane.
	var ground_plane := Plane(
		Vector3.UP,
		ground_height
	)

	return ground_plane.intersects_ray(ray_origin, ray_direction)

func _input(event):
	if event.is_action_pressed("add_money"):
		game_manager.add_money(100)
		
		

func try_pick_up() -> void:
	if camera == null:
		return

	var mouse_position := get_viewport().get_mouse_position()
	var ray_origin := camera.project_ray_origin(mouse_position)
	var ray_direction := camera.project_ray_normal(mouse_position)

	var query := PhysicsRayQueryParameters3D.create(
		ray_origin,
		ray_origin + ray_direction * ray_length
	)
	query.collide_with_areas = false
	query.collide_with_bodies = true

	var result := get_world_3d().direct_space_state.intersect_ray(query)

	if result.is_empty():
		return

	var collider = result.get("collider")

	if not collider is RunningGremlin:
		return

	held_gremlin = collider as RunningGremlin

	# Remember the original ground height once.
	ground_height = held_gremlin.global_position.y

	held_gremlin.is_being_dragged = true
	held_gremlin.velocity = Vector3.ZERO

	move_held_gremlin()


func move_held_gremlin() -> void:
	if not is_instance_valid(held_gremlin):
		return

	var ground_position = get_mouse_ground_position()
	Input.set_default_cursor_shape(Input.CURSOR_DRAG)

	if ground_position == null:
		return

	# Move horizontally with the mouse, but keep a fixed lift.
	held_gremlin.global_position = (
		ground_position + Vector3.UP * lift_height
	)


func try_drop_gremlin() -> void:
	if not is_instance_valid(held_gremlin):
		held_gremlin = null
		return

	# Update the position one last time before releasing.
	move_held_gremlin()

	var gremlin := held_gremlin
	held_gremlin = null

	# Put it back at ground level.
	gremlin.global_position.y = ground_height
	gremlin.is_being_dragged = false
	gremlin.velocity = Vector3.ZERO
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)

	# Check the return area after the physics system updates overlaps.
	await get_tree().physics_frame

	if not is_instance_valid(gremlin):
		return

	if return_area != null:
		if return_area.get_overlapping_bodies().has(gremlin):
			return_area.return_running_gremlin(gremlin)
