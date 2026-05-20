class_name RollResolver
extends RefCounted

## Walks equipped runes in order, calling apply() on each.
## Signals fire synchronously so the UI can queue tween delays between steps.

signal rune_step_started(rune_name: String, rune_index: int)
signal rune_step_completed(rune_name: String, context: RollContext)
signal resolution_complete(context: RollContext)


func resolve(context: RollContext, runes: Array) -> RollContext:
	for i in range(runes.size()):
		var rune = runes[i]
		rune_step_started.emit(rune.rune_name, i)
		context = rune.apply(context)
		rune_step_completed.emit(rune.rune_name, context)

	context.log_entries.append(
		"Final  →  %d × %.2f  =  %d damage" % [
			context.chips, context.mult, context.total_damage()
		]
	)
	resolution_complete.emit(context)
	return context
