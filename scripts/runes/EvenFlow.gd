class_name EvenFlow
extends Rune

func _init() -> void:
	rune_name   = "Even Flow"
	description = "If ALL dice show even numbers, add +25 Chips"
	rune_type   = "damage"
	cost        = 3


func apply(context: RollContext) -> RollContext:
	if context.raw_values.is_empty():
		return context
	var all_even := context.raw_values.all(func(v): return v % 2 == 0)
	if all_even:
		context.add_chips(25, rune_name)
	return context
