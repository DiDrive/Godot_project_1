extends Node

const PLATFORM_KEY = "{{__adv_channels_adapter__}}"

func call_to_action() -> void:
	match PLATFORM_KEY:
		"Facebook":
			JavaScriptBridge.eval("onCTAClick()")
		"Google":
			JavaScriptBridge.eval("ExitApi.exit()")
		"Tiktok":
			JavaScriptBridge.eval("window.openAppStore()")
		_:
			print("未知平台")
