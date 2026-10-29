
extends Node3D
class_name NormalGremlinSpawner

signal gremlin_spawned(gremlin: NormalGremlin)

@export_group("Spawning")
@export var gremlin_scene: PackedScene
@export var spawn_interval_min: float = 5.0
@export var spawn_interval_max: float = 10.0
@onready var process_timer: ProcessTimer = %ProcessTimer



var spawning_enabled: bool = true
var spawn_points: Array[Node3D] = []


func _ready() -> void:
	randomize()

	# Collect Node3D children as spawn points.
	for child in get_children():
		if child is Node3D:
			spawn_points.append(child)

	if spawn_points.is_empty():
		push_error("Normal Gremlin Spawner: Add at least one Node3D spawn point.")
		return

	spawn_loop()
	
	await get_tree().create_timer(2.0).timeout

	if is_inside_tree():
		spawn_gremlin()


func spawn_loop() -> void:
	while is_inside_tree():
		var delay := randf_range(
			spawn_interval_min,
			spawn_interval_max
		)

		await get_tree().create_timer(delay).timeout

		if not is_inside_tree():
			return

		if spawning_enabled:
			spawn_gremlin()


func spawn_gremlin() -> void:
	if gremlin_scene == null:
		push_warning("Normal Gremlin Spawner: No Gremlin scene assigned.")
		return

	if spawn_points.is_empty():
		return

	var gremlin := gremlin_scene.instantiate() as NormalGremlin

	if gremlin == null:
		push_error("The assigned scene root must use NormalGremlin.")
		return

	var spawn_point: Node3D = spawn_points.pick_random()

	get_tree().current_scene.add_child(gremlin)
	gremlin.global_transform = spawn_point.global_transform

	gremlin_spawned.emit(gremlin)
	process_timer.register_gremlin_spawn()


func set_spawning_enabled(enabled: bool) -> void:
	spawning_enabled = enabled
	
func apply_spawn_upgrade(amount: float = 1.0) -> void:
	spawn_interval_max -= amount
