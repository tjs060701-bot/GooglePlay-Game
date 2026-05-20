## EventScene — displays a random encounter with 2 choices; resolves then routes to ShopScene.
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

# UI references
var _hp_lbl:       Label
var _gold_lbl:     Label
var _result_lbl:   Label
var _continue_btn: Button
var _choice_btns:  Array[Button] = []


func _ready() -> void:
	GameManager.state_changed.connect(_on_state_changed)
	var event := _pick_event()
	_build_scene(event)


func _exit_tree() -> void:
	if GameManager.state_changed.is_connected(_on_state_changed):
		GameManager.state_changed.disconnect(_on_state_changed)


func _on_state_changed() -> void:
	if _hp_lbl:
		_hp_lbl.text   = "HP  %d / %d" % [GameManager.player_hp, GameManager.max_player_hp]
	if _gold_lbl:
		_gold_lbl.text = "Gold  %d" % GameManager.gold


# ── Event catalog ──────────────────────────────────────────────────────────────

func _pick_event() -> Dictionary:
	var pool: Array = []
	for ev in _all_events():
		if not ev.has("requires") or (ev["requires"] as Callable).call():
			pool.append(ev)
	if pool.is_empty():
		return _fallback_event()
	pool.shuffle()
	return pool[0]


func _all_events() -> Array:
	# Pre-pick the rune for Merchant Caravan so the player can see what they're buying.
	var scripts := RUNE_SCRIPTS.duplicate()
	scripts.shuffle()
	var caravan_rune = load(scripts[0]).new()

	return [
		{
			"title":  "Lucky Cache",
			"flavor": "You find an abandoned chest half-buried by the roadside.",
			"choices": [
				{
					"text":   "Take the gold  (+4g)",
					"result": "You pocket the gold and move on.",
					"apply":  func(): GameManager.add_gold(4),
				},
				{
					"text":   "Rest here  (+1 HP)",
					"result": "You catch your breath and feel better.",
					"apply":  func(): GameManager.heal(1),
				},
			],
		},
		{
			"title":  "Gambling Den",
			"flavor": "A shifty merchant offers you a high-stakes deal.",
			"choices": [
				{
					"text":   "Take the risk  (−1 HP, +6g)",
					"result": "Worth it. Probably.",
					"apply":  func():
						GameManager.take_damage(1)
						if GameManager.player_hp > 0:
							GameManager.add_gold(6),
				},
				{
					"text":   "Walk away",
					"result": "You leave empty-handed. Boring, but alive.",
					"apply":  func(): pass,
				},
			],
		},
		{
			"title":    "Merchant Caravan",
			"flavor":   "A travelling merchant offers you a rune at a steep discount.",
			"requires": func(): return GameManager.equipped_runes.size() < GameManager.MAX_RUNES,
			"choices":  [
				{
					"text":   "%s  (1g)" % caravan_rune.rune_name,
					"result": "You equip %s." % caravan_rune.rune_name,
					"apply":  func():
						if GameManager.spend_gold(1):
							GameManager.equip_rune(caravan_rune),
				},
				{
					"text":   "Decline",
					"result": "The merchant packs up and leaves.",
					"apply":  func(): pass,
				},
			],
		},
		{
			"title":    "Ancient Forge",
			"flavor":   "A ruined forge still glows. Enough heat for one upgrade.",
			"requires": func(): return GameManager.dice_pool.any(func(d): return d.get("sides", 6) == 6),
			"choices":  [
				{
					"text":   "Upgrade a d6 → d8  (free)",
					"result": "One of your dice shimmers and grows an extra face.",
					"apply":  func(): GameManager.upgrade_die_sides(6, 8),
				},
				{
					"text":   "Take the scrap  (+3g)",
					"result": "You pocket 3 gold from the scrap metal.",
					"apply":  func(): GameManager.add_gold(3),
				},
			],
		},
		{
			"title":  "Healing Spring",
			"flavor": "A clear pool of water offers restoration.",
			"choices": [
				{
					"text":   "Drink deep  (+2 HP)",
					"result": "You feel your wounds close.",
					"apply":  func(): GameManager.heal(2),
				},
				{
					"text":   "Fill your coinpurse  (+2g)",
					"result": "You scoop out a lucky coin.",
					"apply":  func(): GameManager.add_gold(2),
				},
			],
		},
		{
			"title":    "Cursed Shrine",
			"flavor":   "A strange altar hums with unstable energy. Touch it, and one die changes forever.",
			"requires": func(): return GameManager.dice_pool.any(func(d): return not d.get("is_glass", false)),
			"choices":  [
				{
					"text":   "Infuse a die  (Glass, free)",
					"result": "One die becomes Glass: lethal highs, lethal lows.",
					"apply":  func():
						for i in range(GameManager.dice_pool.size()):
							if not GameManager.dice_pool[i].get("is_glass", false):
								GameManager.mark_die_as_glass(i)
								break,
				},
				{
					"text":   "Take the offering  (+2g)",
					"result": "You snatch a coin from the altar and run.",
					"apply":  func(): GameManager.add_gold(2),
				},
			],
		},
		{
			"title":  "Tax Collector",
			"flavor": "A collector blocks your path. There is no free pass today.",
			"choices": [
				{
					"text":   "Pay the toll  (up to −2g)",
					"result": "You grudgingly hand over the coin.",
					"apply":  func(): GameManager.spend_gold(mini(2, GameManager.gold)),
				},
				{
					"text":   "Force through  (−1 HP)",
					"result": "They land a blow before you slip past.",
					"apply":  func(): GameManager.take_damage(1),
				},
			],
		},
		{
			"title":  "Windfall",
			"flavor": "You find a heavy coinpurse on the road. No one is around.",
			"choices": [
				{
					"text":   "Pocket it  (+5g)",
					"result": "Not bad. Not bad at all.",
					"apply":  func(): GameManager.add_gold(5),
				},
				{
					"text":   "Leave it  (nothing)",
					"result": "You walk past. Very noble.",
					"apply":  func(): pass,
				},
			],
		},
	]


