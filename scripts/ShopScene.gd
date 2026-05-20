## ShopScene — browse offered runes, upgrade dice, manage equipped runes, proceed.
extends Node2D

const RUNE_SCRIPTS: Array[String] = [
	"res://scripts/runes/OddStrike.gd",
	"res://scripts/runes/SixSurge.gd",
	"res://scripts/runes/GlassDie.gd",
	"res://scripts/runes/TripleTrigger.gd",
	"res://scripts/runes/HighTide.gd",
	"res://scripts/runes/GoldVein.gd",
	"res://scripts/runes/EvenFlow.gd",
	"res://scripts/runes/Magpie.gd",
	"res://scripts/runes/CriticalHit.gd",
	"res://scripts/runes/Momentum.gd",
]
const SHOP_COST  := 3
const SELL_PRICE := 1

# Dice upgrade costs
const COST_ADD_D6   := 4
const COST_D6_TO_D8 := 5
const COST_D6_TO_D12 := 8

# 3 rune instances offered this visit; null = already purchased.
var _offered: Array = []

# UI references
var _lbl_hp:           Label
var _lbl_gold:         Label
var _lbl_next:         Label
var _lbl_curse:        Label
var _lbl_pool:         Label
var _lbl_equip_header: Label
var _shop_hbox:        HBoxContainer
var _dice_hbox:        HBoxContainer
var _equip_hbox:       HBoxContainer


func _ready() -> void:
	GameManager.state_changed.connect(_refresh_ui)
	_roll_shop()
	_build_scene()
	_refresh_ui()


# ── Shop roll ──────────────────────────────────────────────────────────────────

func _roll_shop() -> void:
	var scripts := RUNE_SCRIPTS.duplicate()
	scripts.shuffle()
	_offered = []
	for i in range(mini(3, scripts.size())):
		_offered.append(load(scripts[i]).new())


# ── Scene construction ─────────────────────────────────────────────────────────

func _build_scene() -> void:
	var cl := CanvasLayer.new()
	add_child(cl)

	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	cl.add_child(root)

	var outer := VBoxContainer.new()
	outer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(outer)

	_build_top_bar(outer)
	_gap_v(outer, 6)

	# ── Rune shop ──
	var shop_title := _lbl("— SHOP —", outer, 22)
	shop_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	_gap_v(outer, 4)

	var shop_center := CenterContainer.new()
	shop_center.custom_minimum_size = Vector2(0, 175)
	outer.add_child(shop_center)

	_shop_hbox = HBoxContainer.new()
	_shop_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	shop_center.add_child(_shop_hbox)

	_gap_v(outer, 8)

	# ── Dice upgrades ──
	var dice_title := _lbl("— DICE UPGRADES —", outer, 18)
	dice_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	_gap_v(outer, 4)

	_lbl_pool = _lbl("Pool: d6 d6 d6 d6", outer, 12)
	_lbl_pool.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lbl_pool.add_theme_color_override("font_color", Color(0.70, 0.70, 0.70, 1))

	_gap_v(outer, 4)

	var dice_center := CenterContainer.new()
	dice_center.custom_minimum_size = Vector2(0, 52)
	outer.add_child(dice_center)

	_dice_hbox = HBoxContainer.new()
	_dice_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	dice_center.add_child(_dice_hbox)

	_gap_v(outer, 8)

	# ── Equipped runes ──
	_lbl_equip_header = _lbl("— EQUIPPED RUNES  0 / 5 —", outer, 18)
	_lbl_equip_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	_gap_v(outer, 4)

	var equip_center := CenterContainer.new()
	equip_center.custom_minimum_size = Vector2(0, 100)
	equip_center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	outer.add_child(equip_center)

	_equip_hbox = HBoxContainer.new()
	_equip_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	equip_center.add_child(_equip_hbox)

	_gap_v(outer, 8)
	_build_footer(outer)
	_gap_v(outer, 10)


func _build_top_bar(parent: Control) -> void:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, 64)
	parent.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(vbox)

	var hbox := HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(hbox)

	_lbl_hp   = _lbl("HP  3 / 3", hbox, 15)
	_gap_h(hbox, 28)
	_lbl_gold = _lbl("Gold  5",   hbox, 15)
	_gap_h(hbox, 48)
	_lbl_next = _lbl("Next: Big Blind  —  Ante 1  (need 175)", hbox, 16)

	_lbl_curse = _lbl("", vbox, 12)
	_lbl_curse.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lbl_curse.add_theme_color_override("font_color", Color(1.0, 0.35, 0.35, 1))


