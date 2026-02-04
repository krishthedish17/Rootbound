extends CanvasLayer

@onready var wave_manager = $"../WaveManager"
@onready var b1 = $Control/ColorRect/Button
@onready var b2 = $Control/ColorRect/Button2
@onready var b3 = $Control/ColorRect/Button3

signal boon_done
signal boon_selected(boon_id: String, new_level: int)


var boon_levels := {} # id -> int
var current_offers

const BOONS := [
	{"id":"spray_fire_rate",  "name":"Rapid Sap",           "desc":"Fire rate up (spray)",          "max":8},
	{"id":"spray_damage",     "name":"Overgrowth",          "desc":"Spray damage up (spray)",      "max":8},
	{"id":"spray_slow",       "name":"Binding Resin",       "desc":"Applies slow (spray)",         "max":5},

	{"id":"sniper_cdr",       "name":"Focused Growth",      "desc":"Cooldown down (snipe)",        "max":8},
	{"id":"sniper_pierce",    "name":"Piercing Heartwood",  "desc":"Pierce up (snipe)",            "max":6},
	{"id":"sniper_explosive", "name":"Rupture Core",        "desc":"Explosive splash (snipe)",     "max":5},

	{"id":"sanctuary_hp",     "name":"Deep Roots",          "desc":"Sanctuary max HP up (base)",  "max":8},
	{"id":"sanctuary_aura",   "name":"Living Canopy",       "desc":"Aura strength up (base)",     "max":6},
]


func get_level(id: String) -> int:
	return int(boon_levels.get(id, 0))

func is_maxed(id: String) -> bool:
	var def = _get_def(id)
	return get_level(id) >= int(def["max"])

func _get_def(id: String) -> Dictionary:
	for b in BOONS:
		if b["id"] == id:
			return b
	return {}


func roll_offers() -> Array:
	var pool: Array = []
	for b in BOONS:
		if not is_maxed(b["id"]):
			pool.append(b)

	pool.shuffle()

	# Basic “anti-stupid”: don’t allow 3 sanctuary-only offers
	var tries := 12
	while tries > 0:
		tries -= 1
		var picks := []
		for b in pool:
			picks.append(b)
			if picks.size() == 3:
				break

		if _offers_ok(picks):
			return picks.map(func(x): return x["id"])

		pool.shuffle()

	# fallback
	return pool.slice(0, 3).map(func(x): return x["id"])

func _offers_ok(picks: Array) -> bool:
	var sanc := 0
	var playerish := 0
	for d in picks:
		var id := String(d["id"])
		if String(d["id"]).begins_with("sanctuary_"):
			sanc += 1
		else:
			playerish += 1
	if sanc == 3:
		return false
	if playerish == 0:
		return false
	return true



func _ready() -> void:
	wave_manager.wave_over.connect(_displayBoon)
	visible = false

	

func _displayBoon():
	visible = true
	current_offers = roll_offers()
	
	if current_offers.size() < 3:
		while current_offers.size() < 3:
			current_offers.append(current_offers[0])

	b1.text = display_text(current_offers[0])
	b2.text = display_text(current_offers[1])
	b3.text = display_text(current_offers[2])

	get_tree().paused = true

func display_text(id: String) -> String:
	var def := _get_def(id)
	var lvl := get_level(id)
	return "%s (%s)  Lv %d→%d" % [def["name"], def["desc"], lvl, lvl + 1]


func pick_offer(index: int) -> void:
	var id: String = current_offers[index]
	if is_maxed(id):
		return

	var new_level := get_level(id) + 1
	boon_levels[id] = new_level

	boon_selected.emit(id, new_level) # <- this is your “parameter”
	
	visible = false
	get_tree().paused = false




func _on_boon_1() -> void:
	emit_signal("boon_done")
	pick_offer(0)
	 


func _on_boon_2() -> void:
	emit_signal("boon_done")
	pick_offer(1)
	


func _on_boon_3() -> void:
	emit_signal("boon_done")
	pick_offer(2)
