extends Node
class_name CraneManager

@export_group("Crane Setup")
@export var cranes: Array[GrabbingCrane] = []

# Number of extra cranes purchased.
var extra_cranes: int = 0


func _ready() -> void:
	if cranes.is_empty():
		push_warning("CraneManager: No cranes assigned!")
		return

	# The first crane is the default crane.
	for i in range(cranes.size()):
		var current_crane := cranes[i]

		if current_crane == null:
			continue

		if i == 0:
			current_crane.enable_crane()
		else:
			current_crane.disable_crane()


func add_crane(amount: int = 1) -> bool:
	if amount <= 0:
		return false

	# Check capacity before enabling any cranes.
	if extra_cranes + amount >= cranes.size():
		return false

	for i in range(amount):
		var crane_index := extra_cranes + 1
		var new_crane := cranes[crane_index]

		if new_crane == null:
			push_warning("CraneManager: Missing crane at index %d" % crane_index)
			return false

		new_crane.enable_crane()
		extra_cranes += 1

	print("Active cranes: ", extra_cranes + 1)
	return true


func remove_crane(amount: int = 1) -> bool:
	if amount <= 0 or amount > extra_cranes:
		return false

	for i in range(amount):
		var crane_index := extra_cranes
		var current_crane := cranes[crane_index]

		if current_crane != null:
			current_crane.disable_crane()

		extra_cranes -= 1

	print("Active cranes: ", extra_cranes + 1)
	return true


func apply_speed_upgrade(amount: float) -> void:
	for current_crane in cranes:
		if current_crane == null:
			continue

		current_crane.apply_speed_upgrade(amount)
