@tool
extends EditorPlugin

var dock
var export_plugin

func _enter_tree():
	print("插件初始化")
	dock = preload("res://addons/playable_ads_adapter/dock.tscn").instantiate()
	if dock:
		print("dock 实例化成功")
		# 直接调用 dock 的 setup 方法
		if dock.has_method("setup"):
			print("找到 setup 方法")
			dock.setup(self)
			print("setup 方法调用完成")
		add_control_to_dock(DOCK_SLOT_RIGHT_UL, dock)
	else:
		print("dock 实例化失败")
	
	export_plugin = preload("res://addons/playable_ads_adapter/export_plugin.gd").new()
	add_export_plugin(export_plugin)

func _exit_tree():
	if dock:
		remove_control_from_docks(dock)
		dock.free()
	if export_plugin:
		remove_export_plugin(export_plugin)
