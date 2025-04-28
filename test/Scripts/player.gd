extends CharacterBody2D

@onready var animated_sprite = $AnimatedSprite2D
const SPEED = 100.0
const FAST_SPEED =150
const JUMP_VELOCITY = -300.0


func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	var direction := Input.get_axis("move_left", "move_right")
	if Input.is_action_just_pressed("roll"):
		velocity.x = direction * FAST_SPEED
		animated_sprite.play("roll")
	else:
		velocity.x = direction * SPEED
	if is_on_floor():
		if direction:
			animated_sprite.flip_h = false if direction>0 else true
			animated_sprite.play("run")
		else:
			#velocity.x = move_toward(velocity.x, 0, SPEED)
			animated_sprite.play("Idle")
	else:
		animated_sprite.play("jump")
		#print("跳跃")

	move_and_slide()
