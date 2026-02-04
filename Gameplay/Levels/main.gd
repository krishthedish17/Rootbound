extends Node

func _ready():
	swap_to(SceneRegistry.main_scenes["StartScreen"], "no_transition")

func swap_to(path: String, transition := "fade_to_black"):
	var game_root := $GameRoot
	var old_scene: Node = null
	if game_root.get_child_count() > 0:
		old_scene = game_root.get_child(0)
	SceneManager.swap_scenes(path, game_root, old_scene, transition)
