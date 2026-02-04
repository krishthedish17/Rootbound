extends CanvasLayer

@onready var label: Label = $HUD
@onready var wave_manager = $"../WaveManager"
@onready var boon_menu = $"../Boon menu"

var wave: int = 1
var boon_levels := {}

func _ready():
	# pull initial state
	wave = wave_manager.wave
	boon_levels = boon_menu.boon_levels

	# listen for updates
	wave_manager.wave_started.connect(_on_wave_started)
	boon_menu.boon_selected.connect(_on_boon_selected)

	_update_text()

func _on_wave_started(new_wave: int) -> void:
	wave = new_wave
	_update_text()

func _on_boon_selected(id: String, lvl: int) -> void:
	boon_levels[id] = lvl
	_update_text()

func _update_text() -> void:
	label.text = _build_text()

func _build_text() -> String:
	var lines: Array[String] = []
	lines.append("Wave: %d" % wave)

	# --- Spray row ---
	var spray_parts: Array[String] = []
	_add_if(spray_parts, "Overgrowth", "spray_damage")
	_add_if(spray_parts, "Rapid Sap", "spray_fire_rate")
	_add_if(spray_parts, "Binding Resin", "spray_slow")
	if spray_parts.size() > 0:
		lines.append("")
		lines.append(" | ".join(spray_parts))

	# --- Sniper row ---
	var sniper_parts: Array[String] = []
	_add_if(sniper_parts, "Piercing Heartwood", "sniper_pierce")
	_add_if(sniper_parts, "Rupture Core", "sniper_explosive")
	_add_if(sniper_parts, "Focused Growth", "sniper_cdr")
	if sniper_parts.size() > 0:
		lines.append(" | ".join(sniper_parts))

	# --- Sanctuary row ---
	var sanc_parts: Array[String] = []
	_add_if(sanc_parts, "Deep Roots", "sanctuary_hp")
	_add_if(sanc_parts, "Living Canopy", "sanctuary_aura")
	if sanc_parts.size() > 0:
		lines.append(" | ".join(sanc_parts))

	return "\n".join(lines)



func _add_if(parts: Array[String], name: String, id: String) -> void:
	var lvl: int = int(boon_levels.get(id, 0))
	if lvl > 0:
		parts.append("%s L%d" % [name, lvl])
