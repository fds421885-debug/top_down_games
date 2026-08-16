extends Control

@export var status_label: Label
@export var timer_label: Label
@export_file("*.tscn") var multiplayer_game_scene: String = "res://Scenes/multiplayer_game.tscn"

@export_category("إدارة السيرفر والغرف")
@export var clear_all_rooms_on_start: bool = false 

@export_category("خيارات أهداف الأونلاين")
@export var possible_kill_goals: Array[int] = [15, 20, 30]
@export var possible_wave_goals: Array[int] = [2, 3, 5]

@export_category("إعدادات البوتات")
@export var bot_names: Array[String] = ["ظل الموت", "الصياد", "المدمر", "الشبح", "الأسطورة"]
@export var bot_kill_delays: Array[float] = [4.0, 2.5, 1.2] 
@export var bot_wave_delays: Array[float] = [25.0, 18.0, 12.0] 

var time_left: float = 15.0
var search_timer: Timer
var poll_timer: Timer
var match_started: bool = false

func _ready() -> void:
	if multiplayer_game_scene == "":
		print("تحذير: لا تنسى تحدد مسار مشهد multiplayer_game.tscn في الإنسبكتور!")
		
	print("--- فتحت شاشة الماتشميكنج، جاري فحص وتنظيف الغرف المنتهية ---")
	
	if clear_all_rooms_on_start:
		clear_all_rooms_in_supabase()
	else:
		# نظام الحماية: حذف أي غرفة waiting مر عليها أكثر من 20 ثانية (خارجة عن القانون)
		delete_expired_rooms_on_server()
	
	search_timer = Timer.new()
	search_timer.wait_time = 1.0
	search_timer.autostart = true
	search_timer.timeout.connect(_on_timer_tick)
	add_child(search_timer)
	
	if status_label: status_label.text = "جاري البحث عن لاعبين..."
	if timer_label: timer_label.text = str(int(time_left))
	
	CloudManager.current_match_id = -1
	search_for_real_match()

# نظام الحماية: البحث عن الغرف التي تجاوزت 20 ثانية وحذفها
func delete_expired_rooms_on_server() -> void:
	var req = HTTPRequest.new()
	add_child(req)
	
	# نطلب الغرف الـ waiting التي تم إنشاؤها قبل أكثر من 20 ثانية (عبر مقارنة الوقت في PostgreSQL/Supabase)
	# أو نقوم بحذف الغرف القديمة باستخدام فلتر الـ lt (Less Than) لو عمود created_at متوفر
	# صيغة بوستجريس لحذف ما تجاوز 20 ثانية: created_at=lt.now() - interval '20 seconds'
	var cleanup_url = CloudManager.matches_url + "?status=eq.waiting&created_at=lt.now()-%20interval%20'20%20seconds'"
	
	req.request(cleanup_url, CloudManager.headers, HTTPClient.METHOD_DELETE)
	await req.request_completed
	req.queue_free()
	print("تم فحص الغرف المعلقة وحذف الخارجة عن القانون بنجاح!")

func _exit_tree() -> void:
	if match_started: return
	if CloudManager.current_match_id != -1:
		print("اللاعب خرج قبل اكتمال الماتش، جاري حذف غرفته...")
		var delete_url = CloudManager.matches_url + "?id=eq." + str(CloudManager.current_match_id)
		var req = HTTPRequest.new()
		get_tree().root.add_child(req)
		req.request(delete_url, CloudManager.headers.duplicate(), HTTPClient.METHOD_DELETE)

func clear_all_rooms_in_supabase() -> void:
	var req = HTTPRequest.new()
	add_child(req)
	var delete_url = CloudManager.matches_url + "?id=gt.0"
	req.request(delete_url, CloudManager.headers, HTTPClient.METHOD_DELETE)
	await req.request_completed
	req.queue_free()
	print("تم تنظيف ومسح جميع الغرف بنجاح!")

func _on_timer_tick() -> void:
	if match_started: return
	
	time_left -= 1.0
	if timer_label: timer_label.text = str(int(time_left))
	
	if time_left <= 0:
		match_started = true
		search_timer.stop()
		if poll_timer: poll_timer.stop()
		print("خلص الوقت وما لقينا أحد، جاري تحويلك للعب ضد بوت وحذف غرفتك المعلقة...")
		cancel_real_match_and_play_bot()

