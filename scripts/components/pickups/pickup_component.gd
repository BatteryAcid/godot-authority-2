class_name PickupComponent
extends Area2D
## Enables items to be picked up using Area2D's area_entered signal. 
## [br]Must add [CollectorComponent] to Player objects in order to 
## enable pickup functionality.
##
## LIMITATIONS:[br]
## - For demo purposes, the base implementation only syncs postion on spawn, 
## meaning, unless you override and synchronize position, late joining peers 
## will not have the object's location properly synched.[br][br]
## 
## NOTE:[br]
## HitboxComponent not added at this level because items may not cause damage.

@export var player_tagged: PlayerTagged
@export var pickup_sprite: AnimatedSprite2D
## Time to live before [method cleanup] is called.
@export var ttl: int = 6

func _ready() -> void:
	if is_multiplayer_authority():
		area_entered.connect(_picked_up)

## Registers the item picked-up when a [CollectorComponent] enters the Area2D.
## Should only be called on the authority-host.[br]
func _picked_up(collector: Area2D):
	if not is_multiplayer_authority() or not collector is CollectorComponent: return
	
	if not player_tagged.is_player_tagged():
		var collector_player = collector.get_parent().name
		print("Item picked up by %s!" % collector_player)
		player_tagged.tagged_player_name = collector.get_parent().name
		
		# Use an RPC to sync player that is tagged with picking up the item.
		inform_peers_control_taken.rpc(collector_player)

## Call this from authority to inform peers of object ownership change.
@rpc("authority", "call_local")
func inform_peers_control_taken(new_player_tagged: String):
	print("Control taken by %s on peer: %s" % [new_player_tagged, multiplayer.get_unique_id()])
	# NOTE: If you wanted the item to hit any player, and not just the one who
	# doesn't own it, leave this null.
	player_tagged.tagged_player_name = new_player_tagged
	pickup_sprite.animation = "armed"
	
@rpc("authority")
func set_pickup_transform(pickup_transform: Transform2D):
	global_transform = pickup_transform

## Sets the time to live of the item.[br]
## NOTE: the way this currently works, the item is killed regardless of whether
## or not it is controlled.
func set_ttl():
	print("Item will last %s seconds!" % ttl)
	print("set_ttl on peer %s" % [multiplayer.get_unique_id()]) #TODO remove
	get_tree().create_timer(ttl).timeout.connect(cleanup)

## Override with custom cleanup. Should always be called on the authority owning
## peer.
func cleanup():
	print("Cleanup after ttl")
	queue_free()
