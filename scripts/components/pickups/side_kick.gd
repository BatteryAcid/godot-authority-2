extends PickupInputAuthComponent
## When the "Side kick" is claimed, use arrow keys to hit the other player.[br]
## Demonstrates "authority swapping" of the InputController. Inputs are then 
## applied to the object on the host-authority peer, then position is synched 
## back to the peers. This is similar to how we are currently handling player's
## movement.
##
## NOTE: I think it's important to point out the added complexity in swapping
## authority of an item that is short lived. In order to be mostly sure we don't
## get "Node not found" or sync errors, we have to do this "back and forth" RPC
## to turn off synching on the input-owner-peer and then back to host-auth to 
## despawn. Timeouts can also be leveraged, but latency between peers could 
## still cause this to occur. Potentially, this may also need a failsafe 
## queue_free, just in case the RPC dance fails.

@onready var _hitbox_component: HitboxComponent = $HitboxComponent
@onready var side_kick_input_synchronizer: MultiplayerSynchronizer \
	= $SideKickInputController/SideKickInputSynchronizer

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

# When mine hit, remove it.
func _hit_hurtbox(_hurtbox: HurtboxComponent) -> void:
	pickup_sprite.animation = "explode"
	
	# easy way to stop item from moving
	set_physics_process(false)
	
	# This is an attempt to prevent "Node not found" errors that happen after
	# the Side Kick is queue_free.
	# TODO: should this only run on owning-peer?
	# Like: side_kick_input_synchronizer.get_multiplayer_authority() == multiplayer.get_unique_id()
	side_kick_input_synchronizer.set_visibility_public(false) 
	
	if is_multiplayer_authority() and not pickup_sprite.animation_finished.has_connections():
		pickup_sprite.animation_finished.connect(queue_free)

func cleanup():
	if player_tagged.is_player_tagged():
		# From the auth-host, send rpc to current owner of item, to stop data sync.
		_kill_sync.rpc_id(str(player_tagged.tagged_player_name).to_int())
	else:
		# If no player is tagged, just despawn, no visibility changes needed.
		_despawn()

## Use "authority" here as this should only be called from the authority-host,
## to the peer that has ownership (authority) over the input synchronizer. Need
## "call_local" as it can also be the authority-host who owns it.
@rpc("authority", "call_local", "reliable")
func _kill_sync():
	# On peer with input-authority, cancel synching data
	side_kick_input_synchronizer.set_visibility_public(false)
	
	# Tell the auth-host to despawn item, as that's who owns the spawner.
	_despawn.rpc_id(1)

@rpc("any_peer", "call_local", "reliable")
func _despawn():
	# We can get away with using the standard authority check as the owning-peer
	# will only have authority over inputs, so this check is still valid.
	if is_multiplayer_authority():
		queue_free()
