extends Camera3D

# Movement settings / position/etc
var movement_speed: float = 15.0
var side_movement_limit: float = 1.0  # Units from the default position on X
var forward_back_movement_limit: float = 0.5  # Units from the default position on Z
var side_rotation_max_degrees: float = 5.0  # Max angle in degrees for rotation
var movement_smoothness: float = 0.3  # The lower the value, the smoother the movement

var default_position: Vector3
var default_rotation_degrees: Vector3

# !INTERACTOR Signal to emit when an object is interacted with
signal object_interacted(object)

func _ready():
	# Set the default position and rotation at startup
	default_position = global_transform.origin
	default_rotation_degrees = rotation_degrees
	
	#! Intercator
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _process(delta):
	# movement thing
	var move_direction = Vector3.ZERO
	if Input.is_action_pressed("move_right"):
		move_direction.x += 1
	if Input.is_action_pressed("move_left"):
		move_direction.x -= 1
	if Input.is_action_pressed("move_forward"):
		move_direction.z -= 1  # In Godot, negative Z is forward
	if Input.is_action_pressed("move_back"):
		move_direction.z += 1  # Positive Z is backward
		
		
	# Normalize the move direction 
	move_direction = move_direction.normalized()

	# new pos
	var target_position = global_transform.origin + move_direction * movement_speed * delta

	# Clamp 
	target_position.x = clamp(target_position.x, default_position.x - side_movement_limit, default_position.x + side_movement_limit)
	target_position.z = clamp(target_position.z, default_position.z - forward_back_movement_limit, default_position.z + forward_back_movement_limit)

	# don't know how it works, just copied below, some interpolation thing
	var new_position = global_transform.origin.lerp(target_position, movement_smoothness)

	global_transform.origin = new_position

	var side_proportion = (new_position.x - default_position.x) / side_movement_limit
	var target_side_rotation = side_rotation_max_degrees * side_proportion

	rotation_degrees.y = lerp(rotation_degrees.y, default_rotation_degrees.y + target_side_rotation, movement_smoothness)
	
# FUNNCTIONS FOR INTERACTOR START:

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			# Perform the raycast when the left mouse button is pressed
			_perform_raycast()

func _perform_raycast():
	var mouse_pos = get_viewport().get_mouse_position()
	var ray_origin = project_ray_origin(mouse_pos)
	var ray_end = ray_origin + project_ray_normal(mouse_pos) * 1000
	var space_state = get_world_3d().direct_space_state
	var ray_query = PhysicsRayQueryParameters3D.new()
	ray_query.from = ray_origin
	ray_query.to = ray_end

	var result = space_state.intersect_ray(ray_query)

	# Debugging output before checking the result
	print("Raycast from: ", ray_origin, " to: ", ray_end)
	if result:
		print("Raycast hit: ", result.collider.name)
	else:
		print("Raycast found no collider.")

	# Check both the collider and its parent for the `interact` method
	if result and result.collider:
		var interactable = result.collider if result.collider.has_method("interact") else result.collider.get_parent()
		if interactable and interactable.has_method("interact"):
			interactable.interact()
			emit_signal("object_interacted", interactable)
		else:
			print("Collider does not have an 'interact' method.")
