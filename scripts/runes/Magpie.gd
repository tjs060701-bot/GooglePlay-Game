class_name Magpie
extends Rune

func _init() -> void:
	rune_name   = "Magpie"
	description = "Each roll earns +1 Gold"
	rune_type   = "economy"
	cost        = 4


func apply(context: RollContext) -> RollContext:
	context.add_gold(1, rune_name)
	return context
