extends PickupFullAuthComponent
## When the "Drone" is claimed, use arrow keys to hit the other player.[br]
## Demonstrates "authority swapping" over the whole object. Inputs are then 
## applied directly to the object from the authority-owning peer, then position
## is synched to the other peers.
##
## NOTE: I think it's important to point out the added complexity in swapping
## authority of an item that is short lived. In order to be mostly sure we don't
## get "Node not found" or sync errors, we have to do this "back and forth" RPC
## to turn off synching on the item-owner-peer and then back to host-auth to 
## despawn. Timeouts can also be leveraged, but latency between peers could 
## still cause this to occur. Potentially, this may also need a failsafe 
## queue_free, just in case the RPC dance fails.

@export var input_controller: Node

@onready var _drone_synchronizer: MultiplayerSynchronizer = $DroneSynchronizer
@onready var _hitbox_component: HitboxComponent = $HitboxComponent

func _ready() -> void:
	super._ready()
	_hitbox_component.hit_hurtbox.connect(_hit_hurtbox)

func _physics_process(delta: float) -> void:
	if get_tree().get_multiplayer().has_multiplayer_peer() \
		and is_multiplayer_authority() and not MatchManager.game_paused \
		and player_tagged.is_player_tagged():
		
		var input_dir = input_controller.input_dir
		var velocity: Vector2 = Vector2(input_dir.x, input_dir.y) * 900
		translate(velocity * delta)
		
		# TODO: for cheat checks, we'd have to manually check if we're on the host-authority
		# peer == "1", last postion and time update greater than X and Y, return to previous position.
		# Get's complicated real quick...

# When Drone hit, remove it.
func _hit_hurtbox(_hurtbox: HurtboxComponent) -> void:
	pickup_sprite.animation = "explode"

	# easy way to stop item from moving
	set_physics_process(false)
	
	# Here, authority means the peer that owns the item, which means the below
	# call to "cleanup" happens on the peer that owns the item, NOT necessarily
	# the host-authority.
	if is_multiplayer_authority() \
		and not pickup_sprite.animation_finished.has_connections():
		
		print("hit hurtbox %s" % [get_multiplayer_authority()])
		pickup_sprite.animation_finished.connect(cleanup)

## This can be called from different authority contexts depending on where it's 
## called from: the timeout signal after ttl is expired, or through a collision.
## This changes the authority context of where it's called from. This is why 
## _kill_sync.rpc_id calls to the authority-owning-peer over the item. 
func cleanup():
	# From the authority-peer, send rpc to current owner of item, to stop data sync.
	if player_tagged.is_player_tagged():
		print("cleanup authority given %s" % [get_multiplayer_authority()])
		_kill_sync.rpc_id(str(player_tagged.tagged_player_name).to_int())
	else:
		# If no player is tagged, just despawn, no visibility changes needed.
		_despawn()

## Need "any_peer" as a non-host peer can also be authority. Should be called to 
## the peer that has authority over the whole item.
@rpc("any_peer", "call_local", "reliable")
func _kill_sync():
	print("(Drone) Killing visibility on peer: %s" % multiplayer.get_unique_id())
	# On peer that owns item, cancel synching data
	_drone_synchronizer.set_visibility_public(false)
	
	# Tell the auth-host to despawn item, as that's who owns the spawner.
	_despawn.rpc_id(1)

# Must use any_peer as any peer can have authority of this item.
@rpc("any_peer", "call_local", "reliable")
func _despawn():
	print("(Drone) Despawn on peer: %s" % multiplayer.get_unique_id())
	# We must check that we are on peer 1, host-authority, as that holds authority
	# over the MultiplayerSpawner responsible for spawning this item. 
	if get_tree().get_multiplayer().get_unique_id() == 1:
		queue_free()
