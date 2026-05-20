extends Node2D

# ── Layout constants ───────────────────────────────────────────────────────────
const ENEMY_START_X  := 900.0   # x within the arena Control
const ENEMY_ATTACK_X := 160.0   # enemy left-edge x that triggers a player hit
const ENEMY_MOVE_DIST := 100.0  # px enemy advances per player roll
const CHAR_Y         := 140.0   # y of the top of character rects inside arena
const PLAYER_W       := 56.0
const PLAYER_H       := 90.0
const ENEMY_W        := 80.0
const ENEMY_H        := 110.0
const STEP_DELAY     := 0.55    # seconds between rune animation steps
const DIE_SIZE       := 60.0

# ── Subsystems ─────────────────────────────────────────────────────────────────
var _roller: DiceRoller
var _resolver: RollResolver
var _pending_steps: Array = []   # [{rune_name, chips, mult, damage}]
var _pending_ctx: RollContext

# ── UI references (assigned in _build_scene) ───────────────────────────────────
var _lbl_hp: Label
var _lbl_gold: Label
var _lbl_blind: Label
var _lbl_rolls: Label
var _lbl_curse: Label
var _bar_progress: ProgressBar
var _lbl_progress: Label
var _lbl_chips_mult: Label
var _dice_hbox: HBoxContainer
var _die_labels: Array[Label] = []
var _btn_roll: Button
var _log_rtl: RichTextLabel

# Arena
var _arena: Control
var _enemy: Control
var _enemy_hp_bar: ProgressBar
var _enemy_hp_lbl: Label

# ── State ──────────────────────────────────────────────────────────────────────
var _enemy_x: float = ENEMY_START_X
var _resolving: bool = false


# ── Lifecycle ──────────────────────────────────────────────────────────────────

func _ready() -> void:
	_roller = DiceRoller.new()
	_resolver = RollResolver.new()
	_resolver.rune_step_started.connect(_on_step_started)
	_resolver.rune_step_completed.connect(_on_step_completed)
	_resolver.resolution_complete.connect(_on_resolution_complete)
	GameManager.state_changed.connect(_refresh_ui)
	_build_scene()
	_refresh_ui()


# ── Scene construction (entire UI built in code) ───────────────────────────────

func _build_scene() -> void:
	var cl := CanvasLayer.new()
	add_child(cl)

	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	cl.add_child(root)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(vbox)

	_build_top_bar(vbox)
	_build_arena(vbox)
	_build_blind_progress(vbox)
	_build_chips_mult_label(vbox)
	_build_dice_tray(vbox)
	_build_roll_log(vbox)


func _build_top_bar(parent: Control) -> void:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, 68)
	parent.add_child(panel)

	var hbox := HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(hbox)

	# Left cluster
	var left := HBoxContainer.new()
	hbox.add_child(left)
	_lbl_hp   = _lbl("HP  3 / 3",  left, 15); _gap(left, 20)
	_lbl_gold = _lbl("Gold  5",    left, 15)

	# Centre cluster (blind name + curse) — expands to fill
	var centre := VBoxContainer.new()
	centre.alignment = BoxContainer.ALIGNMENT_CENTER
	centre.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(centre)

	_lbl_blind = _lbl("Small Blind — Ante 1", centre, 20)
	_lbl_blind.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	_lbl_curse = _lbl("", centre, 13)
	_lbl_curse.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lbl_curse.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3, 1))

	# Right cluster
	var right := HBoxContainer.new()
	hbox.add_child(right)
	_gap(right, 20)
	_lbl_rolls = _lbl("Rolls  4", right, 15)


