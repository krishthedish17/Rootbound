extends CharacterBody2D


@export var SPEED = 100
@export var damage = 1
@export var slow_level: int = 0

var dir : float
var spawnPos : Vector2
var spawnRot : float
var zdex : int


func _ready():
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
	if enemy != null && enemy.is_in_group("enemies"):
		enemy.take_damage(damage)
		get_tree().call_group("player", "notify_spray_hit")
		if slow_level > 0 and enemy.has_method("apply_slow"):
			enemy.apply_slow(slow_level)
	
	
	
	queue_free()
