extends Area2D

@onready var timer = $Timer

func _on_body_entered(body:Node2D):
	if body.has_method("die"):  # 检查是否是玩家
		print("死亡")
		Engine.time_scale = 0.5
		#body.position.y -= 20
		body.get_node("CollisionShape2D").queue_free()
		body.die()  # 调用玩家的死亡函数
		timer.start()

func _on_timer_timeout() -> void:
	Engine.time_scale = 1
	get_tree().reload_current_scene()
