
extends HSlider

@export var bus_name: String = "Music"

var bus_index: int = -1

func _ready() -> void:
	bus_index = AudioServer.get_bus_index(bus_name)

	if bus_index == -1:
		push_warning("Audio bus not found: " + bus_name)
		return

	# Match the slider to the current bus volume.
	value = AudioServer.get_bus_volume_db(bus_index)

	# Update the bus whenever the slider moves.
	value_changed.connect(_on_volume_changed)

func _on_volume_changed(slider_value: float) -> void:
	if bus_index == -1:
		return

	AudioServer.set_bus_volume_db(bus_index, slider_value)

	# Mute at the minimum slider value.
	AudioServer.set_bus_mute(bus_index, slider_value <= -20.0)
