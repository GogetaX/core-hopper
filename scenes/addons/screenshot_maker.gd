extends Control

const IPHONE_6_5_PORTRAIT_SIZE = Vector2(1242,2688)

const SCREENSHOT_FOLDER = "user://shots/"

@export_enum("DISABLED","ANDROID_PHONE_PORTRAIT","iPhone_6.5_PORTRAIT","CRAZYGAMES_1920x1080") var screenshot_type := "DISABLED"

var _cur_size_multiplayer = 1.0

func _ready() -> void:
	if !OS.is_debug_build() || screenshot_type == "DISABLED":
		queue_free()
		return
	visible = true
	SetScreenRes()
	
func SetScreenRes():
	var cur_res = get_viewport().get_visible_rect().size
	var max_screen_size = DisplayServer.screen_get_size()
	var new_res = cur_res
	match screenshot_type:
		"ANDROID_PHONE_PORTRAIT":
			new_res = FindPerfectResForAndroid(new_res,max_screen_size)
		"iPhone_6.5_PORTRAIT":
			new_res = FindPerfectResForIOS(max_screen_size)
		"CRAZYGAMES_1920x1080":
			new_res = Vector2i(1920,1080)
	DisplayServer.window_set_size(new_res)

func FindPerfectResForIOS(screen_res:Vector2):
	var output_res = IPHONE_6_5_PORTRAIT_SIZE
	var divider_step = 0.5
	var cur_divider = 1.0
	while output_res.x/cur_divider > screen_res.x || output_res.y/cur_divider > screen_res.y:
		cur_divider += divider_step
	
	output_res = output_res / cur_divider
	_cur_size_multiplayer = cur_divider
	return output_res

	
func FindPerfectResForAndroid(new_res:Vector2,screen_res:Vector2):
	var screen_devider = Vector2(1.0,1.0)
	var output_res = new_res
	if new_res.x > screen_res.x:
		screen_devider.x = new_res.x / screen_res.x
	if new_res.y > screen_res.y:
		screen_devider.y = new_res.y / screen_res.y
		
	var new_scale = 1.0
	if screen_devider.x > screen_devider.y:
		new_scale = screen_devider.x
	elif screen_devider.x < screen_devider.y:
		new_scale = screen_devider.y
	
	output_res = Vector2(output_res.x / new_scale,output_res.y/new_scale)
	output_res.x = int(output_res.x / 9.0) * 9
	output_res.y = int(output_res.y / 16.0) * 16
	return output_res
	
func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.pressed && event.keycode==32:
			match screenshot_type:
				"ANDROID_PHONE_PORTRAIT":
					capture_control()
				"iPhone_6.5_PORTRAIT":
					capture_control(IPHONE_6_5_PORTRAIT_SIZE)
				_:
					capture_control()
	
func capture_control(force_resize:Vector2i = Vector2i.ZERO):
	#Create screenshot path
	if !FileAccess.file_exists(SCREENSHOT_FOLDER):
		var d = DirAccess.open("user://")
		d.make_dir(SCREENSHOT_FOLDER)
	
	
	var window_size = DisplayServer.window_get_size()
	var viewport_size = get_viewport().get_visible_rect().size
	var control_scale = Vector2(viewport_size.x / window_size.x,viewport_size.y / window_size.y)
	#new method
	#var region = Rect2(control.global_position.x, control.global_position.y, control.size.x, control.size.y)  # change the values around to suit your actual scene
	var region = Rect2(global_position.x/control_scale.x,global_position.y/control_scale.y,size.x/control_scale.x,size.y/control_scale.y)
	var image := get_viewport().get_texture().get_image().get_region(region)
	if force_resize != Vector2i.ZERO:
		image.resize(force_resize.x,force_resize.y)
	var empty_file_name = FindEmptyFile()
	image.save_png(SCREENSHOT_FOLDER+empty_file_name)
	CreateNotif("Screenshot been saved at: "+SCREENSHOT_FOLDER+empty_file_name)
	
func FindEmptyFile():
	var f_count = 0
	var full_file = ""
	var cur_lang = TranslationServer.get_locale()
	var cur_file_name = ""
	while true:
		cur_file_name = screenshot_type+"_"+str(f_count)+"_"+cur_lang+".png"
		full_file = SCREENSHOT_FOLDER + cur_file_name
		if !FileAccess.file_exists(full_file):
			break
		f_count += 1
	cur_file_name = screenshot_type+"_"+str(f_count)+"_"+cur_lang+".png"
	return cur_file_name
	
func CreateNotif(notif_text):
	print_rich("[color=orange]"+notif_text+"[/color]")
