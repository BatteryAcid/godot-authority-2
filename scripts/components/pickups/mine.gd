extends PickupComponent
## Example usage of the [PickupComponent] with an added hitbox component.

@onready var _hitbox_component: HitboxComponent = $HitboxComponent

func _ready() -> void:
	super._ready()
	_hitbox_component.hit_hurtbox.connect(_hit_hurtbox)

# Show hit animation and clean up node. Queue_free is ran on host-authority as
# that's who owns the item.
func _hit_hurtbox(_hurtbox: HurtboxComponent) -> void:
	pickup_sprite.animation = "explode"
	
	# This auth check refers the the host-authority peer.
	if is_multiplayer_authority() \
		and not pickup_sprite.animation_finished.has_connections():
		
		pickup_sprite.animation_finished.connect(queue_free)
