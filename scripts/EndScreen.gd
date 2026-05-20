## EndScreen — shows run summary and a Restart button.
extends Node2D


func _ready() -> void:
	var cl   := CanvasLayer.new()
	add_child(cl)

	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	cl.add_child(root)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(vbox)

	var stats := GameManager.last_run_stats
	var won: bool = stats.get("won", false)

	var title := Label.new()
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 48)
	title.add_theme_color_override("font_color",
		Color(0.3, 1.0, 0.4, 1) if won else Color(1.0, 0.3, 0.3, 1))
	title.text = "VICTORY!" if won else "DEFEATED"
	vbox.add_child(title)

	_gap(vbox, 24)

	var body_lines := [
		"Ante reached:   %d"  % stats.get("ante_reached", 1),
		"Gold remaining: %d"  % stats.get("gold", 0),
		"Damage dealt:   %d"  % stats.get("damage_dealt", 0),
		"Runes used:     %s"  % ", ".join(stats.get("runes_used", [])),
	]
	for line in body_lines:
		var lbl := Label.new()
		lbl.text = line
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.add_theme_font_size_override("font_size", 20)
		vbox.add_child(lbl)

	_gap(vbox, 32)

	var btn := Button.new()
	btn.text = "Restart"
	btn.custom_minimum_size = Vector2(200, 56)
	btn.add_theme_font_size_override("font_size", 22)
	btn.pressed.connect(func(): GameManager.restart_run())

	var btn_container := CenterContainer.new()
	btn_container.add_child(btn)
	vbox.add_child(btn_container)


func _gap(parent: Control, h: int) -> void:
	var s := Control.new()
	s.custom_minimum_size = Vector2(0, h)
	parent.add_child(s)
