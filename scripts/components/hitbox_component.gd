class_name HitboxComponent
extends Area2D

@export var damage: int = 1
@export var player_tagged: PlayerTagged
@export var activation_delay_seconds: int = 0 # seconds to delay interaction

signal hit_hurtbox(hurtbox)

func _ready() -> void:
	# Allow for interaction signals to be delayed upon spawn
	get_tree().create_timer(activation_delay_seconds).timeout.connect(_activate_interaction_signals)

func _activate_interaction_signals():
	area_entered.connect(_on_hurtbox_entered)

func _on_hurtbox_entered(hurtbox: Area2D):
	# Ignore hits to self
	if player_tagged.tagged_player_name == hurtbox.get_parent().name: return

	if not hurtbox is HurtboxComponent: return

	hit_hurtbox.emit(hurtbox)

	hurtbox.hurt.emit(self)
