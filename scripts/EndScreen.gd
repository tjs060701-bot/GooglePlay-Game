## EndScreen — Phase 1 placeholder. Full UI built alongside ShopScene.
extends Node2D


func _ready() -> void:
	var stats: Dictionary = GameManager.last_run_stats
	print("[EndScreen] Run over. Won: %s | Damage: %d | Gold: %d" % [
		stats.get("won", false),
		stats.get("damage_dealt", 0),
		stats.get("gold", 0),
	])


# Called by "Restart" button.
func restart() -> void:
	GameManager.restart_run()