func _build_arena(parent: Control) -> void:
	_arena = Control.new()
	_arena.custom_minimum_size = Vector2(0, 280)
	_arena.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_arena.clip_contents = true
	parent.add_child(_arena)

	# Background
	var bg := ColorRect.new()
	bg.color = Color(0.06, 0.10, 0.07, 1.0)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_arena.add_child(bg)

	# Ground line decoration
	var ground := ColorRect.new()
	ground.color = Color(0.15, 0.22, 0.15, 1.0)
	ground.set_anchor_and_offset(SIDE_LEFT,   0.0, 0.0)
	ground.set_anchor_and_offset(SIDE_RIGHT,  1.0, 0.0)
	ground.set_anchor_and_offset(SIDE_TOP,    1.0, -6.0)
	ground.set_anchor_and_offset(SIDE_BOTTOM, 1.0, 0.0)
	_arena.add_child(ground)

	# Player rectangle
	var player_rect := ColorRect.new()
	player_rect.color = Color(0.25, 0.45, 0.85, 1.0)
	player_rect.size    = Vector2(PLAYER_W, PLAYER_H)
	player_rect.position = Vector2(80.0, CHAR_Y)
	_arena.add_child(player_rect)

	var player_lbl := Label.new()
	player_lbl.text = "YOU"
	player_lbl.add_theme_font_size_override("font_size", 12)
	player_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	player_lbl.size     = Vector2(PLAYER_W, 16)
	player_lbl.position = Vector2(80.0, CHAR_Y + PLAYER_H + 4)
	_arena.add_child(player_lbl)

	# Enemy node (x driven by _enemy_x)
	_enemy = Control.new()
	_enemy.size     = Vector2(ENEMY_W, ENEMY_H + 32)
	_enemy.position = Vector2(ENEMY_START_X, CHAR_Y - 18)
	_arena.add_child(_enemy)

	_enemy_hp_bar = ProgressBar.new()
	_enemy_hp_bar.size          = Vector2(ENEMY_W, 14)
	_enemy_hp_bar.position      = Vector2(0, 0)
	_enemy_hp_bar.show_percentage = false
	_enemy.add_child(_enemy_hp_bar)

	var enemy_rect := ColorRect.new()
	enemy_rect.color    = Color(0.82, 0.14, 0.10, 1.0)
	enemy_rect.size     = Vector2(ENEMY_W, ENEMY_H)
	enemy_rect.position = Vector2(0, 18)
	_enemy.add_child(enemy_rect)

	_enemy_hp_lbl = Label.new()
	_enemy_hp_lbl.add_theme_font_size_override("font_size", 11)
	_enemy_hp_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_enemy_hp_lbl.size     = Vector2(ENEMY_W, 14)
	_enemy_hp_lbl.position = Vector2(0, ENEMY_H + 22)
	_enemy.add_child(_enemy_hp_lbl)


func _build_blind_progress(parent: Control) -> void:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, 52)
	parent.add_child(panel)

	var vbox := VBoxContainer.new()
	panel.add_child(vbox)

	_lbl_progress = _lbl("Damage  0 / 100", vbox, 13)
	_lbl_progress.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	_bar_progress = ProgressBar.new()
	_bar_progress.show_percentage        = false
	_bar_progress.size_flags_horizontal  = Control.SIZE_EXPAND_FILL
	_bar_progress.custom_minimum_size    = Vector2(0, 22)
	vbox.add_child(_bar_progress)


func _build_chips_mult_label(parent: Control) -> void:
	_lbl_chips_mult = Label.new()
	_lbl_chips_mult.custom_minimum_size      = Vector2(0, 36)
	_lbl_chips_mult.size_flags_horizontal    = Control.SIZE_EXPAND_FILL
	_lbl_chips_mult.horizontal_alignment     = HORIZONTAL_ALIGNMENT_CENTER
	_lbl_chips_mult.add_theme_font_size_override("font_size", 20)
	_lbl_chips_mult.add_theme_color_override("font_color", Color(1.0, 0.92, 0.30, 1.0))
	parent.add_child(_lbl_chips_mult)


func _build_dice_tray(parent: Control) -> void:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, 96)
	parent.add_child(panel)

	var outer := HBoxContainer.new()
	outer.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(outer)

	# Dice pool display
	var dvbox := VBoxContainer.new()
	dvbox.alignment = BoxContainer.ALIGNMENT_CENTER
	outer.add_child(dvbox)

	var title := _lbl("DICE POOL", dvbox, 11)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	_dice_hbox = HBoxContainer.new()
	_dice_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	dvbox.add_child(_dice_hbox)

	_gap(outer, 48)

	_btn_roll = Button.new()
	_btn_roll.custom_minimum_size = Vector2(120, 64)
	_btn_roll.text                = "ROLL"
	_btn_roll.add_theme_font_size_override("font_size", 22)
	_btn_roll.pressed.connect(_on_roll_pressed)
	outer.add_child(_btn_roll)


func _build_roll_log(parent: Control) -> void:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, 80)
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	parent.add_child(panel)

	_log_rtl = RichTextLabel.new()
	_log_rtl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_log_rtl.bbcode_enabled  = true
	_log_rtl.scroll_active   = false
	_log_rtl.add_theme_font_size_override("normal_font_size", 13)
	panel.add_child(_log_rtl)


