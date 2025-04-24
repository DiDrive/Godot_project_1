@tool
extends EditorExportPlugin

var config = {}
var current_platform = ""

func _export_begin(features: PackedStringArray, is_debug: bool, path: String, flags: int) -> void:
	var config_file = FileAccess.open("res://.adapterrc", FileAccess.READ)
	if config_file:
		config = JSON.parse_string(config_file.get_as_text())
		config_file.close()

func _export_file(path: String, type: String, features: PackedStringArray) -> void:
	if path.ends_with("index.html"):
		var html = FileAccess.get_file_as_string(path)
		print("开始处理导出文件：", path)
		
		for channel in config.exportChannels:
			print("处理平台：", channel)
			var modified_html = inject_platform_code(html, channel)
			var output_path = path.replace("index.html", channel + "/index.html")
			save_platform_build(output_path, modified_html)

func inject_platform_code(html: String, platform: String) -> String:
	var platform_config = config.injectOptions[platform]
	html = html.replace("{{__adv_channels_adapter__}}", platform)
	html = html.replace("</head>", platform_config.head + "</head>")
	html = html.replace("</body>", platform_config.sdkScript + platform_config.body + "</body>")
	return html

func save_platform_build(path: String, content: String) -> void:
	var dir = path.get_base_dir()
	if !DirAccess.dir_exists_absolute(dir):
		DirAccess.make_dir_recursive_absolute(dir)
	
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(content)
		file.close()
		print("已保存文件：", path)
	else:
		print("保存文件失败：", path)
