## MainMenu — title screen with New Run button.
extends Node2D


func _ready() -> void:
	var cl := CanvasLayer.new()
	add_child(cl)

	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	cl.add_child(root)

	# Dark background
	var bg := ColorRect.new()
	bg.color = Color(0.05, 0.06, 0.08, 1.0)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(bg)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(vbox)

	_gap(vbox, 60)

	var title := Label.new()
	title.text = "DICE ROGUE"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 72)
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.25, 1.0))
	vbox.add_child(title)

	_gap(vbox, 12)

	var subtitle := Label.new()
	subtitle.text = "A roguelite of dice and runes"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 20)
	subtitle.add_theme_color_override("font_color", Color(0.70, 0.70, 0.70, 1.0))
	vbox.add_child(subtitle)

	_gap(vbox, 60)

	var btn_new := Button.new()
	btn_new.text = "New Run"
	btn_new.custom_minimum_size = Vector2(240, 70)
	btn_new.add_theme_font_size_override("font_size", 28)
	btn_new.pressed.connect(_on_new_run)
	var c1 := CenterContainer.new()
	c1.add_child(btn_new)
	vbox.add_child(c1)

	_gap(vbox, 24)

	var lbl_info := Label.new()
	lbl_info.text = "3 Antes × 3 Blinds  |  Chips × Mult = Damage  |  Up to 5 Runes"
	lbl_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_info.add_theme_font_size_override("font_size", 14)
	lbl_info.add_theme_color_override("font_color", Color(0.50, 0.50, 0.50, 1.0))
	vbox.add_child(lbl_info)


func _on_new_run() -> void:
	GameManager.restart_run()


func _gap(parent: Control, h: int) -> void:
	var s := Control.new()
	s.custom_minimum_size = Vector2(0, h)
	parent.add_child(s)
