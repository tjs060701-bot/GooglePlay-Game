class_name CriticalHit
extends Rune

func _init() -> void:
	rune_name   = "Critical Hit"
	description = "If any die shows its maximum face, ×2.5 Mult"
	rune_type   = "mult"
	cost        = 5


func apply(context: RollContext) -> RollContext:
	var pool := context.dice_pool_snapshot
	for i in range(mini(context.raw_values.size(), pool.size())):
		var sides: int = pool[i].get("sides", 6)
		if context.raw_values[i] == sides:
			context.scale_mult(2.5, rune_name)
			return context
	return context
