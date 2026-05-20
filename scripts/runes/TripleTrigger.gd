class_name TripleTrigger
extends Rune

func _init() -> void:
	rune_name = "Triple Trigger"
	description = "Rolling three-of-a-kind grants one free bonus roll"
	rune_type = "trigger"
	cost = 3


func apply(context: RollContext) -> RollContext:
	var counts: Dictionary = {}
	for v in context.raw_values:
		counts[v] = counts.get(v, 0) + 1
	for val in counts:
		if counts[val] >= 3:
			context.add_bonus_roll(rune_name)
			break   # only one bonus roll per resolution
	return context
