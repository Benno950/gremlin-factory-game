
extends Marker3D
class_name BoxLauncher

@export_group("Box")
@export var physics_box_scene: PackedScene

@export_group("Launch Force")
@export var launch_impulse: float = 4.0
@export var upward_impulse: float = 2.0
@export var random_spread: float = 0.15

func _ready() -> void:
	#SignalBus.box_stored.connect(_on_box_stored)
	FactorySignals.conveyor_2_complete.connect(launch_box)


func _on_box_stored() -> void:
	launch_box()


func launch_box() -> void:
	if physics_box_scene == null:
		return

	var box := physics_box_scene.instantiate() as RigidBody3D

	if box == null:
		push_error("Physics Gremlin box scene root must be a RigidBody3D.")
		return

	# Add to the world before setting its global transform.
	get_tree().current_scene.add_child(box)
	box.global_transform = global_transform

	# Godot's local forward direction is -Z.
	var forward := -global_transform.basis.z.normalized()

	# Add a little randomness so launches aren't perfectly identical.
	forward += Vector3(
		randf_range(-random_spread, random_spread),
		randf_range(-random_spread, random_spread),
		randf_range(-random_spread, random_spread)
	)
	forward = forward.normalized()

	var impulse := forward * launch_impulse
	impulse.y += upward_impulse

	box.apply_central_impulse(impulse)
