
extends Resource
class_name UpgradeData

@export var upgrade_id: StringName
@export var display_name: String = "Upgrade"

@export_group("Effect")
@export var upgrade_amount: float = 1.0

@export_group("Pricing")
@export var starting_price: int = 100
@export var price_multiplier: float = 2.0

@export_group("Limits")
@export var max_purchases: int = 0
# 0 means unlimited purchases.

@export_group("Progress")
@export var current_level: int = 0

var purchase_history: Array[int] = []

var current_price: int:
	get:
		return int(round(
			float(starting_price) * pow(price_multiplier, current_level)
		))

var is_maxed: bool:
	get:
		return max_purchases > 0 and current_level >= max_purchases
