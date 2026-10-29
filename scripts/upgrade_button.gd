
extends Area3D
class_name UpgradeButton

@export var game_manager: GameManager
@export var upgrade_id: StringName = &"crane"
@onready var upgrade_cost_label: Label3D = $UpgradeCostLabel

@onready var animation_player: AnimationPlayer = $AnimationPlayer


func _ready() -> void:
	input_ray_pickable = true
	input_event.connect(_on_input_event)
	refresh_button()

func refresh_button() -> void:
	if game_manager == null:
		return

	var upgrade: UpgradeData = game_manager.get_upgrade(upgrade_id)

	if upgrade == null:
		upgrade_cost_label.text = "N/A"
		return


	if upgrade.is_maxed:
		upgrade_cost_label.text = "MAX"
	else:
		upgrade_cost_label.text = "$ " + str(upgrade.current_price)


func _on_input_event(
	_viewport: Node,
	event: InputEvent,
	_event_position: Vector3,
	_normal: Vector3,
	_shape_idx: int
) -> void:
	if not event is InputEventMouseButton:
		return
	if event.button_index != MOUSE_BUTTON_LEFT or not event.pressed:
		return
	if not event.is_action_pressed("mouse_click"):
		return
	if game_manager == null:
		return

	if game_manager.purchase_upgrade(upgrade_id):
		if animation_player:
			animation_player.play("3d_button_pressed")

		print("Purchased upgrade: ", upgrade_id)

	refresh_button()
