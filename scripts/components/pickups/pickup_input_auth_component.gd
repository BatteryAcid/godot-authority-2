class_name PickupInputAuthComponent
extends PickupComponent
## Use this component on items where inputs are controlled by a peer.

@export var input_controller: Node

@rpc("authority", "call_local")
func inform_peers_control_taken(new_player_tagged: String):
	super(new_player_tagged)
	
	# NOTE: Authority must be set on all peers. 
	# Give authority over just the inputs.
	input_controller.set_multiplayer_authority(str(new_player_tagged).to_int(), true)
