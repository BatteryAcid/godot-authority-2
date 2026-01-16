class_name PickupFullAuthComponent
extends PickupComponent
## Use this component on items that assign full authority to a peer.

@rpc("authority", "call_local")
func inform_peers_control_taken(new_player_tagged: String):
	super(new_player_tagged)
	
	# NOTE: Authority must be set on all peers. 
	# Give FULL authority over entire object.
	set_multiplayer_authority(str(new_player_tagged).to_int(), true)
