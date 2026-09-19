extends Area2D

@export var encounter_chance := 1.0   # 0.1 = 10% per step
@export var entries: Array[EncounterEntry] = []


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		body.stepped.connect(_on_player_stepped)

func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player") and body.stepped.is_connected(_on_player_stepped):
		body.stepped.disconnect(_on_player_stepped)

func _on_player_stepped() -> void:
	if entries.is_empty() or randf() > encounter_chance:
		return
	var entry := _pick_weighted()
	var level := randi_range(entry.min_level, entry.max_level)
	EncounterManager.start_battle(entry.creature_id, level)

func _pick_weighted() -> EncounterEntry:
	var total := 0
	for e in entries:
		total += e.weight
	var roll := randi_range(1, total)
	for e in entries:
		roll -= e.weight
		if roll <= 0:
			return e
	return entries[0]
