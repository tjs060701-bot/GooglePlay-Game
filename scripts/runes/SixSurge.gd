class_name SixSurge
extends Rune

func _init() -> void:
	rune_name = "Six Surge"
	description = "Each die showing 6 adds +4 Mult"
	rune_type = "mult"
	cost = 3


func apply(context: RollContext) -> RollContext:
	for v in context.raw_values:
		if v == 6:
			context.add_mult(4.0, rune_name)
	return context
