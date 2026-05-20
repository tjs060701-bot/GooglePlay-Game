## ShopScene — browse 3 offered runes, manage equipped runes, proceed to next blind.
extends Node2D

const RUNE_SCRIPTS: Array[String] = [
	"res://scripts/runes/OddStrike.gd",
	"res://scripts/runes/SixSurge.gd",
	"res://scripts/runes/GlassDie.gd",
	"res://scripts/runes/TripleTrigger.gd",
	"res://scripts/runes/HighTide.gd",
	"res://scripts/runes/GoldVein.gd",
]
const SHOP_COST  := 3
const SELL_PRICE := 1

# 3 rune instances offered this visit; null = already purchased.
var _offered: Array = []

# UI references
var _lbl_hp:    Label
var _lbl_gold:  Label
var _lbl_next:  Label
var _shop_hbox: HBoxContainer
var _equip_hbox: HBoxContainer
var _lbl_equip_header: Label


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
	_gap_v(outer, 8)

	# Shop section header
	var shop_title := _lbl("— SHOP —", outer, 24)
	shop_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	_gap_v(outer, 6)

	# Shop cards row
	var shop_center := CenterContainer.new()
	shop_center.custom_minimum_size = Vector2(0, 190)
	outer.add_child(shop_center)

	_shop_hbox = HBoxContainer.new()
	_shop_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	shop_center.add_child(_shop_hbox)

	_gap_v(outer, 10)

	# Equipped runes header (updated dynamically)
	_lbl_equip_header = _lbl("— EQUIPPED RUNES  0 / 5 —", outer, 20)
	_lbl_equip_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	_gap_v(outer, 6)

	# Equip slots row
	var equip_center := CenterContainer.new()
	equip_center.custom_minimum_size = Vector2(0, 120)
	equip_center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	outer.add_child(equip_center)

	_equip_hbox = HBoxContainer.new()
	_equip_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	equip_center.add_child(_equip_hbox)

	_gap_v(outer, 12)
	_build_footer(outer)
	_gap_v(outer, 12)


func _build_top_bar(parent: Control) -> void:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, 64)
	parent.add_child(panel)

	var hbox := HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(hbox)

	_lbl_hp   = _lbl("HP  3 / 3", hbox, 15)
	_gap_h(hbox, 28)
	_lbl_gold = _lbl("Gold  5",   hbox, 15)
	_gap_h(hbox, 48)
	_lbl_next = _lbl("Next: Big Blind  —  Ante 1  (need 175)", hbox, 16)


func _build_footer(parent: Control) -> void:
	var hbox := HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	parent.add_child(hbox)

	var btn := Button.new()
	btn.text = "Proceed to Next Blind"
	btn.custom_minimum_size = Vector2(280, 64)
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

	var equipped_count := GameManager.equipped_runes.size()
	_lbl_equip_header.text = "— EQUIPPED RUNES  %d / %d —" % [
		equipped_count, GameManager.MAX_RUNES
	]

	_rebuild_shop_cards()
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
	panel.custom_minimum_size = Vector2(190, 170)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(vbox)

	if rune == null:
		_gap_v(vbox, 28)
		var sold := _lbl("[ SOLD ]", vbox, 18)
		sold.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		sold.add_theme_color_override("font_color", Color(0.45, 0.45, 0.45, 1))
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
	btn.custom_minimum_size = Vector2(150, 34)
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
	panel.custom_minimum_size = Vector2(130, 100)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(vbox)

	if slot_idx >= GameManager.equipped_runes.size():
		_gap_v(vbox, 16)
		var empty := _lbl("[ empty ]", vbox, 13)
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty.add_theme_color_override("font_color", Color(0.38, 0.38, 0.38, 1))
		return panel

	var rune = GameManager.equipped_runes[slot_idx]

	var name_lbl := _lbl(rune.rune_name, vbox, 14)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.autowrap_mode        = TextServer.AUTOWRAP_WORD_SMART

	_gap_v(vbox, 3)

	var type_lbl := _lbl("[%s]" % rune.rune_type.to_upper(), vbox, 10)
	type_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	type_lbl.add_theme_color_override("font_color", _type_color(rune.rune_type))

	_gap_v(vbox, 6)

	var btn := Button.new()
	btn.text = "Sell  (1g)"
	btn.custom_minimum_size = Vector2(110, 28)
	btn.add_theme_font_size_override("font_size", 12)
	btn.pressed.connect(func(): _sell_rune(slot_idx))
	var btn_c := CenterContainer.new()
	btn_c.add_child(btn)
	vbox.add_child(btn_c)

	return panel


func _sell_rune(slot_idx: int) -> void:
	GameManager.sell_rune(slot_idx)
	# sell_rune → add_gold(1) → state_changed → _refresh_ui


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
