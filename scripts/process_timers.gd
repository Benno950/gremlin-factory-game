
extends Node
class_name ProcessTimer

# Spawn timestamps for Gremlins still waiting to be sold.
var active_timestamps: Array[int] = []

# Completed spawn-to-sale times, in seconds.
var sold_times: Array[float] = []


func register_gremlin_spawn() -> void:
	active_timestamps.append(Time.get_ticks_msec())


func sell_oldest_gremlins(amount: int) -> void:
	var count := mini(amount, active_timestamps.size())

	for i in range(count):
		var spawn_time: int = active_timestamps.pop_front()
		var elapsed: float = (
			Time.get_ticks_msec() - spawn_time
		) / 1000.0

		sold_times.append(elapsed)

		print("Gremlin sold in ", format_time(elapsed))


func get_shortest_time() -> float:
	if sold_times.is_empty():
		return 0.0

	var shortest: float = sold_times[0]

	for elapsed in sold_times:
		shortest = minf(shortest, elapsed)

	return shortest


func get_longest_time() -> float:
	if sold_times.is_empty():
		return 0.0

	var longest: float = sold_times[0]

	for elapsed in sold_times:
		longest = maxf(longest, elapsed)

	return longest


func get_average_time() -> float:
	if sold_times.is_empty():
		return 0.0

	var total := 0.0

	for elapsed in sold_times:
		total += elapsed

	return total / sold_times.size()


func get_total_sold() -> int:
	return sold_times.size()


func format_time(seconds: float) -> String:
	var total_seconds := int(seconds)
	var minutes := total_seconds / 60
	var remaining_seconds := total_seconds % 60
	var milliseconds := int((seconds - total_seconds) * 1000.0)

	return "%02d:%02d.%03d" % [
		minutes,
		remaining_seconds,
		milliseconds
	]
