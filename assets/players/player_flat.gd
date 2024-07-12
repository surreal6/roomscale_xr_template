extends CharacterBody3D

signal toggle_menu

const SPEED = 5.0
const rotation_speed = 1.5
const JUMP_VELOCITY = 4.5

func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	## Handle jump.
	#if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		#velocity.y = JUMP_VELOCITY
	
	if Input.is_action_just_pressed("ui_cancel"):
		toggle_menu.emit()

	var move_input = Input.get_axis("forward", "back")
	var rotation_direction = Input.get_axis("right", "left")
	
	var direction = (transform.basis * Vector3(0, 0, move_input)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	rotation.y += rotation_direction * rotation_speed * delta
	move_and_slide()