func search_for_real_match() -> void:
	var req = HTTPRequest.new()
	add_child(req)
	var query_url = CloudManager.matches_url + "?status=eq.waiting&limit=1"
	
	var err = req.request(query_url, CloudManager.headers, HTTPClient.METHOD_GET)
	if err != OK:
		req.queue_free()
		create_waiting_match()
		return
		
	var response = await req.request_completed
	req.queue_free()
	
	var found_match = false
	if response.size() >= 2 and response[1] == 200:
		var json = JSON.new()
		if json.parse(response[3].get_string_from_utf8()) == OK:
			var data = json.get_data()
			if not data.is_empty():
				print("لقد تم العثور على غرفة مفتوحة للانضمام!")
				found_match = true
				if not match_started:
					join_match(data[0])
				
	if not found_match and not match_started:
		print("ما فيه غرف مفتوحة، جاري إنشاء غرفة جديدة باسمك...")
		create_waiting_match()

func join_match(match_data: Dictionary) -> void:
	match_started = true
	if search_timer: search_timer.stop()
	if status_label: status_label.text = "تم العثور على خصم! جاري الاتصال..."
	
	var match_id = int(match_data.get("id", -1))
	var body = JSON.stringify({
		"player2_name": str(CloudManager.current_player_name),
		"status": "in_progress"
	})
	
	var req = HTTPRequest.new()
	add_child(req)
	var update_url = CloudManager.matches_url + "?id=eq." + str(match_id)
	req.request(update_url, CloudManager.headers.duplicate(), HTTPClient.METHOD_PATCH, body)
	await req.request_completed
	req.queue_free()
	
	CloudManager.current_match_id = match_id
	CloudManager.is_player_one = false
	CloudManager.is_multiplayer_match = true
	CloudManager.enemy_is_bot = false
	CloudManager.enemy_name = match_data.get("player1_name", "لاعب")
	CloudManager.match_mode = match_data.get("match_mode", "kill_count")
	CloudManager.match_goal = int(match_data.get("match_goal", 20))
	CloudManager.match_time_limit = 0 if CloudManager.match_mode == "kill_count" else 120
	
	start_game()

func create_waiting_match() -> void:
	var modes = ["kill_count", "wave_survival"]
	var selected_mode = modes[randi() % modes.size()]
	var selected_goal = 20
	
	if selected_mode == "kill_count":
		if possible_kill_goals.is_empty(): possible_kill_goals = [20]
		selected_goal = possible_kill_goals[randi() % possible_kill_goals.size()]
	else:
		if possible_wave_goals.is_empty(): possible_wave_goals = [3]
		selected_goal = possible_wave_goals[randi() % possible_wave_goals.size()]
	
	var dict_body = {
		"player1_name": str(CloudManager.current_player_name),
		"player2_name": "", 
		"status": "waiting",
		"match_mode": str(selected_mode),
		"match_goal": int(selected_goal),
		"player1_score": 0,
		"player2_score": 0
	}
	var body = JSON.stringify(dict_body)
	
	var req = HTTPRequest.new()
	add_child(req)
	req.request(CloudManager.matches_url, CloudManager.headers, HTTPClient.METHOD_POST, body)
	var response = await req.request_completed
	req.queue_free()
	
	if response.size() >= 2:
		if response[1] == 201 or response[1] == 200:
			if not match_started:
				fetch_latest_my_match()
				
				CloudManager.is_player_one = true
				CloudManager.is_multiplayer_match = true
				CloudManager.enemy_is_bot = false
				CloudManager.match_mode = selected_mode
				CloudManager.match_goal = selected_goal
				CloudManager.match_time_limit = 0 if selected_mode == "kill_count" else 120
				
				print("تم إنشاء الغرفة بنجاح - جاري انتظار لاعب يشاركنا...")
				
				poll_timer = Timer.new()
				poll_timer.wait_time = 2.0
				poll_timer.autostart = true
				poll_timer.timeout.connect(check_if_someone_joined)
				add_child(poll_timer)
		else:
			print("خطأ من السيرفر. نص الاستجابة:", response[3].get_string_from_utf8())

