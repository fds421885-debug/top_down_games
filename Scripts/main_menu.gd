extends Control

@export var play_button: Button
@export var logout_button: Button
@export var leaderboard_button: Button
@export var welcome_label: Label

@export_file("*.tscn") var game_scene_path: String = "res://Scenes/game.tscn"
@export_file("*.tscn") var login_scene_path: String = "res://Scenes/login_screen.tscn"
@export_file("*.tscn") var leaderboard_scene_path: String = "res://Scenes/leaderboard.tscn"

func _ready() -> void:
	# التحقق إذا اللاعب مو مسجل دخول، نطردة لشاشة الدخول
	if CloudManager.current_email == "":
		get_tree().change_scene_to_file(login_scene_path)
		return
		
	if welcome_label:
		welcome_label.text = "أهلاً بك يا بطل: " + CloudManager.current_player_name
		
	if play_button: play_button.pressed.connect(_on_play_pressed)
	if logout_button: logout_button.pressed.connect(_on_logout_pressed)
	if leaderboard_button: leaderboard_button.pressed.connect(_on_leaderboard_pressed)

func _on_play_pressed() -> void:
	if game_scene_path != "":
		get_tree().change_scene_to_file(game_scene_path)

func _on_logout_pressed() -> void:
	# تسجيل الخروج وحذف الجلسة المحلية
	CloudManager.logout()
	get_tree().change_scene_to_file(login_scene_path)

func _on_leaderboard_pressed() -> void:
	if leaderboard_scene_path != "":
		get_tree().change_scene_to_file(leaderboard_scene_path)
