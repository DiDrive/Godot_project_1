@tool
extends Control

@onready var build_button = $BuildButton
@onready var platform_list = $PlatformList
@onready var status_label = $StatusLabel

var plugin_reference: EditorPlugin = null

func setup(plugin: EditorPlugin):
	print("setup 被调用")
	plugin_reference = plugin
	print("plugin_reference 已设置")

func _ready():
	build_button.pressed.connect(_on_build_pressed)
	load_config()

func load_config():
	var config_file = FileAccess.open("res://.adapterrc", FileAccess.READ)
	if config_file:
		var config = JSON.parse_string(config_file.get_as_text())
		for platform in config.exportChannels:
			platform_list.add_item(platform)
		config_file.close()

func _get_web_export_preset():
	# 直接使用 EditorExportPlatform 类
	var config = ConfigFile.new()
	var err = config.load("res://export_presets.cfg")
	
	if err == OK:
		print("成功加载导出预设配置")
		# 手动创建导出目录
		return true
	else:
		print("加载导出预设配置失败")
	return false

func _on_build_pressed():
	print("开始构建流程")
	if plugin_reference:
		print("成功获取插件引用")
		var editor = plugin_reference.get_editor_interface()
		if editor:
			print("成功获取编辑器接口")
			
			# 先使用 Godot 导出功能导出一次 HTML5 项目，但使用自定义模板
			var export_path = "res://builds/temp"
			var dir = DirAccess.open("res://")
			if dir:
				dir.make_dir_recursive(export_path)
				print("创建临时导出目录")
			
			# 使用命令行调用 Godot 导出，添加参数减小文件大小
			var godot_path = OS.get_executable_path()
			var output_path = ProjectSettings.globalize_path(export_path)
			
			print("开始导出基础项目")
			status_label.text = "正在导出基础项目..."
			
			# 使用系统命令导出，添加优化参数
			var output = []
			var args = [
				"--headless", 
				"--export-release", 
				"Web", 
				output_path + "/index.html",
				"--rendering-driver", "opengl3",  # 使用更兼容的渲染器
				"--minify-js",                    # 压缩JS
				"--threads", "0"                  # 禁用线程以减小文件大小
			]
			var exit_code = OS.execute(godot_path, args, output, true)
			
			if exit_code != 0:
				print("导出失败：", output)
				status_label.text = "导出失败！"
				return
			
			print("基础项目导出完成")
			
			# 为每个平台创建定制版本
			for idx in platform_list.get_selected_items():
				var platform = platform_list.get_item_text(idx)
				print("正在处理平台：", platform)
				status_label.text = "正在构建 " + platform + " 版本..."
				
				# 创建平台目录
				var platform_dir = "res://builds/" + platform
				if dir:
					dir.make_dir_recursive(platform_dir)
					print("创建平台目录：", platform_dir)
				
				# 复制基础导出文件
				_copy_directory(export_path, platform_dir)
				
				# 修改 HTML 文件，添加内联数据
				_optimize_html_file(platform_dir + "/index.html", platform)
				
				print("平台版本构建完成：", platform_dir)
			
			# 删除临时目录
			_remove_directory(export_path)
			
			status_label.text = "构建完成！"
			print("全部构建完成")
		else:
			print("获取编辑器接口失败")
	else:
		print("获取插件引用失败")

