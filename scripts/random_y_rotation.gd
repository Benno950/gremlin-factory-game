extends Node3D


func _ready() -> void:
	rotation.y = randf_range(0.0, TAU)
