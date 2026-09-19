extends Node

var current_creature_id := ""
var current_level := 1
var return_scene_path := ""
var return_position := Vector2.ZERO
var battle_active := false

func start_battle(creature_id: String, level: int) -> void:
	if battle_active:
		return
	battle_active = true

	current_creature_id = creature_id
	current_level = level

	var tree := get_tree()
	return_scene_path = tree.current_scene.scene_file_path
	return_position = tree.get_first_node_in_group("player").global_position

	await get_tree().create_timer(0.6).timeout   # placeholder for a flash/fade effect
	tree.change_scene_to_file("res://scenes/src/battle.tscn")

func end_battle() -> void:
	get_tree().change_scene_to_file(return_scene_path)
	await get_tree().process_frame
	await get_tree().process_frame
	get_tree().get_first_node_in_group("player").global_position = return_position
	battle_active = false
