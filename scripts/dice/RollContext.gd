class_name RollContext
extends RefCounted

## Mutable state that flows through the RollResolver pipeline.
## Rune.apply() reads and writes this object; the UI reads it via signals.

var raw_values: Array[int] = []           # one entry per active die
var dice_pool_snapshot: Array = []        # copy of GameManager.dice_pool at roll time
var chips: int = 0                        # base damage accumulator
var mult: float = 1.0                     # damage multiplier
var bonus_rolls: int = 0                  # extra free rolls granted this resolution
var gold_earned: int = 0                  # gold granted this resolution
var dice_to_remove: Array[int] = []       # pool indices to drop after resolution
var log_entries: Array[String] = []       # human-readable step log for UI


func total_damage() -> int:
	return int(chips * mult)


# ── Mutation helpers (log automatically) ───────────────────────────────────────

func add_chips(amount: int, source: String = "") -> void:
	chips += amount
	if source:
		log_entries.append("+%d Chips  [%s]" % [amount, source])


func add_mult(amount: float, source: String = "") -> void:
	mult += amount
	if source:
		log_entries.append("+%.1f Mult  [%s]" % [amount, source])


func scale_mult(factor: float, source: String = "") -> void:
	mult *= factor
	if source:
		log_entries.append("×%.1f Mult  [%s]" % [factor, source])


func add_bonus_roll(source: String = "") -> void:
	bonus_rolls += 1
	if source:
		log_entries.append("Bonus roll  [%s]" % source)


func add_gold(amount: int, source: String = "") -> void:
	gold_earned += amount
	if source:
		log_entries.append("+%d Gold  [%s]" % [amount, source])


func mark_die_for_removal(pool_index: int, source: String = "") -> void:
	if pool_index not in dice_to_remove:
		dice_to_remove.append(pool_index)
	if source:
		log_entries.append("Die #%d shattered  [%s]" % [pool_index, source])
