extends CharacterBody2D

@onready var player = get_parent()
@onready var projectile = load("res://Gameplay/Projectiles/spreadProjectile.tscn")
@onready var snipeProjectile = load("res://Gameplay/Projectiles/snipeProjectile.tscn")
@onready var sprite: AnimatedSprite2D = $sprite
@onready var hitbox: CollisionShape2D = $hitbox
@onready var cooldown: Timer = $Cooldown
@onready var muzzle: Marker2D = $sprite/Muzzle

# Get the movement speed from the inspector
@export var speed : float = 75.0

var proj_rotation : float = PI / 2  # default: facing right
var facing := 1  # 1 = right, -1 = left
var shootCooldown = true
var spray_cooldown = 0.3
var snipe_cooldown = 1.0
var spray_damage_level := 0
var spray_slow_level := 0
var sniper_pierce_level := 0
var sniper_explosive_level := 0
var sniper_cdr_level := 0 # if you want, but cooldown is already a value
var spray_heat := 0.0 
var sniper_base := 15.0
var sniper_damage_buff := 1.5
const SPRAY_HEAT_BUILD := 0.1
const SPRAY_HEAT_DECAY := 1.2
const SPRAY_HEAT_BONUS_MAX := 4
var since_spray_hit := 999.0



func _ready():
	pass

func _on_boon_selected(id: String, lvl: int) -> void:
	match id:
		"spray_fire_rate":
			spray_cooldown = max(0.04, spray_cooldown * 0.90)
		"sniper_cdr":
			snipe_cooldown = max(0.15, snipe_cooldown * 0.88)

		"spray_damage":
			spray_damage_level = lvl
		"spray_slow":
			spray_slow_level = lvl

		"sniper_pierce":
			sniper_pierce_level = lvl + 1
		"sniper_explosive":
			sniper_explosive_level = lvl
	print("BOON", id, " lvl", lvl)


func _physics_process(_delta: float) -> void:
	# Get the input direction using get_vector for smooth diagonal movement
	var direction := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")

	# Update the character's velocity based on direction and speed
	if direction != Vector2.ZERO:
		velocity.x = direction.x * speed
		sprite.play("walk")
	else:
		# Stop movement if no input is detected
		velocity.x = move_toward(velocity.x, 0, speed)
		sprite.play("idle")
	
	
	if velocity.x < 0:
		# Moving left, flip to the left
		sprite.scale.x = -5
		proj_rotation = -PI / 2
		
		# OR: sprite.scale.x = -1 # For Node2D/Parent node
	elif velocity.x > 0:
		# Moving right, flip to the right (default)
		sprite.scale.x = 5
		proj_rotation = PI / 2
		# OR: sprite.scale.x = 1 # For Node2D/Parent node
	# If velocity.x is 0, it keeps its current flip state (facing direction of last movement)
	
	
	# Move the character and handle collisions
	move_and_slide()

func _process(delta: float) -> void:
	var is_spraying = Input.is_action_pressed("shoot")
	
	since_spray_hit *= delta
	var decay = 1.2 if since_spray_hit < 0.25 else 2.5
	
	if is_spraying:
		pass
	else:
		spray_heat = max(0.0, spray_heat - decay * delta)
	
	
	if(Input.is_action_pressed("shoot") && shootCooldown == true):
		shoot()		
	if(Input.is_action_pressed("altshoot") && shootCooldown == true):
		altShoot()
func shoot():
	SFX.play("shoot")
	var instance = projectile.instantiate()
	
	#APPLY SPRAY HEAT
	spray_heat = min(1.0, spray_heat + SPRAY_HEAT_BUILD)
	
	var heat_bonus := int(round(spray_heat * float(SPRAY_HEAT_BONUS_MAX)))
	# --- APPLY SPRAY UPGRADES ---
	# These fields must exist on the spray projectile script (or use set() safely)
	instance.damage = 1 + spray_damage_level * 0.5 + heat_bonus * (0.2 * spray_damage_level)
	instance.slow_level = spray_slow_level
	# ----------------------------

	instance.dir = proj_rotation
	instance.spawnPos = muzzle.global_position
	instance.spawnRot = proj_rotation
	instance.zdex = z_index - 4

	player.add_child.call_deferred(instance)

	shootCooldown = false
	cooldown.wait_time = spray_cooldown
	cooldown.start()

func notify_spray_hit():
	since_spray_hit = 0.0

func altShoot():
	SFX.play("sancHit")
	var instance = snipeProjectile.instantiate()

	# --- APPLY SNIPER UPGRADES ---
	instance.pierce = sniper_pierce_level
	instance.explosive_level = sniper_explosive_level
	instance.damage = sniper_base + sniper_damage_buff * float(sniper_cdr_level)
	
	# ----------------------------

	instance.dir = proj_rotation
	instance.spawnPos = muzzle.global_position
	instance.spawnRot = proj_rotation
	instance.zdex = z_index - 4

	player.add_child.call_deferred(instance)

	shootCooldown = false
	cooldown.wait_time = snipe_cooldown
	cooldown.start()



	


func _on_cooldown_timeout():
	shootCooldown = true


func _on_snipe_cooldown_timeout():
	shootCooldown = true
