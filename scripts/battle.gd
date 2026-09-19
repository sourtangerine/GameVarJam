extends Node
# Attach to the root "Battle" node.

enum State { PLAYER_TURN, ENEMY_TURN, WON, LOST, ESCAPED }

@export var player_max_hp := 10
@export var enemy_max_hp := 50
@export var player_damage := Vector2i(5, 10)   # min, max
@export var enemy_damage := Vector2i(1, 3)
@export var item_heal := 4
@export var items_left := 2
@export var run_chance := 1.0

var state := State.PLAYER_TURN
var player_hp := 0
var enemy_hp := 0
var reflect_next_hit := false   # set by ReverseButton

@onready var enemy: Node = $VBoxContainer/Enemy
@onready var enemy_bar: ProgressBar = $VBoxContainer/EnemyHealthBar
@onready var enemy_label: Label = $VBoxContainer/EnemyHealthBar/EnemyHP

@onready var player: Node = $PlayerPanel/Player
@onready var attack_anim: Node = $PlayerPanel/Player/AttackAnimation
@onready var player_bar: ProgressBar = $PlayerPanel/PlayerHealthBar
@onready var player_label: Label = $PlayerPanel/PlayerHealthBar/PlayerHP

@onready var attack_button: Button = $PlayerPanel/AttackButton
@onready var item_button: Button = $PlayerPanel/ItemButton
@onready var run_button: Button = $PlayerPanel/RunButton
@onready var reverse_button: Button = $PlayerPanel/ReverseButton

@onready var buttons: Array[Button] = [attack_button, item_button, run_button, reverse_button]

const CREATURE_HP := {
	"skull": 50,
	"bat": 20,
}

func _ready() -> void:
	enemy_max_hp = CREATURE_HP.get(EncounterManager.current_creature_id, enemy_max_hp)
	player_hp = player_max_hp
	enemy_hp = enemy_max_hp

	for bar in [enemy_bar, player_bar]:
		bar.show_percentage = false   # labels draw "HP: x / y" instead
	enemy_bar.max_value = enemy_max_hp
	player_bar.max_value = player_max_hp

	attack_button.pressed.connect(_on_attack)
	item_button.pressed.connect(_on_item)
	run_button.pressed.connect(_on_run)
	reverse_button.pressed.connect(_on_reverse)

	_update_ui()
	_start_player_turn()


# ---------- turn flow ----------

func _start_player_turn() -> void:
	state = State.PLAYER_TURN
	_set_buttons_enabled(true)
	item_button.disabled = items_left <= 0


func _end_player_turn() -> void:
	if enemy_hp <= 0:
		_end_battle(State.WON)
		return
	await _enemy_turn()


func _enemy_turn() -> void:
	state = State.ENEMY_TURN
	_set_buttons_enabled(false)
	await get_tree().create_timer(0.8).timeout

	var dmg := randi_range(enemy_damage.x, enemy_damage.y)
	if reflect_next_hit:
		reflect_next_hit = false
		await _flash(enemy)
		enemy_hp = max(0, enemy_hp - dmg)
		print("Reflected %d damage!" % dmg)
	else:
		await _flash(player)
		player_hp = max(0, player_hp - dmg)
	_update_ui()

	if enemy_hp <= 0:
		_end_battle(State.WON)
	elif player_hp <= 0:
		_end_battle(State.LOST)
	else:
		_start_player_turn()


func _end_battle(result: State) -> void:
	state = result
	_set_buttons_enabled(false)
	match result:
		State.WON: print("You won!")
		State.LOST: print("You lost...")
		State.ESCAPED: print("Got away safely.")

	await get_tree().create_timer(1.0).timeout   # short pause so the player sees the result
	EncounterManager.end_battle()


# ---------- player actions ----------

func _on_attack() -> void:
	if state != State.PLAYER_TURN:
		return
	_set_buttons_enabled(false)
	await _play_attack_animation()
	await _flash(enemy)
	enemy_hp = max(0, enemy_hp - randi_range(player_damage.x, player_damage.y))
	_update_ui()
	_end_player_turn()


func _on_item() -> void:
	if state != State.PLAYER_TURN or items_left <= 0:
		return
	_set_buttons_enabled(false)
	items_left -= 1
	player_hp = min(player_max_hp, player_hp + item_heal)
	_update_ui()
	await get_tree().create_timer(0.4).timeout
	_end_player_turn()


func _on_run() -> void:
	if state != State.PLAYER_TURN:
		return
	_set_buttons_enabled(false)
	if randf() < run_chance:
		_end_battle(State.ESCAPED)
	else:
		print("Couldn't escape!")
		await _enemy_turn()


# Placeholder: reflects the enemy's next hit back at it.
# Change this to whatever "Reverse" is supposed to do.
func _on_reverse() -> void:
	if state != State.PLAYER_TURN:
		return
	_set_buttons_enabled(false)
	reflect_next_hit = true
	await get_tree().create_timer(0.4).timeout
	await _enemy_turn()


# ---------- helpers ----------

func _set_buttons_enabled(enabled: bool) -> void:
	for b in buttons:
		b.disabled = not enabled


func _update_ui() -> void:
	enemy_bar.value = enemy_hp
	enemy_label.text = "HP: %d / %d" % [enemy_hp, enemy_max_hp]
	player_bar.value = player_hp
	player_label.text = "HP: %d / %d" % [player_hp, player_max_hp]


func _play_attack_animation() -> void:
	if attack_anim is AnimatedSprite2D:
		attack_anim.play()   # plays the currently selected animation
		await attack_anim.animation_finished
	elif attack_anim is AnimationPlayer and attack_anim.has_animation("attack"):
		attack_anim.play("attack")
		await attack_anim.animation_finished
	else:
		await get_tree().create_timer(0.2).timeout


func _flash(target: Node) -> void:
	if not (target is CanvasItem):
		return
	var tween := create_tween()
	tween.tween_property(target, "modulate", Color(1, 0.3, 0.3), 0.08)
	tween.tween_property(target, "modulate", Color.WHITE, 0.12)
	await tween.finished
