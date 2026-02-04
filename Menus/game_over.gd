extends Node2D

@onready var label = $Label/Label2

var wave_reached: int = 0


func _ready():
	label.text = "Wave Reached: %d" % wave_reached

func _unhandled_input(event):
	if event.is_action_pressed("end"):
		go_to_menu()

func receive_data(data: Dictionary) -> void:
	if data.has("wave_reached"):
		wave_reached = int(data["wave_reached"]);
	
func go_to_menu():
		SceneManager.swap_scenes(SceneRegistry.main_scenes["StartScreen"],get_tree().root,get_tree().current_scene,"fade_to_black")

		
  
