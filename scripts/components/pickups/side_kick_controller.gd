extends Node

var input_dir: Vector2

func _physics_process(_delta: float) -> void:
	if get_tree().get_multiplayer().has_multiplayer_peer() \
		and is_multiplayer_authority() and not MatchManager.game_paused:
		
		input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
