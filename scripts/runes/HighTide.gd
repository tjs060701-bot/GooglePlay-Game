class_name HighTide
extends Rune

func _init() -> void:
	rune_name = "High Tide"
	description = "The highest die value is added again to Chips (effective doubling)"
	rune_type = "damage"
	cost = 3


func apply(context: RollContext) -> RollContext:
	if context.raw_values.is_empty():
		return context
	var highest: int = context.raw_values.max()
	context.add_chips(highest, "%s (max die ×2: +%d)" % [rune_name, highest])
	return context
