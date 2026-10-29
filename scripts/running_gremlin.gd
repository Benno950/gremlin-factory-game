
extends CharacterBody3D
class_name RunningGremlin

@export_group("Movement")
@export var move_speed: float = 3.5
@export var gravity: float = 18.0
@export var direction_change_min: float = 0.8
@export var direction_change_max: float = 2.0

@onready var navigation_agent: NavigationAgent3D = $NavigationAgent3D
@onready var animation_player: AnimationPlayer = $M_Gremlin/AnimationPlayer


var is_being_dragged: bool = false
var wander_timer: float = 0.0


func _ready() -> void:
	choose_new_destination()


func _physics_process(delta: float) -> void:
	if is_being_dragged:
		velocity = Vector3.ZERO
		animation_player.play("Gremlin_InAir")
		return

	if not is_on_floor():
		velocity.y -= gravity * delta
		animation_player.play("Gremlin_InAir")
	else:
		animation_player.play("Gremlin_Run")
		velocity.y = 0.0

	wander_timer -= delta

	if wander_timer <= 0.0 or navigation_agent.is_navigation_finished():
		choose_new_destination()

	var next_position := navigation_agent.get_next_path_position()
	var direction := next_position - global_position
	direction.y = 0.0

	if direction.length_squared() > 0.01:
		direction = direction.normalized()
		velocity.x = direction.x * move_speed
		velocity.z = direction.z * move_speed

		var target_angle := atan2(direction.x, direction.z)
		rotation.y = lerp_angle(rotation.y, target_angle, 10.0 * delta)
	else:
		velocity.x = 0.0
		velocity.z = 0.0

	move_and_slide()


func choose_new_destination() -> void:
	wander_timer = randf_range(
		direction_change_min,
		direction_change_max
	)

	var navigation_map := navigation_agent.get_navigation_map()
	var center := global_position

	for attempt in range(10):
		var offset := Vector3(
			randf_range(-4.0, 4.0),
			0.0,
			randf_range(-4.0, 4.0)
		)

		var candidate := NavigationServer3D.map_get_closest_point(
			navigation_map,
			center + offset
		)

		if candidate.distance_to(center + offset) < 1.0:
			navigation_agent.target_position = candidate
			return
