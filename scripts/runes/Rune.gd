class_name Rune
extends Resource

@export var rune_name: String = "Unnamed Rune"
@export var description: String = ""
@export_enum("damage", "mult", "trigger", "economy") var rune_type: String = "damage"
@export var cost: int = 3


## Called once when the rune is equipped. Override for equip-time side-effects
## (e.g. GlassDie marking a die in the pool).
func on_equip(gm: Node) -> void:
	pass


## Called each roll resolution pass. Mutates and returns context.
func apply(context: RollContext) -> RollContext:
	return context


## Called once at end of a won combat. Return any gold bonus earned.
func on_combat_end(_total_damage: int, _blind_threshold: int) -> int:
	return 0
