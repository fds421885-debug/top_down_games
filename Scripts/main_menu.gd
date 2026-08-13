extends Control

@export_category("Menu Buttons")
# هنا بنسحب الأزرار من الـ Scene Tree ونفلتها في الإنسبيكتور
@export var start_button: Button
@export var exit_button: Button

@export_category("Game Settings")
# هنا نحدد مسار مشهد اللعبة الرئيسي (Game.tscn)
@export_file("*.tscn") var game_scene_path: String

func _ready() -> void:
	SupabaseManager.submit_score("تجربة", 2, 45)

	
	
	
	
	# ربط الأزرار بالوظائف (Signals)
	if start_button:
		start_button.pressed.connect(_on_start_pressed)
	else:
		push_warning("انتبه! زر البداية (StartButton) مو مربوط في الإنسبيكتور.")

	if exit_button:
		exit_button.pressed.connect(_on_exit_pressed)
	else:
		push_warning("انتبه! زر الخروج (ExitButton) مو مربوط في الإنسبيكتور.")

func _on_start_pressed() -> void:
	# نتحقق إننا اخترنا مشهد للعبة قبل ما نحاول ننقل اللاعب
	if game_scene_path == "":
		print("يا غالي، نسيت تحدد مسار مشهد اللعبة في الإنسبيكتور!")
		return
		
	var err = get_tree().change_scene_to_file(game_scene_path)
	if err != OK:
		print("فيه خطأ وما قدرنا نفتح اللعبة!")

func _on_exit_pressed() -> void:
	# إغلاق اللعبة تماماً
	get_tree().quit()
