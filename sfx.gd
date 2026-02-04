extends Node

@export var library := {
	"shoot": preload("res://Gameplay/Audio/mixkit-twig-breaking-2945.wav"),
	"hit": preload("res://Gameplay/Audio/mixkit-tree-branch-brake-2943.wav"),
	"sancHit": preload("res://Gameplay/Audio/mixkit-wood-hard-hit-2182.wav")
}

@export var offsets := {
	"door": 1.0
}



@onready var players: Array[AudioStreamPlayer2D] = [
	$P0, $P1, $P2
]

var _idx := 0

func play(name: String, volume_db: float = 0.0, pitch: float = 1.0) -> void:
	var stream: AudioStream = library.get(name)
	if stream == null:
		push_warning("SFX missing: %s" % name)
		return

	var p := players[_idx]
	_idx = (_idx + 1) % players.size()

	p.stream = stream
	p.volume_db = volume_db
	p.pitch_scale = pitch
	p.play(offsets.get(name, 0.0))
