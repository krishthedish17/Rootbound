extends Node2D

@onready var body = $body

func _on_boon_selected(id: String, lvl: int) -> void:
	body._on_boon_selected(id, lvl)
	
func notify_spray_hit():
	body.notify_spray_hit()
