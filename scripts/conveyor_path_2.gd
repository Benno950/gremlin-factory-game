
extends Node
class_name ConveyorTwo

@export_group("Conveyor")
@export var conveyor_path: Path3D
@export var boxed_gremlin_scene: PackedScene
@export var conveyor_speed: float = 2.0


func _ready() -> void:
	if conveyor_path == null:
		push_error("ConveyorTwo: Assign the Conveyor Path3D.")
		return

	if boxed_gremlin_scene == null:
		push_error("ConveyorTwo: Assign the Boxed Gremlin scene.")
		return

	if conveyor_path.curve == null:
		push_error("ConveyorTwo: Path3D needs a Curve3D.")
		return

	# FactorySignals.packaging_complete.connect(start_processing)
	FactorySignals.conveyor_1_complete.connect(start_processing)


func start_processing() -> void:
	if conveyor_path == null or boxed_gremlin_scene == null:
		return

	var boxed_gremlin := boxed_gremlin_scene.instantiate() as PathFollow3D

	if boxed_gremlin == null:
		push_error("Boxed Gremlin scene root must be PathFollow3D.")
		return

	# Disable looping so the box stays at the end of the path.
	boxed_gremlin.loop = false

	# Add it to the path before setting its progress.
	conveyor_path.add_child(boxed_gremlin)
	boxed_gremlin.progress = 0.0


func _process(delta: float) -> void:
	if conveyor_path == null:
		return

	for child in conveyor_path.get_children():
		if not child is PathFollow3D:
			continue

		var follower := child as PathFollow3D
		follower.progress += conveyor_speed * delta

		if follower.progress_ratio >= 1.0:
			follower.queue_free()
			FactorySignals.conveyor_2_complete.emit()

func apply_conveyor_2_upgrade(amount: float = 1.0) -> void:
	conveyor_speed += amount
