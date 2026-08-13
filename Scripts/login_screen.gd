extends Control

@export_category("UI Elements")
@export var email_input: LineEdit
@export var login_button: Button
@export var name_input: LineEdit
@export var save_name_button: Button
@export var status_label: Label

@export_category("Scene Settings")
@export_file("*.tscn") var main_menu_scene: String = "res://Scenes/main_menu.tscn"

func _ready():
	if login_button:
		login_button.pressed.connect(_on_login_pressed)
	if save_name_button:
		save_name_button.pressed.connect(_on_save_name_pressed)
	
	# إخفاء خانات الاسم في البداية
	if name_input: name_input.visible = false
	if save_name_button: save_name_button.visible = false

func _on_login_pressed():
	if not email_input or not status_label:
		return
		
	var email = email_input.text.strip_edges()
	if email == "":
		status_label.text = "اكتب حسابك أو إيميلك أولاً!"
		return
		
	status_label.text = "جاري الاتصال بالسحابة..."
	if login_button: login_button.disabled = true
	
	# نكلم المدير السحابي يفحص الحساب
	var result = await CloudManager.login_or_register(email)
	
	if result.success:
		if result.is_new:
			# حساب جديد! نطلع له خانة الاسم
			status_label.text = "حساب جديد! أدخل اسمك في اللعبة:"
			if email_input: email_input.visible = false
			if login_button: login_button.visible = false
			if name_input: name_input.visible = true
			if save_name_button: save_name_button.visible = true
		else:
			# حساب قديم! نرحب فيه ونوديه للعبة مباشرة
			status_label.text = "مرحباً بعودتك: " + CloudManager.current_player_name
			await get_tree().create_timer(1.0).timeout
			_change_to_game_scene()
	else:
		status_label.text = result.message
		if login_button: login_button.disabled = false

func _on_save_name_pressed():
	if not name_input or not status_label:
		return
		
	var p_name = name_input.text.strip_edges()
	if p_name == "":
		status_label.text = "الاسم لا يمكن أن يكون فارغاً!"
		return
		
	status_label.text = "جاري إنشاء الحساب السحابي..."
	if save_name_button: save_name_button.disabled = true
	
	var success = await CloudManager.save_new_player(p_name)
	
	if success:
		status_label.text = "تم إنشاء الحساب بنجاح!"
		await get_tree().create_timer(1.0).timeout
		_change_to_game_scene()
	else:
		status_label.text = "حدث خطأ أثناء الحفظ."
		if save_name_button: save_name_button.disabled = false

func _change_to_game_scene():
	if main_menu_scene != "":
		var err = get_tree().change_scene_to_file(main_menu_scene)
		if err != OK:
			print("خطأ: ما قدرنا نفتح مشهد المين منيو، تأكد من المسار في الإنسبيكتور!")
	else:
		print("يا غالي، نسيت تحدد مسار مشهد المين منيو في الإنسبيكتور!")
