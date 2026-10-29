extends Node

class_name CraneManager

@export var extra_crane_1: GrabbingCrane
@export var extra_crane_2: GrabbingCrane

var extra_cranes: int = 0

func add_crane(amount) -> void:
	extra_cranes += amount
	print("Current Cranes: " , extra_cranes)
	
func remove_crane(amount) -> void:
	extra_cranes -= amount
	print("Current Cranes Removed: " , extra_cranes)
	
func _process(delta: float) -> void:
	if extra_cranes == 1:
		extra_crane_1.enable_crane()
		
	if extra_cranes == 2:
		extra_crane_2.enable_crane()
