extends Node
#@onready var coins_label: Label = $"../Player/Camera2D/coins_Label"
#@onready var coins_label: Label = $"../CanvasLayer/coins_Label"
@onready var coins_label: Label = $"../CanvasLayer/coins_Label"

var coinCount =0

func  addCoins():
	coinCount+=1
	coins_label.text = "收集的金币数量：" + str(coinCount) 
