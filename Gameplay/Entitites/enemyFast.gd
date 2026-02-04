extends CharacterBody2D

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

@export var sanctuary: Node2D
@export var base_hp: int = 1

var speed := 200.0
var hp := 1
var core_damage := 3
var amount = 1
var slow_stacks: int = 0

func _ready() -> void:
	hp = base_hp

func _process(delta):
	if sanctuary == null:
		return

	sprite.scale.x = 6 if global_position.x > sanctuary.global_position.x else -6


func apply_slow(stacks_to_add: int) -> void:
	slow_stacks = min(slow_stacks + stacks_to_add, 10)
	_update_slow_visual()

func _update_slow_visual():
	if slow_stacks > 0:
		sprite.modulate = Color(0.6, 0.7, 1.0)
	else:
		sprite.modulate = Color(1.0, 1.0, 1.0)

func _physics_process(delta):
	if sanctuary == null:
		return
		
	var slow_factor := 1.0 - 0.06 * slow_stacks
	slow_factor = max(0.35, slow_factor)
	
	var dir: float = 1.0 if sanctuary.global_position.x > global_position.x else -1.0
	velocity.x = dir * speed * slow_factor
	move_and_slide()



func take_damage(amount : int):
	SFX.play("hit")
	hp -= amount
	if hp <= 0:
		die()

func die():
	get_parent().queue_free()


func _on_sanctuary_entered(area: Area2D) -> void:
	pass


func _on_hit(area: Area2D) -> void:
	pass # Replace with function body.
