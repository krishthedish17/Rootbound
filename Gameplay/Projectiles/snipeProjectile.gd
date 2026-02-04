extends CharacterBody2D


@onready var explosion_fx = preload("res://Gameplay/Projectiles/explosion_fx.tscn")

@export var SPEED = 400
@export var pierce = 1
@export var explosive_level: int = 0
@export var pierce_falloff: float = 0.7


var dir : float
var spawnPos : Vector2
var spawnRot : float
var zdex : int
var damage = 15
var hit_set := {}
var explosion_count = 0
var hit_ids := {}

func _ready():
	collision_layer = 0
	collision_mask = 0
	global_position = spawnPos
	global_rotation = spawnRot
	z_index = zdex
	
func _physics_process(delta: float) -> void:
	velocity = Vector2(0, -SPEED).rotated(dir)
	move_and_slide()





func _on_life_timeout() -> void:
	queue_free()


func _on_bullet_hit(area: Area2D) -> void:
	var enemy := area.get_parent()
	if enemy == null or not enemy.is_in_group("enemies"):
		return

	# Prevent double-triggering the same enemy (enter/exit, multiple shapes)
	var eid := enemy.get_instance_id()
	if hit_set.has(eid) or hit_ids.has(eid):
		return
	hit_set[eid] = true
	hit_ids[eid] = true
	
	# Direct hit
	enemy.take_damage(damage)

	# Always consumes 1 pierce per enemy hit
	pierce -= 1
	global_position += Vector2(0, -1).rotated(dir) * 6.0
	damage *= pierce_falloff

	# Explosive splash: multi-explode, but nerfed
	if explosive_level > 0:
		explosion_count += 1

		# --- falloff so chain explosions don't delete waves ---
		var mult: float = 1.0
		if explosion_count == 2:
			mult = 0.6
		elif explosion_count == 3:
			mult = 0.35
		elif explosion_count >= 4:
			mult = 0.2

		var splash_damage: int = damage / 2

		_do_explosion(enemy.global_position, splash_damage, enemy)

		# explosions optionally cost extra pierce (tune)
		# If pierce feels TOO high, turn this ON.

	if pierce <= 0 or damage < 1.0:
		queue_free()


func _do_explosion(center: Vector2, splash_damage: int, primary: Node) -> void:
	var radius: float = 96.0 + 12.0 * float(explosive_level)

	# damage enemies in radius
	for e in get_tree().get_nodes_in_group("enemies"):
		if e == null:
			continue
		if not (e is Node2D):
			continue
		
		# Skip the primary target so you don't double-dip
		if e == primary:
			continue

		var dist: float = (e as Node2D).global_position.distance_to(center)
		if dist <= radius:
			if e.has_method("take_damage"):
				e.take_damage(splash_damage)
				

	# VFX (always spawn, even if no one else is hit)
	var fx = explosion_fx.instantiate()
	get_tree().current_scene.add_child(fx)
	var scale_mult: float = radius / 64.0
	fx.play_at(center, scale_mult)
