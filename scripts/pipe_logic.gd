extends Node3D
class_name PipeController

@export_group("References")
@export var conveyor_one: ConveyorOne
@export var camera: Camera3D
@export var fixing_detector: Area3D
@export var repair_bar: ProgressBar
@export var hammer_animation: AnimationPlayer

@export_group("Breakdown")
@export var can_break: bool = true

@export_group("Repair")
@export var min_repair_time: float = 2.5
@export var max_repair_time: float = 5.0
@export var progress_height: float = 2.5

@onready var pipe_break_sound: AudioStreamPlayer3D = $PipeBreakSound

var breakdown_timer: float = 0.0
var repair_progress: float = 0.0
var required_repair_time: float = 5.0
var is_repairing: bool = false


func _ready() -> void:
	randomize()

	if repair_bar:
		repair_bar.visible = false
		repair_bar.min_value = 0.0
		repair_bar.max_value = 1.0
		repair_bar.value = 0.0

	#if hammer_animation:
	#	hammer_animation.stop()

	if conveyor_one == null:
		push_warning("PipeController: Assign Conveyor One.")


func _process(delta: float) -> void:
	update_repair_bar_position()

	if conveyor_one == null:
		return

	if conveyor_one.pipe_broken:
		handle_repair(delta)

func break_pipe() -> void:
	if not can_break:
		return
	if conveyor_one == null or conveyor_one.pipe_broken:
		return

	
	conveyor_one.break_pipe()
	pipe_break_sound.play()

	required_repair_time = randf_range(
		min_repair_time,
		max_repair_time
	)

	reset_repair()



func handle_repair(delta: float) -> void:
	if Input.is_action_pressed("mouse_click") and is_mouse_over_pipe():
		if not is_repairing:
			is_repairing = true
			repair_progress = 0.0

			if repair_bar:
				repair_bar.visible = true

			# if hammer_animation:
			#	hammer_animation.play(hammer_animation_name)

		repair_progress += delta
		update_repair_bar()

		if repair_progress >= required_repair_time:
			repair_pipe()
	else:
		# Releasing the mouse or looking away resets progress.
		if is_repairing:
			reset_repair()


func is_mouse_over_pipe() -> bool:
	if camera == null or fixing_detector == null:
		return false

	var mouse_position := get_viewport().get_mouse_position()
	var ray_origin := camera.project_ray_origin(mouse_position)
	var ray_direction := camera.project_ray_normal(mouse_position)

	var query := PhysicsRayQueryParameters3D.create(
		ray_origin,
		ray_origin + ray_direction * 200.0
	)

	# Allow the ray to detect Area3D objects.
	query.collide_with_areas = true
	query.collide_with_bodies = false

	var result := get_world_3d().direct_space_state.intersect_ray(query)

	if result.is_empty():
		return false

	return result.get("collider") == fixing_detector


func update_repair_bar() -> void:
	if repair_bar == null:
		return

	repair_bar.value = clampf(
		repair_progress / required_repair_time,
		0.0,
		1.0
	)


func update_repair_bar_position() -> void:
	if repair_bar == null or camera == null:
		return

	var world_position := global_position + Vector3.UP * progress_height

	if camera.is_position_behind(world_position):
		repair_bar.visible = false
		return

	if is_repairing:
		repair_bar.visible = true
		repair_bar.position = (
			camera.unproject_position(world_position)
			- repair_bar.size * 0.5
		)


func reset_repair() -> void:
	is_repairing = false
	repair_progress = 0.0

	if repair_bar:
		repair_bar.value = 0.0
		repair_bar.visible = false

	#if hammer_animation:
	#	hammer_animation.stop()


func repair_pipe() -> void:
	conveyor_one.fix_pipe()
	breakdown_timer = 0.0
	reset_repair()

	print("Pipe repaired!")

func apply_quality_upgrade(amount) -> void:
	conveyor_one.pipe_break_chance -= amount