# ── UI refresh ─────────────────────────────────────────────────────────────────

func _refresh_ui() -> void:
	if not _lbl_hp:
		return

	_lbl_hp.text    = "HP  %d / %d"      % [GameManager.player_hp, GameManager.max_player_hp]
	_lbl_gold.text  = "Gold  %d"          % GameManager.gold
	_lbl_blind.text = "%s  —  Ante %d"   % [GameManager.blind_name(), GameManager.current_ante]
	_lbl_rolls.text = "Rolls  %d"         % GameManager.rolls_remaining

	if GameManager.boss_curse == "RollCap":
		_lbl_curse.text = "BOSS CURSE: ROLL CAP  (3 dice max)"
	else:
		_lbl_curse.text = ""

	var dealt  := GameManager.damage_dealt_this_combat
	var thresh := GameManager.blind_threshold
	_lbl_progress.text   = "Damage  %d / %d" % [dealt, thresh]
	_bar_progress.max_value = maxf(float(thresh), 1.0)
	_bar_progress.value     = float(dealt)

	_sync_enemy_hp(dealt, thresh)
	_refresh_dice()

	var can_act := not _resolving and GameManager.can_roll()
	if _btn_roll:
		_btn_roll.disabled = not can_act


func _refresh_dice() -> void:
	if not _dice_hbox:
		return
	for child in _dice_hbox.get_children():
		child.queue_free()
	_die_labels.clear()

	var pool   := GameManager.dice_pool
	var active := GameManager.active_dice_count()

	for i in range(pool.size()):
		var die_data            = pool[i]
		var is_glass: bool      = die_data.get("is_glass", false)
		var inactive: bool      = (i >= active)

		var container := Control.new()
		container.custom_minimum_size = Vector2(DIE_SIZE, DIE_SIZE)
		_dice_hbox.add_child(container)

		var bg := ColorRect.new()
		bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		if inactive:
			bg.color = Color(0.28, 0.28, 0.30, 0.55)
		elif is_glass:
			bg.color = Color(0.50, 0.80, 1.00, 0.90)
		else:
			bg.color = Color(0.90, 0.85, 0.70, 1.00)
		container.add_child(bg)

		var lbl := Label.new()
		lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
		lbl.add_theme_font_size_override("font_size", 22)
		lbl.add_theme_color_override("font_color",
			Color(0.15, 0.50, 0.80, 1) if is_glass else Color(0.12, 0.08, 0.04, 1))
		var sides: int = die_data.get("sides", 6)
		lbl.text = "G" if is_glass else "d%d" % sides
		container.add_child(lbl)
		_die_labels.append(lbl)

		# Gap between dice
		if i < pool.size() - 1:
			_gap(_dice_hbox, 6)


func _show_die_values(values: Array[int]) -> void:
	for i in range(mini(values.size(), _die_labels.size())):
		_die_labels[i].text = str(values[i])


func _sync_enemy_hp(dealt: int, thresh: int) -> void:
	if not _enemy_hp_bar:
		return
	var remaining := maxi(0, thresh - dealt)
	_enemy_hp_bar.max_value = maxf(float(thresh), 1.0)
	_enemy_hp_bar.value     = float(remaining)
	_enemy_hp_lbl.text      = "HP  %d" % remaining


# ── Roll flow ──────────────────────────────────────────────────────────────────

func _on_roll_pressed() -> void:
	if _resolving or not GameManager.can_roll():
		return

	GameManager.spend_roll()
	_pending_steps.clear()
	_log_rtl.clear()
	_lbl_chips_mult.text = ""

	var ctx := _roller.roll(GameManager.dice_pool, GameManager.active_dice_count())

	# Show raw values immediately on the dice
	_show_die_values(ctx.raw_values)
	_log_rtl.append_text("[color=#aaaaaa]%s[/color]\n" % ctx.log_entries[0])

	# RollResolver fires signals synchronously; we collect then animate.
	_resolver.resolve(ctx, GameManager.equipped_runes)


func _on_step_started(_rune_name: String, _idx: int) -> void:
	pass  # buffered in _on_step_completed


func _on_step_completed(rune_name: String, ctx: RollContext) -> void:
	_pending_steps.append({
		"rune_name": rune_name,
		"chips":     ctx.chips,
		"mult":      ctx.mult,
		"damage":    ctx.total_damage(),
	})


