extends Node

@export var runner_scene: PackedScene = preload("res://Gameplay/Entitites/enemy_runner.tscn")
@export var fast_scene: PackedScene = preload("res://Gameplay/Entitites/enemy_fast.tscn")
@export var brute_scene: PackedScene = preload("res://Gameplay/Entitites/enemy_brute.tscn")
@export var sanctuary_path: NodePath
@export var fast_batch: int = 2
@export var runner_batch: int = 2
@export var brute_batch: int = 1
@export var enemy_lane_path: NodePath



@onready var sanctuary: Node2D = get_node(sanctuary_path)
@onready var spawn_timer: Timer = $SpawnTimer
@onready var wave_text = $"../waveText"
@onready var boon_menu = $"../Boon menu"
@onready var enemy_lane: Node2D = get_node(enemy_lane_path)

var wave: int = 0
var alive: int = 0
var game_over = false
signal wave_over
signal wave_started(wave:int)


# how many enemies still need to be spawned this wave
enum EnemyType { FAST, RUNNER, BRUTE }
var to_spawn_runner: int = 0
var to_spawn_fast: int = 0
var to_spawn_brute: int = 0
var spawning: bool = false
var spawn_order: Array[EnemyType] = [
	EnemyType.FAST,
	EnemyType.RUNNER,
	EnemyType.BRUTE
]

var spawn_index: int = 0
var phase_left: int = 0

func _ready() -> void:
	sanctuary.core_destroyed.connect(_on_core_destroyed)
	boon_menu.boon_done.connect(start_next_wave)
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	start_next_wave()

func _on_core_destroyed():
	trigger_game_over()


	
func trigger_game_over():
	if game_over:
		return
	game_over = true
	spawn_timer.stop()
	
	var old_scene: Node = get_tree().current_scene
	
	SceneManager.swap_scenes(SceneRegistry.levels["game_over"],get_tree().root,old_scene,"fade_to_black")
func start_next_wave() -> void:
	spawn_timer.wait_time *= 0.95
	wave += 1
	wave_started.emit(wave)
	print("Starting wave:", wave)
	wave_text.text = "WAVE " + str(wave)

	# ---- wave composition (tweak later) ----
	to_spawn_runner = 1 + wave * 2
	to_spawn_fast = 0
	to_spawn_brute = 0
	
	if wave >= 5:
		to_spawn_runner = 1 + wave
	if wave >= 10:
		to_spawn_runner = 1 + wave * 2
	if wave >= 20:
		to_spawn_runner = 1 + wave * 3
	
	if wave >= 3:
		to_spawn_fast = wave * 2  # integer division is fine here\
	if wave >= 10:
		to_spawn_fast = wave * 4
	if wave >= 20:
		to_spawn_fast = wave * 8
	
	
	if wave == 5:
		to_spawn_brute = 1
	if wave > 5:
		to_spawn_brute = wave / 3
	if wave > 10:
		to_spawn_brute = wave / 2
	if wave > 20:
		to_spawn_brute = wave
	# ---------------------------------------

	spawning = true
	spawn_timer.start()

func _batch_for(t: EnemyType) -> int:
	match t:
		EnemyType.FAST: return fast_batch
		EnemyType.RUNNER: return runner_batch
		EnemyType.BRUTE: return brute_batch
	return 1


func _remaining_for(t: EnemyType) -> int:
	match t:
		EnemyType.FAST: return to_spawn_fast
		EnemyType.RUNNER: return to_spawn_runner
		EnemyType.BRUTE: return to_spawn_brute
	return 0


func _spawn_one_of(t: EnemyType) -> bool:
	match t:
		EnemyType.FAST:
			if to_spawn_fast <= 0: return false
			_spawn_enemy(fast_scene)
			to_spawn_fast -= 1
			return true

		EnemyType.RUNNER:
			if to_spawn_runner <= 0: return false
			_spawn_enemy(runner_scene)
			to_spawn_runner -= 1
			return true

		EnemyType.BRUTE:
			if to_spawn_brute <= 0: return false
			_spawn_enemy(brute_scene)
			to_spawn_brute -= 1
			return true

	return false


func _on_spawn_timer_timeout() -> void:
	# Try to spawn from current batch
	for _i in range(spawn_order.size()):
		var t: EnemyType = spawn_order[spawn_index]

		# Move to next type if batch done or empty
		if phase_left <= 0 or _remaining_for(t) <= 0:
			spawn_index = (spawn_index + 1) % spawn_order.size()
			phase_left = 0
			continue

		# Spawn one enemy from this batch
		if _spawn_one_of(t):
			phase_left -= 1

			# Batch finished → advance type
			if phase_left <= 0:
				spawn_index = (spawn_index + 1) % spawn_order.size()
			return

	# Start a new batch if needed
	for _i in range(spawn_order.size()):
		var t: EnemyType = spawn_order[spawn_index]
		if _remaining_for(t) > 0:
			phase_left = _batch_for(t)
			return
		spawn_index = (spawn_index + 1) % spawn_order.size()

	# Nothing left to spawn
	spawning = false
	spawn_timer.stop()
	print("no more spawn")
	_check_wave_clear()



func _spawn_enemy(scene: PackedScene) -> void:
	var e = scene.instantiate()
	get_parent().add_child(e)

	var body: CharacterBody2D = e.get_node("CharacterBody2D")
	body.sanctuary = sanctuary
	body.hp = body.base_hp + int(wave * 1.5)

	# X spawn logic (same as you have)
	var side := -1.0 if randf() < 0.5 else 1.0
	var spread := randf_range(-24.0, 24.0)
	var x := sanctuary.global_position.x + side * 450.0 + spread

	# Place enemy roughly at lane height first
	var lane_y := enemy_lane.global_position.y
	e.global_position = Vector2(x, lane_y)

	# ---- FEET SNAP ----
	# IMPORTANT: Feet must be a node under body named "Feet"
	var feet := body.get_node_or_null("Feet") as Node2D
	if feet != null:
		# how far feet are from lane; shift root by that amount
		var dy := lane_y - feet.global_position.y
		e.global_position.y += dy
	# -------------------

	alive += 1
	e.tree_exited.connect(_on_enemy_removed)



func _on_enemy_removed() -> void:
	print("Enemy removed. Alive:", alive)
	alive -= 1
	_check_wave_clear()

func _check_wave_clear() -> void:
	# wave clears only when:
	# 1) we're done spawning AND
	# 2) no enemies left alive
	if (not spawning) and alive <= 0:
		on_wave_cleared()

func on_wave_cleared() -> void:
	print("Wave cleared:", wave)
	# later: show upgrade menu here, then call start_next_wave()
	emit_signal("wave_over")
	
