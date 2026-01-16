class_name PlayerInput
extends Node

signal weapon_fired

var input_dir: Vector2

func _physics_process(_delta: float) -> void:
	if get_tree().get_multiplayer().has_multiplayer_peer() and is_multiplayer_authority() and not MatchManager.game_paused:
		input_dir = Input.get_vector("left", "right", "up", "down")
		
		if Input.is_action_just_pressed("fire"):
			weapon_fired.emit()
