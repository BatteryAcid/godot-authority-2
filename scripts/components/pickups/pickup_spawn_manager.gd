extends Node

## Spawns pickup items.
##
## LIMITATIONS:
## - For demo purposes, only the authority-host can spawn items. For actual 
## gameplay, you may want to randomly spawn them from a timer or something.

@onready var _pickup_spawn_path: Node2D = get_tree().current_scene.get_node("%Pickups")

var _pickup_item_scene_names: Array[String] = \
	["res://scenes/pickups/mine.tscn", 
	"res://scenes/pickups/side_kick.tscn", 
	"res://scenes/pickups/drone.tscn"]
var _pickup_item: PickupComponent = null # Limit to only one active pickup item at a time

func _ready() -> void:
	var spawner: MultiplayerSpawner = get_child(0)
	spawner.spawn_path = _pickup_spawn_path.get_path()

func _physics_process(_delta: float) -> void:
	if get_tree().get_multiplayer().has_multiplayer_peer() and is_multiplayer_authority() \
		and not MatchManager.game_paused and _pickup_item == null:
			
		if Input.is_action_just_pressed("1"):
			_spawn_pickup_item(0)
		elif Input.is_action_just_pressed("2"):
			_spawn_pickup_item(1)
		elif Input.is_action_just_pressed("3"):
			_spawn_pickup_item(2)

func _spawn_pickup_item(item_scene_index: int):
	var pickup_scene = load(_pickup_item_scene_names[item_scene_index])
	var pickup_to_add = pickup_scene.instantiate()
	pickup_to_add.set_multiplayer_authority(1)
	pickup_to_add.global_transform = Transform2D(0, Vector2(800, 600))
	
	_pickup_spawn_path.add_child(pickup_to_add, true)
	_pickup_item = pickup_to_add
	
	# RPC to synch spawn location on spawn, so we don't have to use a synchronizer
	_pickup_item.set_pickup_transform.rpc(pickup_to_add.global_transform)
	
	# kill after some time
	# TODO: could move to store this in the item itself
	_pickup_item.set_ttl()
