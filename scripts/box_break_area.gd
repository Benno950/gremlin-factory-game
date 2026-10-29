
extends Area3D
class_name GremlinBoxFloorDetector

@export var running_gremlin_scene: PackedScene



func _on_body_entered(body: Node3D) -> void:

	if body.is_in_group("physics_gremlin_box"):
		
		# Spawn the Running Gremlin where the box landed.
		var gremlin := running_gremlin_scene.instantiate() as RunningGremlin
		get_tree().current_scene.add_child(gremlin)

		var spawn_position := body.global_position
		spawn_position.y += 0.2
		gremlin.global_position = spawn_position

		# Remove the escaped box.
		body.queue_free()
