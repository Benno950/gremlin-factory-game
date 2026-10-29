extends Control

@export var camera: Camera3D
@export var move_distance := 11.0
@export var move_duration := 0.8

@onready var left_arrow: TextureButton = $MarginContainer/GoLeftButton
@onready var right_arrow: TextureButton = $MarginContainer/GoRightButton

var is_moving := false


func _ready() -> void:
	left_arrow.hide()

func move_camera_to_x(target_x: float) -> void:
	is_moving = true

	var target_position := camera.global_position
	target_position.x = target_x

	var tween := create_tween()

	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_IN_OUT)

	tween.tween_property(
		camera,
		"global_position",
		target_position,
		move_duration
	)

	await tween.finished

	is_moving = false


func _on_go_right_button_pressed() -> void:
	if is_moving:
		return

	right_arrow.hide()
	left_arrow.show()

	move_camera_to_x(11.0)


func _on_go_left_button_pressed() -> void:
	if is_moving:
		return

	left_arrow.hide()
	right_arrow.show()

	move_camera_to_x(0.0)