# 优化 HTML 文件，尝试内联小文件
func _optimize_html_file(file_path, platform):
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file:
		var content = file.get_as_text()
		file.close()
		
		# 加载配置
		var config_file = FileAccess.open("res://.adapterrc", FileAccess.READ)
		if config_file:
			var config = JSON.parse_string(config_file.get_as_text())
			config_file.close()
			
			var platform_config = config.injectOptions[platform]
			
			# 替换平台标识符
			content = content.replace("{{__adv_channels_adapter__}}", platform)
			
			# 注入平台特定代码
			content = content.replace("</head>", platform_config.head + "</head>")
			
			# 添加 CTA 按钮和平台特定处理
			var cta_script = """
<script>
// 添加 CTA 按钮
document.addEventListener('DOMContentLoaded', function() {
	// 创建 CTA 按钮
	var ctaButton = document.createElement('button');
	ctaButton.id = 'cta-button';
	ctaButton.innerText = '立即下载';
	ctaButton.style.position = 'absolute';
	ctaButton.style.bottom = '20px';
	ctaButton.style.left = '50%';
	ctaButton.style.transform = 'translateX(-50%)';
	ctaButton.style.backgroundColor = '#ff5500';
	ctaButton.style.color = 'white';
	ctaButton.style.border = 'none';
	ctaButton.style.borderRadius = '25px';
	ctaButton.style.padding = '12px 30px';
	ctaButton.style.fontSize = '18px';
	ctaButton.style.fontWeight = 'bold';
	ctaButton.style.cursor = 'pointer';
	ctaButton.style.zIndex = '9999';
	
	// 添加点击事件
	ctaButton.addEventListener('click', function() {
		console.log('CTA 按钮被点击');
		
		// 根据平台调用不同的 API
		switch ('""" + platform + """') {
			case 'Facebook':
				try { onCTAClick(); } catch(e) { console.error(e); }
				break;
			case 'Google':
				try { ExitApi.exit(); } catch(e) { console.error(e); }
				break;
			case 'Tiktok':
				try { window.openAppStore(); } catch(e) { console.error(e); }
				break;
			default:
				console.log('未知平台');
		}
	});
	
	document.body.appendChild(ctaButton);
});
</script>
"""
			
			content = content.replace("</body>", cta_script + platform_config.sdkScript + platform_config.body + "</body>")
			
			# 保存修改后的文件
			var out_file = FileAccess.open(file_path, FileAccess.WRITE)
			if out_file:
				out_file.store_string(content)
				out_file.close()
				print("HTML 文件优化完成：", file_path)

