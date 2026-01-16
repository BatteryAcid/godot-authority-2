class_name AttributeComponent
extends Node

@export var starting_health = 5

@export var health: int = 5:
	set(value):
		health = value
		
		health_changed.emit()
		
		if health <= 0 && not no_health_emitted:
			no_health.emit()
			no_health_emitted = true

signal health_changed
signal no_health

var no_health_emitted = false

func reset_health():
	health = starting_health
	no_health_emitted = false
