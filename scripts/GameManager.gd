extends Node

# ── Run state ──────────────────────────────────────────────────────────────────
var current_ante: int = 1
var current_blind: int = 1   # 1 = Small, 2 = Big, 3 = Boss
var gold: int = 5
var player_hp: int = 3
var max_player_hp: int = 3
var max_rolls: int = 4
var rolls_remaining: int = 4

# ── Dice pool: Array of { sides: int, is_glass: bool } ─────────────────────────
var dice_pool: Array = []

# ── Rune slots ─────────────────────────────────────────────────────────────────
const MAX_RUNES: int = 5
var equipped_runes: Array = []   # Array[Rune]

# ── Combat tracking ────────────────────────────────────────────────────────────
var blind_threshold: int = 0
var boss_curse: String = ""       # "RollCap" on Boss Blind, else ""
var damage_dealt_this_combat: int = 0
var last_run_stats: Dictionary = {}

# ── Signals ────────────────────────────────────────────────────────────────────
signal state_changed()
signal run_ended(won: bool, stats: Dictionary)


func _ready() -> void:
	_initialize_run()


# ── Initialisation ─────────────────────────────────────────────────────────────

func _initialize_run() -> void:
	current_ante = 1
	current_blind = 1
	gold = 5
	player_hp = 3
	max_player_hp = 3
	dice_pool = []
	for _i in range(4):
		dice_pool.append({"sides": 6, "is_glass": false})
	equipped_runes = []
	_refresh_blind()


func _refresh_blind() -> void:
	blind_threshold = _threshold(current_ante, current_blind)
	rolls_remaining = max_rolls
	damage_dealt_this_combat = 0
	boss_curse = "RollCap" if current_blind == 3 else ""
	state_changed.emit()


func _threshold(ante: int, blind: int) -> int:
	match blind:
		1: return 100 * ante
		2: return 175 * ante
		3: return 300 * ante
		_: return 100 * ante


# ── Queries ────────────────────────────────────────────────────────────────────

func blind_name() -> String:
	match current_blind:
		1: return "Small Blind"
		2: return "Big Blind"
		3: return "Boss Blind"
		_: return "?"


func active_dice_count() -> int:
	var cap := 3 if boss_curse == "RollCap" else dice_pool.size()
	return min(cap, dice_pool.size())


## Returns the threshold for the *next* blind (-1 if the run would end).
func next_blind_threshold() -> int:
	var nb := current_blind + 1
	var na := current_ante
	if nb > 3:
		nb = 1
		na += 1
	if na > 3:
		return -1
	return _threshold(na, nb)


# ── Rolls ───────────────────────────────────────────────────────────────────────

func spend_roll() -> void:
	rolls_remaining = max(0, rolls_remaining - 1)
	state_changed.emit()


func grant_bonus_rolls(n: int) -> void:
	rolls_remaining += n
	state_changed.emit()


func can_roll() -> bool:
	return rolls_remaining > 0


# ── Damage / HP ────────────────────────────────────────────────────────────────

func add_damage(amount: int) -> void:
	damage_dealt_this_combat += amount
	state_changed.emit()


func take_damage(amount: int) -> void:
	player_hp = max(0, player_hp - amount)
	state_changed.emit()
	if player_hp <= 0:
		_end_run(false)


# ── Economy ────────────────────────────────────────────────────────────────────

func add_gold(amount: int) -> void:
	gold += amount
	state_changed.emit()


## Returns false if the player cannot afford it.
func spend_gold(amount: int) -> bool:
	if gold < amount:
		return false
	gold -= amount
	state_changed.emit()
	return true


# ── Rune management ────────────────────────────────────────────────────────────

func equip_rune(rune) -> bool:
	if equipped_runes.size() >= MAX_RUNES:
		return false
	equipped_runes.append(rune)
	rune.on_equip(self)
	state_changed.emit()
	return true


func sell_rune(index: int) -> void:
	if index < 0 or index >= equipped_runes.size():
		return
	equipped_runes.remove_at(index)
	add_gold(1)


# ── Dice pool management ───────────────────────────────────────────────────────

func remove_die_at(index: int) -> void:
	if index >= 0 and index < dice_pool.size():
		dice_pool.remove_at(index)
		state_changed.emit()


func mark_die_as_glass(index: int) -> void:
	if index >= 0 and index < dice_pool.size():
		dice_pool[index]["is_glass"] = true
		state_changed.emit()


# ── Combat flow ────────────────────────────────────────────────────────────────

## Call this when the player meets the blind threshold.
func combat_victory() -> void:
	# Let economy runes pay out
	for rune in equipped_runes:
		var g: int = rune.on_combat_end(damage_dealt_this_combat, blind_threshold)
		if g > 0:
			add_gold(g)
	_advance_blind()


func _advance_blind() -> void:
	current_blind += 1
	if current_blind > 3:
		current_blind = 1
		current_ante += 1
	if current_ante > 3:
		_end_run(true)
		return
	_refresh_blind()
	get_tree().change_scene_to_file("res://scenes/ShopScene.tscn")


func proceed_to_combat() -> void:
	_refresh_blind()
	get_tree().change_scene_to_file("res://scenes/CombatScene.tscn")


func _end_run(won: bool) -> void:
	last_run_stats = {
		"won": won,
		"ante_reached": current_ante,
		"blind_reached": current_blind,
		"gold": gold,
		"damage_dealt": damage_dealt_this_combat,
		"runes_used": equipped_runes.map(func(r): return r.rune_name),
	}
	run_ended.emit(won, last_run_stats)
	get_tree().change_scene_to_file("res://scenes/EndScreen.tscn")


func restart_run() -> void:
	_initialize_run()
	get_tree().change_scene_to_file("res://scenes/CombatScene.tscn")
