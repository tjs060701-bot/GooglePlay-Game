## ShopScene — Phase 1 placeholder. Full UI built in Phase 3.
extends Node2D


func _ready() -> void:
	GameManager.state_changed.connect(_on_state_changed)
	_on_state_changed()


func _on_state_changed() -> void:
	pass


# Called by "Next Blind" button (Phase 3 wires the button).
func proceed() -> void:
	GameManager.proceed_to_combat()
