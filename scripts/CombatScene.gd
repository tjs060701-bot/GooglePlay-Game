## CombatScene — Phase 1 placeholder.
## Wires DiceRoller + RollResolver to GameManager; full UI built in Phase 2.
extends Node2D

var _roller: DiceRoller
var _resolver: RollResolver


func _ready() -> void:
	_roller = DiceRoller.new()
	_resolver = RollResolver.new()
	_resolver.rune_step_started.connect(_on_rune_step_started)
	_resolver.rune_step_completed.connect(_on_rune_step_completed)
	_resolver.resolution_complete.connect(_on_resolution_complete)

	GameManager.state_changed.connect(_on_state_changed)
	_on_state_changed()


func _on_state_changed() -> void:
	# Phase 2 will update UI widgets here.
	pass


# ── Public API (called by UI buttons in Phase 2) ───────────────────────────────

func do_roll() -> void:
	if not GameManager.can_roll():
		return
	GameManager.spend_roll()
	var ctx := _roller.roll(GameManager.dice_pool, GameManager.active_dice_count())
	_resolver.resolve(ctx, GameManager.equipped_runes)


# ── Resolver callbacks ─────────────────────────────────────────────────────────

func _on_rune_step_started(rune_name: String, _idx: int) -> void:
	print("[CombatScene] Rune: ", rune_name)


func _on_rune_step_completed(rune_name: String, ctx: RollContext) -> void:
	print("[CombatScene] After %s → %d chips × %.2f mult = %d dmg" % [
		rune_name, ctx.chips, ctx.mult, ctx.total_damage()
	])


func _on_resolution_complete(ctx: RollContext) -> void:
	# Apply permanent glass-die shatters to the pool (highest index first to
	# avoid index shift mid-removal).
	var to_remove := ctx.dice_to_remove.duplicate()
	to_remove.sort()
	to_remove.reverse()
	for idx in to_remove:
		GameManager.remove_die_at(idx)

	# Apply bonus rolls granted this resolution.
	for _i in range(ctx.bonus_rolls):
		GameManager.rolls_remaining += 1

	GameManager.add_damage(ctx.total_damage())

	# Phase 2 UI will tween the step log; for now just print it.
	for entry in ctx.log_entries:
		print(entry)

	if GameManager.damage_dealt_this_combat >= GameManager.blind_threshold:
		GameManager.combat_victory()
