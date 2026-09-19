# player.gd
extends CharacterBody2D

signal stepped

const STEP_DISTANCE := 16.0   # pixels per "step"
var _distance_accum := 0.0

func _ready() -> void:
	add_to_group("player")

func _physics_process(delta: float) -> void:
	var dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	velocity = dir * 80.0
	var before := global_position
	move_and_slide()

	_distance_accum += global_position.distance_to(before)
	if _distance_accum >= STEP_DISTANCE:
		_distance_accum -= STEP_DISTANCE
		stepped.emit()