func fetch_latest_my_match() -> void:
	var req = HTTPRequest.new()
	add_child(req)
	var url = CloudManager.matches_url + "?player1_name=eq." + CloudManager.current_player_name.uri_encode() + "&status=eq.waiting&order=id.desc&limit=1"
	req.request(url, CloudManager.headers, HTTPClient.METHOD_GET)
	var res = await req.request_completed
	req.queue_free()
	if res.size() >= 2 and res[1] == 200:
		var json = JSON.new()
		if json.parse(res[3].get_string_from_utf8()) == OK:
			var data = json.get_data()
			if not data.is_empty():
				CloudManager.current_match_id = int(data[0].get("id", -1))
				print("تم جلب ID الغرفة الخاصة بك بنجاح: ", CloudManager.current_match_id)

func check_if_someone_joined() -> void:
	if match_started or CloudManager.current_match_id == -1: return
	
	var query_url = CloudManager.matches_url + "?id=eq." + str(CloudManager.current_match_id)
	var p_http = HTTPRequest.new()
	add_child(p_http)
	p_http.request(query_url, CloudManager.headers, HTTPClient.METHOD_GET)
	var response = await p_http.request_completed
	p_http.queue_free()
	
	if response.size() >= 2 and response[1] == 200:
		var json = JSON.new()
		if json.parse(response[3].get_string_from_utf8()) == OK:
			var data = json.get_data()
			if not data.is_empty() and data[0].get("status") == "in_progress":
				match_started = true
				if search_timer: search_timer.stop()
				if poll_timer: poll_timer.stop()
				CloudManager.enemy_name = data[0].get("player2_name", "لاعب")
				print("يا سلام! انضم لاعب حقيقي للغرفة: ", CloudManager.enemy_name)
				if status_label: status_label.text = "جاري التجهيز.."
				start_game()

func cancel_real_match_and_play_bot() -> void:
	if status_label: status_label.text = " جاري التجهيز.."
	
	if CloudManager.current_match_id != -1:
		print("جاري حذف الغرفة التي تحمل ID رقم: ", CloudManager.current_match_id)
		var delete_url = CloudManager.matches_url + "?id=eq." + str(CloudManager.current_match_id)
		var c_http = HTTPRequest.new()
		add_child(c_http)
		c_http.request(delete_url, CloudManager.headers.duplicate(), HTTPClient.METHOD_DELETE)
	
	create_bot_match()

func create_bot_match() -> void:
	print("تم التحويل للعب ضد بوت محلي.")
	CloudManager.is_multiplayer_match = true
	CloudManager.enemy_is_bot = true
	CloudManager.enemy_bot_difficulty = randi() % 3 
	
	if bot_names.is_empty(): bot_names = ["بوت"]
	CloudManager.enemy_name = bot_names[randi() % bot_names.size()]
	
	var game_modes_arr = ["kill_count", "wave_survival"]
	CloudManager.match_mode = game_modes_arr[randi() % game_modes_arr.size()]
	
	var selected_goal = 20
	
	if CloudManager.match_mode == "kill_count":
		if possible_kill_goals.is_empty(): possible_kill_goals = [20]
		selected_goal = possible_kill_goals[randi() % possible_kill_goals.size()]
		CloudManager.match_goal = selected_goal
		CloudManager.match_time_limit = 0 
		CloudManager.current_bot_delay = bot_kill_delays[CloudManager.enemy_bot_difficulty]
	else:
		if possible_wave_goals.is_empty(): possible_wave_goals = [3]
		selected_goal = possible_wave_goals[randi() % possible_wave_goals.size()]
		CloudManager.match_goal = selected_goal
		CloudManager.match_time_limit = 120 
		CloudManager.current_bot_delay = bot_wave_delays[CloudManager.enemy_bot_difficulty]
		
	start_game()

func start_game() -> void:
	await get_tree().create_timer(1.0).timeout
	if multiplayer_game_scene != "":
		get_tree().change_scene_to_file(multiplayer_game_scene)
	else:
		print("خطأ تذكير: يرجى ربط مشهد multiplayer_game.tscn في خانة الـ Inspector باللعبة!")
