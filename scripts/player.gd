extends CharacterBody2D

signal stepped

const SPEED = 300.0
const STEP_DISTANCE := 48.0   # pixels walked per "step"

var last_direction: Vector2 = Vector2.RIGHT
var _distance_accum := 0.0
var _last_pos := Vector2.ZERO

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	add_to_group("player")
	_last_pos = global_position


func _physics_process(delta: float) -> void:
	process_movement()
	move_and_slide()
	track_steps()


func track_steps() -> void:
	_distance_accum += global_position.distance_to(_last_pos)
	_last_pos = global_position
	if _distance_accum >= STEP_DISTANCE:
		_distance_accum -= STEP_DISTANCE
		stepped.emit()


func process_movement() -> void:
	var direction := Input.get_vector("left", "right", "up", "down")
	
	if direction != Vector2.ZERO:
		velocity = direction * SPEED
		last_direction = direction
	else:
		velocity = Vector2.ZERO
	
	process_animation(last_direction)

func process_animation(direction) -> void:
	if velocity != Vector2.ZERO:
		play_animation("run", direction)
	else:
		play_animation("idle", direction)
	

func play_animation(prefix: String, dir: Vector2) -> void:
	if dir.x != 0:
		animated_sprite_2d.flip_h = dir.x < 0
		animated_sprite_2d.play(prefix + "_right")
	elif dir.y < 0:
		animated_sprite_2d.play(prefix + "_up")
	elif dir.y > 0:
		animated_sprite_2d.play(prefix + "_down")
