extends CSGBox3D

@export var scroll_speed: float = 5


func _process(delta: float) -> void:
	material.uv1_offset * delta * scroll_speed
	
	