func _on_resolution_complete(ctx: RollContext) -> void:
	_pending_ctx = ctx
	_resolving   = true
	if _btn_roll:
		_btn_roll.disabled = true
	_animate_step(0)


func _animate_step(i: int) -> void:
	if i >= _pending_steps.size():
		_finish_resolution()
		return

	var step: Dictionary = _pending_steps[i]
	_lbl_chips_mult.text = "  %d Chips  ×  %.2f Mult  =  %d Damage" % [
		step.chips, step.mult, step.damage
	]
	_log_rtl.append_text(
		"[color=yellow]%s[/color]  →  %d × %.2f = %d\n" % [
			step.rune_name, step.chips, step.mult, step.damage
		]
	)

	get_tree().create_timer(STEP_DELAY).timeout.connect(
		func(): _animate_step(i + 1), CONNECT_ONE_SHOT
	)


func _finish_resolution() -> void:
	var ctx := _pending_ctx

	# Apply glass-die shatters (remove highest index first to avoid index shift).
	var removals := ctx.dice_to_remove.duplicate()
	removals.sort()
	removals.reverse()
	for idx in removals:
		GameManager.remove_die_at(idx)

	# Grant bonus rolls (TripleTrigger etc.)
	if ctx.bonus_rolls > 0:
		GameManager.grant_bonus_rolls(ctx.bonus_rolls)
		_log_rtl.append_text("[color=cyan]+%d bonus roll(s)![/color]\n" % ctx.bonus_rolls)

	# Commit damage.
	GameManager.add_damage(ctx.total_damage())

	_log_rtl.append_text(
		"[b]Final: %d × %.2f = [color=orange]%d damage[/color][/b]\n" % [
			ctx.chips, ctx.mult, ctx.total_damage()
		]
	)
	_lbl_chips_mult.text = "  %d Chips  ×  %.2f Mult  =  %d Damage" % [
		ctx.chips, ctx.mult, ctx.total_damage()
	]

	# Gold earned this roll (e.g. from future per-roll economy runes).
	if ctx.gold_earned > 0:
		GameManager.add_gold(ctx.gold_earned)

	# Victory check.
	if GameManager.damage_dealt_this_combat >= GameManager.blind_threshold:
		_log_rtl.append_text("[color=lime][b]BLIND CLEARED![/b][/color]\n")
		get_tree().create_timer(1.2).timeout.connect(
			func(): GameManager.combat_victory(), CONNECT_ONE_SHOT
		)
		return

	# Enemy turn.
	get_tree().create_timer(0.35).timeout.connect(
		func(): _do_enemy_turn(), CONNECT_ONE_SHOT
	)


# ── Enemy turn ─────────────────────────────────────────────────────────────────

func _do_enemy_turn() -> void:
	_log_rtl.append_text("[color=#ff6666]Enemy advances![/color]\n")
	_enemy_x -= ENEMY_MOVE_DIST

	var tween := create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.tween_property(_enemy, "position:x", _enemy_x, 0.40)
	tween.tween_callback(_after_enemy_move)


func _after_enemy_move() -> void:
	if _enemy_x <= ENEMY_ATTACK_X:
		_enemy_attacks()
	else:
		_resolving = false
		GameManager.state_changed.emit()


func _enemy_attacks() -> void:
	_log_rtl.append_text("[color=red][b]Enemy attacks! −1 HP[/b][/color]\n")
	GameManager.take_damage(1)

	# Flash enemy red (already red, so flash white)
	_enemy.modulate = Color(2.0, 2.0, 2.0, 1.0)
	get_tree().create_timer(0.15).timeout.connect(
		func(): _enemy.modulate = Color.WHITE, CONNECT_ONE_SHOT
	)

	# Reset enemy position.
	_enemy_x = ENEMY_START_X
	_enemy.position.x = _enemy_x

	get_tree().create_timer(0.25).timeout.connect(func():
		_resolving = false
		GameManager.state_changed.emit()
	, CONNECT_ONE_SHOT)


# ── Helpers ────────────────────────────────────────────────────────────────────

func _lbl(txt: String, parent: Control, size: int = 14) -> Label:
	var l := Label.new()
	l.text = txt
	l.add_theme_font_size_override("font_size", size)
	parent.add_child(l)
	return l


func _gap(parent: Control, w: int) -> void:
	var s := Control.new()
	s.custom_minimum_size = Vector2(w, 0)
	parent.add_child(s)