func _fallback_event() -> Dictionary:
	return {
		"title":  "Quiet Road",
		"flavor": "Nothing unusual happens. You press on.",
		"choices": [
			{
				"text":   "Keep moving  (+2g)",
				"result": "A little gold for your troubles.",
				"apply":  func(): GameManager.add_gold(2),
			},
		],
	}


# ── Scene construction ─────────────────────────────────────────────────────────

func _build_scene(event: Dictionary) -> void:
	var cl := CanvasLayer.new()
	add_child(cl)

	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	cl.add_child(root)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(vbox)

	_build_status_bar(vbox)
	_gap(vbox, 28)

	var title := Label.new()
	title.text = event["title"]
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 40)
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.25, 1.0))
	vbox.add_child(title)

	_gap(vbox, 10)

	var flavor := Label.new()
	flavor.text = event["flavor"]
	flavor.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	flavor.add_theme_font_size_override("font_size", 16)
	flavor.add_theme_color_override("font_color", Color(0.72, 0.72, 0.72, 1.0))
	vbox.add_child(flavor)

	_gap(vbox, 36)

	var choices: Array = event["choices"]
	var choice_row := HBoxContainer.new()
	choice_row.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(choice_row)

	for i in range(choices.size()):
		var card := _make_choice_card(choices[i])
		choice_row.add_child(card)
		if i < choices.size() - 1:
			_gap_h(choice_row, 28)

	_gap(vbox, 28)

	_result_lbl = Label.new()
	_result_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_result_lbl.add_theme_font_size_override("font_size", 18)
	_result_lbl.add_theme_color_override("font_color", Color(0.55, 1.0, 0.60, 1.0))
	_result_lbl.visible = false
	vbox.add_child(_result_lbl)

	_gap(vbox, 14)

	var cont_c := CenterContainer.new()
	vbox.add_child(cont_c)

	_continue_btn = Button.new()
	_continue_btn.text = "Head to Shop"
	_continue_btn.custom_minimum_size = Vector2(220, 56)
	_continue_btn.add_theme_font_size_override("font_size", 20)
	_continue_btn.visible = false
	_continue_btn.pressed.connect(func(): GameManager.proceed_to_shop())
	cont_c.add_child(_continue_btn)


func _make_choice_card(choice: Dictionary) -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(230, 130)

	var inner := VBoxContainer.new()
	inner.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(inner)

	var lbl := Label.new()
	lbl.text = choice["text"]
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.add_theme_font_size_override("font_size", 15)
	inner.add_child(lbl)

	_gap(inner, 12)

	var btn := Button.new()
	btn.text = "Choose"
	btn.custom_minimum_size = Vector2(170, 38)
	btn.add_theme_font_size_override("font_size", 16)
	btn.pressed.connect(func(): _on_choice(choice["apply"], choice.get("result", "")))
	inner.add_child(btn)

	_choice_btns.append(btn)
	return panel


func _build_status_bar(parent: Control) -> void:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, 56)
	parent.add_child(panel)

	var hbox := HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(hbox)

	_hp_lbl = Label.new()
	_hp_lbl.add_theme_font_size_override("font_size", 15)
	hbox.add_child(_hp_lbl)

	_gap_h(hbox, 40)

	_gold_lbl = Label.new()
	_gold_lbl.add_theme_font_size_override("font_size", 15)
	hbox.add_child(_gold_lbl)

	_on_state_changed()  # populate initial values


# ── Choice resolution ──────────────────────────────────────────────────────────

func _on_choice(apply_fn: Callable, result_text: String) -> void:
	apply_fn.call()
	for b in _choice_btns:
		b.disabled = true
	if result_text:
		_result_lbl.text = result_text
		_result_lbl.visible = true
	_continue_btn.visible = true


# ── Helpers ────────────────────────────────────────────────────────────────────

func _gap(parent: Control, h: int) -> void:
	var s := Control.new()
	s.custom_minimum_size = Vector2(0, h)
	parent.add_child(s)


func _gap_h(parent: Control, w: int) -> void:
	var s := Control.new()
	s.custom_minimum_size = Vector2(w, 0)
	parent.add_child(s)
