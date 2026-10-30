extends Node
class_name GameManager

@export_group("UI Elements")
@onready var time_label: Label = $GameUI/MarginContainer/TimeLabel

@onready var money_label: Label = $GameUI/MarginContainer/MoneyLabel

@export_group("Game Logic")
@onready var game_timer: Timer = $GameTimer
@export var game_length := 120.0 
@export var money_per_box: int = 12
var time_remaining: float = 0.0

var total_money: int = 0
var current_money: int = 0
var sold_boxes: int = 0
var game_running: bool = false

@export_group("Factory Machines")
@export var gremlin_spawner: NormalGremlinSpawner
@export var crane_manager: CraneManager
@export var crane: GrabbingCrane
@export var conveyor_one: ConveyorOne
@export var pipe_controller: PipeController
@export var conveyor_two: ConveyorTwo
@export var shipping_cart: ShippingCart
@export var upgrades: Array[UpgradeData] = []
var upgrades_by_id: Dictionary = {}

@onready var buy_sound: AudioStreamPlayer2D = $BuySound

@onready var game_ui: Control = $GameUI
@onready var result_screen_ui: Control = $ResultScreenUI



func _ready() -> void:
	start_game()
	update_money_label()
	
	upgrades_by_id.clear()

	for upgrade in upgrades:
		if upgrade == null:
			continue

		if upgrades_by_id.has(upgrade.upgrade_id):
			push_warning("Duplicate upgrade ID: " + str(upgrade.upgrade_id))
			continue

		upgrades_by_id[upgrade.upgrade_id] = upgrade

func start_game() -> void:
	time_remaining = game_length
	game_running = true
	game_ui.visible = true
	run_game_timer()

func add_money(sellingprice) -> void:
	current_money += sellingprice
	update_money_label()
	
func remove_money(upgrade_cost) -> void:
	if current_money >= upgrade_cost:
		current_money -= upgrade_cost
		update_money_label()

func sell_boxes(amount: int) -> void:
	sold_boxes += amount
	current_money += money_per_box * amount
	total_money += money_per_box * amount
	update_money_label()
	print("Sold ", amount, " boxes. Total sold: ", sold_boxes)

func update_money_label() -> void:
	money_label.text = ("$ " + str(current_money))
	
func run_game_timer() -> void:
	game_timer.start(game_length)
	update_timer_display()

func update_timer_display() -> void:
	var total_seconds := int(ceil(time_remaining))
	var minutes := total_seconds / 60
	var seconds := total_seconds % 60

	time_label.text = "%d:%02d" % [minutes, seconds]

#Game Ended
func _on_game_timer_timeout() -> void:
	game_running = false
	gremlin_spawner.set_spawning_enabled(false)
	Engine.time_scale = 0

	print("Game ended")
	print("Total Sold Boxes: ", sold_boxes)
	game_ui.visible = false
	result_screen_ui.visible = true
	result_screen_ui.show_results()

func _process(delta: float) -> void:
	time_remaining = maxf(0.0, time_remaining - delta)
	update_timer_display()


func get_upgrade(upgrade_id: StringName) -> UpgradeData:
	return upgrades_by_id.get(upgrade_id) as UpgradeData


func refund_upgrade(upgrade_id: StringName) -> bool:
	var upgrade := get_upgrade(upgrade_id)

	if upgrade == null:
		return false

	# Can't refund an upgrade that hasn't been purchased.
	if upgrade.current_level <= 0:
		return false

	if upgrade.purchase_history.is_empty():
		push_warning("Missing purchase history for: " + str(upgrade_id))
		return false

	# The last purchase is refunded first.
	var refund_amount: int = upgrade.purchase_history.back()

	# Reverse the machine upgrade before changing money or history.
	if not apply_upgrade_effect(upgrade_id, false):
		return false

	upgrade.purchase_history.pop_back()
	upgrade.current_level -= 1
	current_money += refund_amount
	update_money_label()
	return true

func purchase_upgrade(upgrade_id: StringName) -> bool:
	var upgrade := get_upgrade(upgrade_id)

	if upgrade == null:
		push_warning("Unknown upgrade: " + str(upgrade_id))
		return false

	if upgrade.is_maxed:
		return false

	var upgrade_price := upgrade.current_price

	if current_money < upgrade_price:
		return false

	# Apply the effect before charging the player.
	if not apply_upgrade_effect(upgrade_id, true):
		return false

	current_money -= upgrade_price
	buy_sound.play()
	upgrade.purchase_history.append(upgrade_price)
	upgrade.current_level += 1
	update_money_label()

	return true

	
func apply_upgrade_effect(upgrade_id: StringName, buying: bool) -> bool:
	var upgrade: UpgradeData = get_upgrade(upgrade_id)
	match upgrade_id:
		&"crane":
			var amount: float = upgrade.upgrade_amount if buying else -upgrade.upgrade_amount

			if crane_manager != null:
				crane_manager.apply_speed_upgrade(amount)
			elif crane != null:
				# Fallback if you aren't using CraneManager.
				crane.apply_speed_upgrade(amount)
			else:
				return false

			return true

		&"gremlin_spawn_speed":
			if gremlin_spawner == null:
				return false

			var amount: float = upgrade.upgrade_amount

			if amount <= 0.0:
				return false

			if buying:
				# Reject the purchase if it would go below 2 seconds.
					if gremlin_spawner.spawn_interval_max - amount < 2.0:
						return false

					gremlin_spawner.spawn_interval_max -= amount
			else:
		# Restore the exact amount when refunding.
				gremlin_spawner.spawn_interval_max += amount

			return true

		&"conveyor_speed":
			if conveyor_one and conveyor_two == null:
				return false
				
			var amount: float = upgrade.upgrade_amount if buying else -upgrade.upgrade_amount
			conveyor_one.apply_conveyor_1_upgrade(amount)
			conveyor_two.apply_conveyor_2_upgrade(amount)
			return true
			
		&"cart_speed":
			if shipping_cart == null:
				return false
				
			var amount: float = upgrade.upgrade_amount if buying else -upgrade.upgrade_amount
			shipping_cart.apply_speed_upgrade(amount)
			return true

		&"pipe_upgrade":
			if pipe_controller == null:
				return false
				
			var amount: float = upgrade.upgrade_amount if buying else -upgrade.upgrade_amount
			pipe_controller.apply_quality_upgrade(amount)
			return true

		&"extra_crane":
			if crane_manager == null:
				return false

			var amount: int = int(round(upgrade.upgrade_amount))

			if amount <= 0:
				return false

			if buying:
				return crane_manager.add_crane(amount)
			else:
				return crane_manager.remove_crane(amount)

	return false

func reset_upgrades() -> void:
	for upgrade in upgrades:
		if upgrade == null:
			continue

		upgrade.current_level = 0
		upgrade.purchase_history.clear()

	print("All upgrades reset for the new round.")
