extends CharacterBody2D

@onready var animated_sprite = $AnimatedSprite2D
@onready var roll_timer = $RollTimer  # 添加一个Timer节点
var is_rolling = false
var roll_cooldown = false
const ROLL_DURATION = 0.5
const ROLL_COOLDOWN = 1.0 #冷却时间
#const ROLL_INVINCIBILITY = true  # 翻滚时是否无敌
const SPEED = 100.0
const FAST_SPEED =120
const JUMP_VELOCITY = -300.0


func _physics_process(delta: float) -> void:
	apply_gravity(delta)
	handle_jump()
	handle_movement()
	update_animation()
	move_and_slide()

# 重力
func apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

# 跳跃
func handle_jump() -> void:
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

# 移动
func handle_movement() -> void:
	var direction := Input.get_axis("move_left", "move_right")
	
	if Input.is_action_just_pressed("roll") and is_on_floor() and not roll_cooldown:
		start_roll(direction)
	elif is_rolling:
		pass
	else:
		velocity.x = direction * SPEED

# 翻滚
func start_roll(direction: float) -> void:
	if direction == 0:
		direction = -1 if animated_sprite.flip_h else 1

	is_rolling = true
	roll_cooldown = true
	velocity.x = direction * FAST_SPEED
	animated_sprite.play("roll")

	if not roll_timer:
		roll_timer = Timer.new()
		roll_timer.one_shot = true
		add_child(roll_timer)
		roll_timer.timeout.connect(end_roll)

	roll_timer.start(ROLL_DURATION)
	# $RollSound.play()

# 结束翻滚
func end_roll() -> void:
	is_rolling = false
	# 设置冷却时间
	var cooldown_timer = Timer.new()
	cooldown_timer.one_shot = true
	add_child(cooldown_timer)
	cooldown_timer.timeout.connect(func(): roll_cooldown = false)
	cooldown_timer.start(ROLL_COOLDOWN)

# 更新动画
func update_animation() -> void:
	var direction := Input.get_axis("move_left", "move_right")
	# 如果正在翻滚，不中断动画
	if is_rolling:
		return
	if is_on_floor():
		if direction:
			animated_sprite.flip_h = direction < 0
			animated_sprite.play("run")
		else:
			animated_sprite.play("Idle")
	else:
		animated_sprite.play("jump")
