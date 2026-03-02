extends RefCounted
class_name Economy


static func scaled_cost(base_cost: float, scaling: float, purchased_count: int) -> int:
	return maxi(1, int(floor(base_cost * pow(scaling, purchased_count))))


static func format_short(value: float) -> String:
	var abs_value := absf(value)
	if abs_value < 1000.0:
		return str(int(floor(value)))

	var suffixes := ["k", "M", "B", "T", "Qa", "Qi", "Sx"]
	var reduced := value
	var suffix_idx := -1
	while absf(reduced) >= 1000.0 and suffix_idx < suffixes.size() - 1:
		reduced /= 1000.0
		suffix_idx += 1

	var decimals := 2
	if absf(reduced) >= 100.0:
		decimals = 0
	elif absf(reduced) >= 10.0:
		decimals = 1
	var formatted := ("%." + str(decimals) + "f") % reduced
	formatted = _trim_trailing_zeros(formatted)
	return "%s%s" % [formatted, suffixes[suffix_idx]]


static func calculate_prestige_gain(max_wave_reached: int, current_gold: float) -> int:
	var wave_gain := maxi(0, int(floor(max_wave_reached / 10.0)))
	var gold_gain := 0
	if current_gold >= 1_000_000_000.0:
		gold_gain = maxi(1, int(floor(log(current_gold / 1_000_000_000.0 + 1.0) / log(2.0))))
	return maxi(1, wave_gain + gold_gain)


static func _trim_trailing_zeros(formatted: String) -> String:
	var result := formatted
	if result.find(".") == -1:
		return result
	while result.ends_with("0"):
		result = result.left(-1)
	if result.ends_with("."):
		result = result.left(-1)
	return result
