extends Area2D

@onready var timer =$Timer

func _on_body_entered(body:Node2D):
    print("死亡")
    timer.start()

func _on_timer_timeout() -> void:
    get_tree().reload_current_scene()
