
extends Area3D
class_name GremlinReturnArea

@export var normal_gremlin_scene: PackedScene

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
	# Only handle Running Gremlins.
	if not body is RunningGremlin:
		return

	var gremlin := body as RunningGremlin

	# Only return Gremlins that have been released.
	if gremlin.is_being_dragged:
		return

	if normal_gremlin_scene == null:
		push_warning("GremlinReturnArea: Assign the Normal Gremlin scene.")
		return

	var normal_gremlin := normal_gremlin_scene.instantiate() as NormalGremlin

	if normal_gremlin == null:
		push_error("Normal Gremlin scene root must use NormalGremlin.")
		return

	# Spawn the Normal Gremlin at the Running Gremlin's position.
	get_tree().current_scene.add_child(normal_gremlin)
	normal_gremlin.global_transform = gremlin.global_transform

	# Remove the Running Gremlin.
	gremlin.queue_free()


func return_running_gremlin(gremlin: RunningGremlin) -> void:
	if not is_instance_valid(gremlin):
		return

	if normal_gremlin_scene == null:
		push_warning("Assign the Normal Gremlin scene.")
		return

	var normal_gremlin := normal_gremlin_scene.instantiate() as NormalGremlin

	if normal_gremlin == null:
		push_error("Normal Gremlin scene root must use NormalGremlin.")
		return

	get_tree().current_scene.add_child(normal_gremlin)
	normal_gremlin.global_transform = gremlin.global_transform
	gremlin.queue_free()