func _build_footer(parent: Control) -> void:
	var hbox := HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	parent.add_child(hbox)

	var btn := Button.new()
	btn.text = "Proceed to Next Blind"
	btn.custom_minimum_size = Vector2(280, 60)
	btn.add_theme_font_size_override("font_size", 22)
	btn.pressed.connect(func(): GameManager.proceed_to_combat())
	hbox.add_child(btn)


# ── UI refresh ─────────────────────────────────────────────────────────────────

func _refresh_ui() -> void:
	if not _lbl_hp:
		return

	_lbl_hp.text   = "HP  %d / %d" % [GameManager.player_hp, GameManager.max_player_hp]
	_lbl_gold.text = "Gold  %d"    % GameManager.gold

	var thresh := GameManager.blind_threshold
	_lbl_next.text = "Next: %s  —  Ante %d  (need %d)" % [
		GameManager.blind_name(), GameManager.current_ante, thresh
	]

	if GameManager.boss_curse == "RollCap":
		_lbl_curse.text = "WARNING: Boss Blind — ROLL CAP active (3 dice max)"
	else:
		_lbl_curse.text = ""

	_lbl_pool.text = "Pool: " + " ".join(
		GameManager.dice_pool.map(func(d): return "d%d" % d.get("sides", 6))
	)

	_lbl_equip_header.text = "— EQUIPPED RUNES  %d / %d —" % [
		GameManager.equipped_runes.size(), GameManager.MAX_RUNES
	]

	_rebuild_shop_cards()
	_rebuild_dice_upgrades()
	_rebuild_equip_slots()


# ── Shop cards ─────────────────────────────────────────────────────────────────

func _rebuild_shop_cards() -> void:
	_clear_children(_shop_hbox)

	for i in range(_offered.size()):
		var card := _make_shop_card(_offered[i], i)
		_shop_hbox.add_child(card)
		if i < _offered.size() - 1:
			_gap_h(_shop_hbox, 20)


func _make_shop_card(rune, shop_idx: int) -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(190, 160)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(vbox)

	if rune == null:
		_gap_v(vbox, 30)
		var sold := _lbl("[ SOLD ]", vbox, 18)
		sold.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		sold.add_theme_color_override("font_color", Color(0.40, 0.40, 0.40, 1))
		return panel

	var name_lbl := _lbl(rune.rune_name, vbox, 17)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.autowrap_mode        = TextServer.AUTOWRAP_WORD_SMART

	_gap_v(vbox, 4)

	var desc_lbl := _lbl(rune.description, vbox, 12)
	desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_lbl.autowrap_mode        = TextServer.AUTOWRAP_WORD_SMART

	_gap_v(vbox, 6)

	var type_lbl := _lbl("[%s]" % rune.rune_type.to_upper(), vbox, 11)
	type_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	type_lbl.add_theme_color_override("font_color", _type_color(rune.rune_type))

	_gap_v(vbox, 8)

	var can_buy := (
		GameManager.gold >= SHOP_COST and
		GameManager.equipped_runes.size() < GameManager.MAX_RUNES
	)
	var btn := Button.new()
	btn.text     = "Buy  (%dg)" % SHOP_COST
	btn.disabled = not can_buy
	btn.custom_minimum_size = Vector2(150, 32)
	btn.pressed.connect(func(): _buy_rune(shop_idx))
	var btn_c := CenterContainer.new()
	btn_c.add_child(btn)
	vbox.add_child(btn_c)

	return panel


func _buy_rune(shop_idx: int) -> void:
	if shop_idx >= _offered.size() or _offered[shop_idx] == null:
		return
	var rune = _offered[shop_idx]
	if not GameManager.spend_gold(SHOP_COST):
		return
	if not GameManager.equip_rune(rune):
		GameManager.add_gold(SHOP_COST)   # refund — slots full
		return
	_offered[shop_idx] = null
	# equip_rune emits state_changed → _refresh_ui fires automatically


# ── Dice upgrades ──────────────────────────────────────────────────────────────