# 删除目录函数
func _remove_directory(dir_path):
	var dir = DirAccess.open(dir_path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if dir.current_is_dir() and file_name != "." and file_name != "..":
				_remove_directory(dir_path + "/" + file_name)
			else:
				dir.remove(file_name)
			file_name = dir.get_next()
		dir.remove(dir_path)
		print("目录删除完成：", dir_path)

# 创建自包含的 HTML 文件
func _create_self_contained_html(file_path, platform):
	# 加载配置
	var config_file = FileAccess.open("res://.adapterrc", FileAccess.READ)
	if config_file:
		var config = JSON.parse_string(config_file.get_as_text())
		config_file.close()
		
		var platform_config = config.injectOptions[platform]
		
		# 创建基本的 HTML 模板，包含内联的游戏代码
		var html_content = """
<!DOCTYPE html>
<html>
<head>
	<meta charset="utf-8">
	<meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
	<title>Playable Ad - """ + platform + """</title>
	<style>
		body { 
			margin: 0; 
			padding: 0; 
			background-color: black; 
			overflow: hidden;
			touch-action: none;
		}
		#game-container {
			position: absolute;
			top: 0;
			left: 0;
			width: 100%;
			height: 100%;
			display: flex;
			flex-direction: column;
			justify-content: center;
			align-items: center;
		}
		#cta-button {
			position: absolute;
			bottom: 20px;
			left: 50%;
			transform: translateX(-50%);
			background-color: #ff5500;
			color: white;
			border: none;
			border-radius: 25px;
			padding: 12px 30px;
			font-size: 18px;
			font-weight: bold;
			cursor: pointer;
			box-shadow: 0 4px 8px rgba(0,0,0,0.3);
			display: none;
		}
		#cta-button:hover {
			background-color: #ff7700;
		}
		.game-element {
			position: absolute;
			background-size: contain;
			background-repeat: no-repeat;
			background-position: center;
		}
	</style>
	""" + platform_config.head + """
</head>
<body>
	<div id="game-container">
		<!-- 游戏元素将在这里动态创建 -->
	</div>
	
	<button id="cta-button">立即下载</button>
	
	<script>
		// 平台标识
		const PLATFORM_KEY = '""" + platform + """';
		
		// 游戏状态
		let gameState = {
			started: false,
			elements: [],
			score: 0,
			timeLeft: 30
		};
		
		// 初始化游戏
		function initGame() {
			console.log('游戏初始化，平台：' + PLATFORM_KEY);
			
			// 显示 CTA 按钮
			document.getElementById('cta-button').style.display = 'block';
			
			// 绑定 CTA 点击事件
			document.getElementById('cta-button').addEventListener('click', function() {
				callToAction();
			});
			
			// 创建简单的游戏元素
			createGameElement();
			
			// 开始游戏循环
			gameState.started = true;
			requestAnimationFrame(gameLoop);
		}
		
		// 创建游戏元素
		function createGameElement() {
			const element = document.createElement('div');
			element.className = 'game-element';
			element.style.width = '100px';
			element.style.height = '100px';
			element.style.backgroundColor = 'red';
			element.style.borderRadius = '50%';
			element.style.left = Math.random() * (window.innerWidth - 100) + 'px';
			element.style.top = Math.random() * (window.innerHeight - 100) + 'px';
			
			element.addEventListener('click', function() {
				gameState.score += 1;
				element.style.left = Math.random() * (window.innerWidth - 100) + 'px';
				element.style.top = Math.random() * (window.innerHeight - 100) + 'px';
			});
			
			document.getElementById('game-container').appendChild(element);
			gameState.elements.push(element);
		}
		
		// 游戏循环
		function gameLoop() {
			if (!gameState.started) return;
			
			// 更新游戏状态
			
			// 继续循环
			requestAnimationFrame(gameLoop);
		}
		
		// CTA 调用
		function callToAction() {
			console.log('CTA 被点击');
			
			switch (PLATFORM_KEY) {
				case 'Facebook':
					try { onCTAClick(); } catch(e) { console.error(e); }
					break;
				case 'Google':
					try { ExitApi.exit(); } catch(e) { console.error(e); }
					break;
				case 'Tiktok':
					try { window.openAppStore(); } catch(e) { console.error(e); }
					break;
				default:
					console.log('未知平台');
			}
		}
		
		// 当文档加载完成时初始化游戏
		document.addEventListener('DOMContentLoaded', initGame);
	</script>
	""" + platform_config.sdkScript + """
	""" + platform_config.body + """
</body>
</html>
"""
		
		# 保存 HTML 文件
		var file = FileAccess.open(file_path, FileAccess.WRITE)
		if file:
			file.store_string(html_content)
			file.close()
			print("自包含 HTML 文件创建完成：", file_path)
		else:
			print("HTML 文件创建失败：", file_path)

# 复制目录函数
func _copy_directory(from_dir, to_dir):
	var dir = DirAccess.open(from_dir)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if dir.current_is_dir():
				var new_from = from_dir + "/" + file_name
				var new_to = to_dir + "/" + file_name
				DirAccess.make_dir_recursive_absolute(new_to)
				_copy_directory(new_from, new_to)
			else:
				dir.copy(from_dir + "/" + file_name, to_dir + "/" + file_name)
			file_name = dir.get_next()
		print("目录复制完成：", from_dir, " -> ", to_dir)

# 处理 HTML 文件
func _process_html_file(file_path, platform):
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file:
		var content = file.get_as_text()
		file.close()
		
		# 加载配置
		var config_file = FileAccess.open("res://.adapterrc", FileAccess.READ)
		if config_file:
			var config = JSON.parse_string(config_file.get_as_text())
			config_file.close()
			
			var platform_config = config.injectOptions[platform]
			
			# 替换平台标识符
			content = content.replace("{{__adv_channels_adapter__}}", platform)
			
			# 注入平台特定代码
			content = content.replace("</head>", platform_config.head + "</head>")
			content = content.replace("</body>", platform_config.sdkScript + platform_config.body + "</body>")
			
			# 保存修改后的文件
			var out_file = FileAccess.open(file_path, FileAccess.WRITE)
			if out_file:
				out_file.store_string(content)
				out_file.close()
				print("HTML 文件处理完成：", file_path)
