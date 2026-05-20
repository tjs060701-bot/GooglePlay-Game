class_name GlassDie
extends Rune

func _init() -> void:
	rune_name = "Glass Die"
	description = "One die becomes Glass: rolls 5+ give ×3 Mult; rolls 1 shatter it forever"
	rune_type = "trigger"
	cost = 3


# Mark the first unmarked die in the pool as glass when equipped.
func on_equip(gm: Node) -> void:
	for i in range(gm.dice_pool.size()):
		if not gm.dice_pool[i].get("is_glass", false):
			gm.mark_die_as_glass(i)
			break


func apply(context: RollContext) -> RollContext:
	for i in range(context.dice_pool_snapshot.size()):
		if i >= context.raw_values.size():
			break
		if not context.dice_pool_snapshot[i].get("is_glass", false):
			continue
		var v: int = context.raw_values[i]
		if v >= 5:
			context.scale_mult(3.0, "%s (die #%d rolled %d)" % [rune_name, i, v])
		elif v == 1:
			context.mark_die_for_removal(i, rune_name)
	return context
