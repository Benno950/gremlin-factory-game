extends Control

@export var game_manager: GameManager

@onready var total_sold_boxes_label: Label = $MarginContainer/VBoxContainer2/VBoxContainer/TotalSoldBoxesLabel
@onready var total_money_label: Label = $MarginContainer/VBoxContainer2/VBoxContainer/TotalMoneyLabel

@onready var process_timer: ProcessTimer = %ProcessTimer
@onready var shortest_process_time_label: Label = $MarginContainer/VBoxContainer2/VBoxContainer/ShortestProcessTimeLabel
@onready var longest_process_time_label: Label = $MarginContainer/VBoxContainer2/VBoxContainer/LongestProcessTimeLabel
@onready var average_process_time_label: Label = $MarginContainer/VBoxContainer2/VBoxContainer/AverageProcessTimeLabel




func _ready() -> void:
	visible = false

func show_results() -> void:
	visible = true
	total_sold_boxes_label.text = ("Total Gremlins Sold: " + str(game_manager.sold_boxes))
	total_money_label.text = ("Total Money Earned: $ " + str(game_manager.total_money))
	
	shortest_process_time_label.text = "Shortest Process Time: " + process_timer.format_time(
		process_timer.get_shortest_time()
	)

	longest_process_time_label.text = "Longest Process Time: " + process_timer.format_time(
		process_timer.get_longest_time()
	)

	average_process_time_label.text = "Average Process Time: " + process_timer.format_time(
		process_timer.get_average_time()
	)
	



func _on_retry_button_pressed() -> void:
	Engine.time_scale = 1
	game_manager.reset_upgrades()
	get_tree().reload_current_scene()
	

func _on_quit_button_pressed() -> void:
	Engine.time_scale = 1
	get_tree().quit()
