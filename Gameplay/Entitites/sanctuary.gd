extends StaticBody2D

@onready var health_text: Label = $Label
@onready var aura_area: Area2D = $aura # <-- rename your Area2D to AuraArea, or change path
@onready var aura_ring: Line2D = $AuraRing

@export var aura_base_radius: float = 60.0
@export var aura_per_level: float = 12.0


signal core_destroyed

var max_hp: int = 100
var hp: int = 100
var dead: bool = false


# Sanctuary boons
var aura_level: int = 1
var aura_mode: String = "slow"  # "slow" or "zap"

# Timers for aura
var aura_timer: Timer
var zap_timer: Timer

func _ready() -> void:
	dead = false
	hp = max_hp
	_update_label()

	# Aura tick (slow pulse)
	aura_timer = Timer.new()
	aura_timer.wait_time = 0.40
	aura_timer.one_shot = false
	aura_timer.timeout.connect(_pulse_aura)
	add_child(aura_timer)
	aura_timer.start()

	# Zap tick (less frequent)
	zap_timer = Timer.new()
	zap_timer.wait_time = 0.90
	zap_timer.one_shot = false
	zap_timer.timeout.connect(_pulse_zap)
	add_child(zap_timer)
	zap_timer.start()

func _update_label() -> void:
	health_text.text = "HEALTH: " + str(hp)
	$ProgressBar.value = hp

func take_damage(amount: int) -> void:
	SFX.play("sancHit")
	if dead:
		return
	hp -= amount
	_update_label()
	if hp <= 0:
		die()

func set_aura_level(lvl: int) -> void:
	aura_level = lvl
	_update_aura_visual()

func _update_aura_visual() -> void:
	if aura_ring == null:
		return
	
	var r: float = aura_base_radius + aura_per_level * float(aura_level)

	var pts: Array[Vector2] = []
	var segments := 32
	for i in range(segments):
		var t := TAU * float(i) / float(segments)
		pts.append(Vector2(cos(t), sin(t)) * r)

	aura_ring.points = pts
	aura_ring.visible = aura_level > 0


func die() -> void:
	if dead:
		return
	dead = true
	emit_signal("core_destroyed")
	print("game over")

# --- BOON HANDLER (connect BoonMenu.boon_selected to this) ---
func _on_boon_selected(id: String, lvl: int) -> void:
	match id:
		"sanctuary_hp":
			# +20 max HP per level, plus a small heal so it feels good
			max_hp = 100 + lvl * 20
			hp = min(hp + 20, max_hp)
			_update_label()

		"sanctuary_aura":
			aura_level = lvl

# Called by player style tracker (optional)
func set_style(prefers: String) -> void:
	# If player is mostly spraying, sanctuary damages enemies to help clear.
	# If player is mostly sniping, sanctuary slows to buy time.
	aura_mode = "zap" if prefers == "spray" else "slow"

# --- AURA EFFECTS ---
func _pulse_aura() -> void:
	if dead or aura_level <= 0:
		return
	if aura_mode != "slow":
		return

	# Apply slow to enemies inside aura
	for a in aura_area.get_overlapping_areas():
		var enemy = a.get_parent()
		if enemy != null and enemy.is_in_group("enemies") and enemy.has_method("apply_slow"):
			enemy.apply_slow(aura_level)

func _pulse_zap() -> void:
	if dead or aura_level <= 0:
		return
	if aura_mode != "zap":
		return

	# Pick a random enemy in aura and chip it
	var enemies: Array = []
	for a in aura_area.get_overlapping_areas():
		var enemy = a.get_parent()
		if enemy != null and enemy.is_in_group("enemies"):
			enemies.append(enemy)

	if enemies.is_empty():
		return

	var target = enemies[randi() % enemies.size()]
	if target.has_method("take_damage"):
		target.take_damage(1 + aura_level)  # tune

# --- Your existing “enemy hits core and dies” logic ---
func _on_sanctuary_entered(area: Area2D) -> void:
	if dead:
		return
	if not area.is_in_group("core_detector"):
		return

	var enemy := area.get_parent()
	if enemy != null and enemy.is_in_group("enemies"):
		take_damage(enemy.core_damage)
		enemy.get_parent().queue_free()
