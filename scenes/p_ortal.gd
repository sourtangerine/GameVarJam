extends Area2D

@export_file("*.tscn") var target_scene: String = "res://scenes/map.tscn"
@export var spawn_position: Vector2 = Vector2.ZERO

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	print("entered by: ", body.name)
	if body.is_in_group("player"):
		print("player detected, changing level")
		get_tree().current_scene.call_deferred("change_level", target_scene, spawn_position)
