
extends Node
class_name ConveyorOne

signal GremlinPacked

@export_group("Path")
@export var conveyor_path: Path3D

@export_group("Gremlin Scenes")
@export var stunned_gremlin_scene: PackedScene
@export var running_gremlin_scene: PackedScene

@export_group("Pipe")
@export var pipe_escape_spawn: Node3D
@export var pipe_broken: bool = false
@export var pipe_escape_ratio: float = 0.44

@export_range(0.0, 1.0, 0.05) var pipe_break_chance: float = 0.1
@export var pipe_controller: PipeController

@export_group("Conveyor Settings")
@export var conveyor_speed: float = 2.0

@onready var mesh_pipe_broken: MeshInstance3D = $"../Pipe/M_FactoryPipe/Pipe_Broken"
@onready var mesh_pipe_intact: MeshInstance3D = $"../Pipe/M_FactoryPipe/Pipe_Intact"



func _ready() -> void:
	if conveyor_path == null:
		push_error("Conveyor 1: Assign the Path3D!")
		return

	if conveyor_path.curve == null:
		push_error("Conveyor 1: Path3D needs a Curve3D!")
		return
	
	mesh_pipe_broken.visible = false
	FactorySignals.gremlin_in_hopper.connect(start_processing)


# Connect the hopper's GremlinInHopper signal to this function.
func start_processing() -> void:
	if conveyor_path == null:
		push_error("Conveyor 1: Assign the Path3D!")
		return

	if stunned_gremlin_scene == null:
		push_error("Conveyor 1: Assign the Stunned Gremlin scene!")
		return

	var follower := stunned_gremlin_scene.instantiate() as PathFollow3D

	if follower == null:
		push_error("Stunned Gremlin scene root must be PathFollow3D.")
		return

	# Configure looping before adding it to the path.
	follower.loop = false

	# Add it to the Path3D FIRST.
	conveyor_path.add_child(follower)


func _process(delta: float) -> void:
	if conveyor_path == null:
		return

	var path_length := conveyor_path.curve.get_baked_length()

	if path_length <= 0.0:
		return

	# Iterate backwards because followers may be removed during this loop.
	for i in range(conveyor_path.get_child_count() - 1, -1, -1):
		var follower := conveyor_path.get_child(i) as PathFollow3D

		if follower == null:
			continue

		# Move the follower along the path.
		follower.progress += conveyor_speed * delta

		# If the pipe is broken, Gremlins reaching halfway escape.
		if pipe_broken and follower.progress_ratio >= pipe_escape_ratio:
			spawn_running_gremlin()
			follower.queue_free()
			continue

		# A Gremlin that reaches the end successfully is packed.
		if follower.progress_ratio >= 1:
			follower.queue_free()

			# Each Gremlin that passes through gets one breakdown roll.
			if not pipe_broken and randf() < pipe_break_chance:
				if pipe_controller != null:
					pipe_controller.break_pipe()
				else:
					break_pipe()

			FactorySignals.conveyor_1_complete.emit()


func spawn_running_gremlin() -> void:
	if running_gremlin_scene == null:
		push_warning("Conveyor 1: Running Gremlin scene is not assigned.")
		return

	if pipe_escape_spawn == null:
		push_warning("Conveyor 1: Pipe escape spawn point is not assigned.")
		return

	var gremlin := running_gremlin_scene.instantiate() as Node3D

	if gremlin == null:
		push_error("Running Gremlin scene root must inherit Node3D.")
		return

	get_tree().current_scene.add_child(gremlin)
	gremlin.global_transform = pipe_escape_spawn.global_transform
	
func break_pipe() -> void:
	mesh_pipe_intact.visible = false
	mesh_pipe_broken.visible = true
	pipe_broken = true
	
func fix_pipe() -> void:
	mesh_pipe_intact.visible = true
	mesh_pipe_broken.visible = false
	pipe_broken = false

func apply_conveyor_1_upgrade(amount: float = 1.0) -> void:
	conveyor_speed += amount
