
extends Node3D
class_name GremlinHopper

@onready var detection_area: Area3D = $DetectionArea

var gremlins_being_processed: Array[int] = []


func _ready() -> void:
	detection_area.body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node3D) -> void:
	# Only accept Normal Gremlins.
	if not body.is_in_group("normal_gremlin"):
		return

	var instance_id := body.get_instance_id()

	# Prevent the same Gremlin from being counted twice.
	if gremlins_being_processed.has(instance_id):
		return

	gremlins_being_processed.append(instance_id)

	# Remove the Gremlin from the scene.
	body.queue_free()

	# Tell the factory that a Gremlin entered the hopper.
	FactorySignals.gremlin_in_hopper.emit()
