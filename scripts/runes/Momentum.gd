class_name Momentum
extends Rune

func _init() -> void:
	rune_name   = "Momentum"
	description = "Add +8 Chips for each die in your pool"
	rune_type   = "damage"
	cost        = 4


func apply(context: RollContext) -> RollContext:
	var bonus: int = context.dice_pool_snapshot.size() * 8
	context.add_chips(bonus, rune_name)
	return context
