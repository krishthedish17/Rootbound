extends Node2D

@onready var player = $Player
@onready var boon_menu = $"Boon menu"
@onready var sanctuary = $sanctuary
@onready var wave_manager = $WaveManager

func _ready() -> void:
	boon_menu.boon_selected.connect(player._on_boon_selected)
	boon_menu.boon_selected.connect(sanctuary._on_boon_selected)

func get_data() -> Dictionary:
	return {
		"wave_reached": wave_manager.wave
	}