func _rebuild_dice_upgrades() -> void:
	_clear_children(_dice_hbox)

	var has_d6 := GameManager.dice_pool.any(func(d): return d.get("sides", 6) == 6)

	var options := [
		{
			"label": "Add d6  (%dg)" % COST_ADD_D6,
			"can":   GameManager.gold >= COST_ADD_D6,
			"action": func(): _buy_add_die(6, COST_ADD_D6),
		},
		{
			"label": "d6 → d8  (%dg)" % COST_D6_TO_D8,
			"can":   GameManager.gold >= COST_D6_TO_D8 and has_d6,
			"action": func(): _buy_upgrade_die(6, 8, COST_D6_TO_D8),
		},
		{
			"label": "d6 → d12  (%dg)" % COST_D6_TO_D12,
			"can":   GameManager.gold >= COST_D6_TO_D12 and has_d6,
			"action": func(): _buy_upgrade_die(6, 12, COST_D6_TO_D12),
		},
	]

	for i in range(options.size()):
		var opt: Dictionary = options[i]
		var btn := Button.new()
		btn.text     = opt.label
		btn.disabled = not opt.can
		btn.custom_minimum_size = Vector2(155, 42)
		btn.add_theme_font_size_override("font_size", 14)
		btn.pressed.connect(opt.action)
		_dice_hbox.add_child(btn)
		if i < options.size() - 1:
			_gap_h(_dice_hbox, 14)


func _buy_add_die(sides: int, cost: int) -> void:
	if GameManager.spend_gold(cost):
		GameManager.add_die(sides)


func _buy_upgrade_die(from_sides: int, to_sides: int, cost: int) -> void:
	if GameManager.spend_gold(cost):
		GameManager.upgrade_die_sides(from_sides, to_sides)


# ── Equip slots ────────────────────────────────────────────────────────────────

func _rebuild_equip_slots() -> void:
	_clear_children(_equip_hbox)

	for i in range(GameManager.MAX_RUNES):
		var slot := _make_equip_slot(i)
		_equip_hbox.add_child(slot)
		if i < GameManager.MAX_RUNES - 1:
			_gap_h(_equip_hbox, 10)


func _make_equip_slot(slot_idx: int) -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(128, 90)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(vbox)

	if slot_idx >= GameManager.equipped_runes.size():
		_gap_v(vbox, 14)
		var empty := _lbl("[ empty ]", vbox, 13)
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty.add_theme_color_override("font_color", Color(0.36, 0.36, 0.36, 1))
		return panel

	var rune = GameManager.equipped_runes[slot_idx]

	var name_lbl := _lbl(rune.rune_name, vbox, 13)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.autowrap_mode        = TextServer.AUTOWRAP_WORD_SMART

	_gap_v(vbox, 3)

	var type_lbl := _lbl("[%s]" % rune.rune_type.to_upper(), vbox, 10)
	type_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	type_lbl.add_theme_color_override("font_color", _type_color(rune.rune_type))

	_gap_v(vbox, 5)

	var btn := Button.new()
	btn.text = "Sell  (1g)"
	btn.custom_minimum_size = Vector2(108, 26)
	btn.add_theme_font_size_override("font_size", 12)
	btn.pressed.connect(func(): GameManager.sell_rune(slot_idx))
	var btn_c := CenterContainer.new()
	btn_c.add_child(btn)
	vbox.add_child(btn_c)

	return panel


# ── Helpers ────────────────────────────────────────────────────────────────────

func _clear_children(node: Control) -> void:
	while node.get_child_count() > 0:
		var child := node.get_child(node.get_child_count() - 1)
		node.remove_child(child)
		child.queue_free()


func _type_color(rune_type: String) -> Color:
	match rune_type:
		"damage":  return Color(1.0, 0.40, 0.40, 1)
		"mult":    return Color(1.0, 0.80, 0.20, 1)
		"trigger": return Color(0.40, 0.90, 1.0,  1)
		"economy": return Color(0.40, 1.0,  0.50, 1)
		_:         return Color(0.80, 0.80, 0.80, 1)


func _lbl(txt: String, parent: Control, size: int = 14) -> Label:
	var l := Label.new()
	l.text = txt
	l.add_theme_font_size_override("font_size", size)
	parent.add_child(l)
	return l


func _gap_h(parent: Control, w: int) -> void:
	var s := Control.new()
	s.custom_minimum_size = Vector2(w, 0)
	parent.add_child(s)


func _gap_v(parent: Control, h: int) -> void:
	var s := Control.new()
	s.custom_minimum_size = Vector2(0, h)
	parent.add_child(s)
