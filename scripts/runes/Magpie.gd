class_name Magpie
extends Rune

func _init() -> void:
	rune_name   = "Magpie"
	description = "Each roll earns +1 Gold"
	rune_type   = "economy"
	cost        = 4


func apply(context: RollContext) -> RollContext:
	context.gold_earned += 1
	context.log_entries.append("%s: +1 Gold" % rune_name)
	return context
