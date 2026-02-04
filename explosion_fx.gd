extends Node2D

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

func play_at(pos: Vector2, scale_mult: float = 1.0) -> void:
	global_position = pos
	scale = Vector2.ONE * scale_mult
	anim.play("boom")

func _ready() -> void:
	# if you forget to call play_at, still won't hang around
	if not anim.is_playing():
		anim.play("boom")

func _on_anim_animation_finished() -> void:
	queue_free()
