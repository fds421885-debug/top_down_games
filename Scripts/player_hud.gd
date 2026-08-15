extends Control

@export var name_label: Label
@export var wave_label: Label
@export var kills_label: Label

func _ready() -> void:
	# أول ما تبدأ اللعبة، نتاكد هل اللاعب مسجل دخول ولا مفرود برا؟
	if CloudManager.current_email == "" or CloudManager.current_player_name == "":
		print("ما فيه تسجيل دخول! جاري طرد اللاعب لشاشة الدخول...")
		get_tree().change_scene_to_file("res://Scenes/login_screen.tscn")
		return

	update_hud_display()

func _process(_delta: float) -> void:
	# تحديث دوري سريع للعدادات أثناء اللعب
	update_hud_display()

func update_hud_display() -> void:
	if name_label:
		name_label.text = "اللاعب: " + CloudManager.current_player_name
	if wave_label:
		wave_label.text = "الويف: " + str(CloudManager.current_wave)
	if kills_label:
		kills_label.text = "القتلات: " + str(CloudManager.current_kills)
