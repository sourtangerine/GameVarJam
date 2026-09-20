extends Node2D

@onready var level_root: Node = $LevelRoot
@onready var player: CharacterBody2D = $Player

func change_level(path: String, spawn_pos: Vector2) -> void:
	var packed: PackedScene = load(path)
	if packed == null:
		push_error("Can't load scene: " + path)
		return
	for child in level_root.get_children():
		child.queue_free()
	var level: Node = packed.instantiate()
	level_root.add_child(level)
	var spawn := level.get_node_or_null("SpawnPoint")
	player.global_position = spawn.global_position if spawn else spawn_pos
