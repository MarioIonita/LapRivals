extends Camera3D

@export var follow_speed: float = 10.0
@export var rotation_speed: float = 8.0
@export var target: Marker3D

#  OFFSET IMPORTANT
@export var offset: Vector3 = Vector3(-0.83, 0.6, 0)

func _physics_process(delta: float) -> void:
	
	if not target:
		return
	
	#  poziția dorită = target + offset
	var desired_position = target.global_transform.origin + target.global_transform.basis * offset
	
	# LERP către poziția corectă
	global_position = global_position.lerp(desired_position, follow_speed * delta)
	
	# Look at (mult mai stabil decât quaternion aici)
	look_at(target.global_transform.origin)
