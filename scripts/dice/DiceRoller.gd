class_name DiceRoller
extends RefCounted

## Pure-logic roller. Takes the current dice pool and active count,
## returns a RollContext with raw values and base chips pre-filled.

func roll(dice_pool: Array, active_count: int) -> RollContext:
	var ctx := RollContext.new()
	ctx.dice_pool_snapshot = dice_pool.duplicate(true)

	var count := min(active_count, dice_pool.size())
	for i in range(count):
		var sides: int = dice_pool[i].get("sides", 6)
		ctx.raw_values.append(randi_range(1, sides))

	# Base chips = sum of all rolled values
	for v in ctx.raw_values:
		ctx.chips += v

	ctx.log_entries.append(
		"Rolled %s  →  %d base Chips" % [str(ctx.raw_values), ctx.chips]
	)
	return ctx
