
extends Node3D
class_name AssemblyLine

signal item_finished(item_type: String)

@export var product_scene: PackedScene
@export var move_speed: float = 2.0
@export_enum("stunned", "boxed") var item_type: String = "stunned"

@onready var path: Path3D = $Path3D

var busy := false

func start_processing() -> bool:
	if busy or product_scene == null:
		return false

	if path.curve == null:
		push_warning("AssemblyLine needs a Path3D curve.")
		return false

	var path_length := path.curve.get_baked_length()
	if path_length <= 0.0 or move_speed <= 0.0:
		push_warning("Path length and move speed must be greater than zero.")
		return false

	busy = true

	var follower := PathFollow3D.new()
	follower.loop = false
	follower.progress = 0.0
	path.add_child(follower)

	var product := product_scene.instantiate()
	follower.add_child(product)

	# Let Conveyor 1's pipe monitor check this item.
	follower.set_meta("item_type", item_type)

	var duration := path_length / move_speed
	var tween := create_tween()
	tween.tween_property(follower, "progress_ratio", 1.0, duration)
	await tween.finished

	if is_instance_valid(follower):
		follower.queue_free()

	busy = false
	item_finished.emit(item_type)
	return true
