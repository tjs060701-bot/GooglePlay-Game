class_name OddStrike
extends Rune

func _init() -> void:
	rune_name = "Odd Strike"
	description = "If ALL dice show odd numbers, add +30 Chips"
	rune_type = "damage"
	cost = 3


func apply(context: RollContext) -> RollContext:
	if context.raw_values.is_empty():
		return context
	var all_odd := context.raw_values.all(func(v): return v % 2 != 0)
	if all_odd:
		context.add_chips(30, rune_name)
	return context
