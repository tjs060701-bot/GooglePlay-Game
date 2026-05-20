class_name GoldVein
extends Rune

func _init() -> void:
	rune_name = "Gold Vein"
	description = "After combat, gain 1 Gold per 50 damage dealt above the Blind threshold"
	rune_type = "economy"
	cost = 3


func on_combat_end(total_damage: int, blind_threshold: int) -> int:
	var excess := max(0, total_damage - blind_threshold)
	return excess / 50
