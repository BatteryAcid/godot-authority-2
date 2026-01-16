class_name PlayerTagged
extends Node
## Add this component to objects where you want to track player ownership, like
## pickup items. Helps with checks to avoid self-collisions or if item has 
## already been claimed.[br][br]
## TIP: use the network id for [member tagged_player_name], can help when you 
## need to send RPCs to a specific peer.

var tagged_player_name: String = "":
	set(value):
		tagged_player_name = value

func is_player_tagged() -> bool:
	return tagged_player_name != ""
