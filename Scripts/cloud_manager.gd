extends Node

const SUPABASE_URL = "https://rtnvmeuomvnizlmfbqhb.supabase.co"
const SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJ0bnZtZXVvbXZuaXpsbWZicWhiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODY2MzAxMzEsImV4cCI6MjEwMjIwNjEzMX0.rsmaV5XNttyhAlipAPREns29FQz6PkbjFjHlcg2d68o"
const LOCAL_SESSION_PATH = "user://player_session.json"
const OFFLINE_SAVE_PATH = "user://offline_save.json"

var table_url = SUPABASE_URL + "/rest/v1/cloud_saves"
var matches_url = SUPABASE_URL + "/rest/v1/active_matches" # رابط جدول الأونلاين الجديد

var headers = [
	"apikey: " + SUPABASE_KEY,
	"Authorization: Bearer " + SUPABASE_KEY,
	"Content-Type: application/json",
	"Prefer: return=representation"
]

var http_request: HTTPRequest

var current_email: String = ""
var current_player_name: String = ""
var current_wave: int = 1
var current_kills: int = 0
var is_offline_mode: bool = false

# --- متغيرات نظام الأونلاين (المباراة الحالية) ---
var is_multiplayer_match: bool = false
var match_mode: String = "" 
var match_goal: int = 0
var match_time_limit: int = 0
var enemy_is_bot: bool = false
var enemy_bot_difficulty: int = 0
var enemy_name: String = ""
var current_bot_delay: float = 2.0 

# متغيرات الأونلاين الحقيقي (Real Player)
var current_match_id: int = -1
var is_player_one: bool = true # يحدد إذا أنت راعي الغرفة أو اللي انضم
# ------------------------------------------------

func _ready():
	http_request = HTTPRequest.new()
	add_child(http_request)
	load_session()

# دالة تصفير ذاكرة اللاعب تماماً
func reset_player_memory():
	current_email = ""
	current_player_name = ""
	current_wave = 1
	current_kills = 0
	is_offline_mode = false

func generate_signature(wave: int, kills: int) -> String:
	var raw_string = str(wave) + "_" + str(kills) + "_GodotSecureToken2026"
	return raw_string.sha256_text()

func login_or_register(email: String) -> Dictionary:
	# خطوة جوهرية: نصفر كل القيم القديمة بالذاكرة فوراً قبل القراءة
	reset_player_memory()
	current_email = email
	
	var query_url = table_url + "?email=eq." + email.uri_encode()
	
	var err = http_request.request(query_url, headers, HTTPClient.METHOD_GET)
	if err != OK: 
		is_offline_mode = true
		return {"success": true, "is_new": false, "offline": true}
		
	var response = await http_request.request_completed
	var code = response[1]
	var body = response[3].get_string_from_utf8()
	
	if code == 200:
		is_offline_mode = false
		var json = JSON.new()
		if json.parse(body) == OK:
			var data = json.get_data()
			if data.is_empty():
				# حساب جديد: القيم مصفورة أساساً جاهزة
				return {"success": true, "is_new": true}
			else:
				# حساب قديم: نضع بيانات هذا الحساب فقط
				current_player_name = data[0].get("player_name", "")
				current_wave = int(data[0].get("wave", 1))
				current_kills = int(data[0].get("kills", 0))
				save_session()
				return {"success": true, "is_new": false}
				
	return {"success": false, "message": "فشل الاتصال بالسيرفر"}

func save_new_player(player_name: String) -> bool:
	current_player_name = player_name
	current_wave = 1
	current_kills = 0
	
	var body = JSON.stringify({
		"email": current_email,
		"player_name": current_player_name,
		"wave": 1,
		"kills": 0,
		"signature": generate_signature(1, 0)
	})
	
	var err = http_request.request(table_url, headers, HTTPClient.METHOD_POST, body)
	if err != OK: return false
	var response = await http_request.request_completed
	if response[1] == 201 or response[1] == 200:
		save_session()
		return true
	return false

func update_progress(new_wave: int, new_kills: int) -> void:
	# نمنع حفظ التقدم العادي إذا كنا نلعب أونلاين
	if is_multiplayer_match:
		return 

	current_wave = new_wave
	current_kills = new_kills
	save_session()
	
	if is_offline_mode: return
		
	var body = JSON.stringify({
		"wave": current_wave,
		"kills": current_kills,
		"signature": generate_signature(current_wave, current_kills)
	})
	
	var update_url = table_url + "?email=eq." + current_email.uri_encode()
	http_request.request(update_url, headers.duplicate(), HTTPClient.METHOD_PATCH, body)

# --- دوال الأونلاين الجديدة ---

# 1. تحديث النتيجة بعد ما تخلص مباراة الأونلاين
func update_multiplayer_result(is_winner: bool, points_gained: int) -> void:
	if is_winner:
		current_kills += points_gained
	else:
		current_kills -= 5
		if current_kills < 0: current_kills = 0
	
	# نقفل الغرفة بالسيرفر لو كانت ضد لاعب حقيقي
	if not enemy_is_bot and current_match_id != -1:
		end_real_match()
		
	is_multiplayer_match = false 
	update_progress(current_wave, current_kills)

# 2. إرسال نقاطك للسيرفر أثناء اللعب عشان يشوفها خصمك
func sync_my_score_to_server(my_score: int) -> void:
	if current_match_id == -1 or enemy_is_bot: return
	var score_field = "player1_score" if is_player_one else "player2_score"
	var body = JSON.stringify({ score_field: my_score })
	var update_url = matches_url + "?id=eq." + str(current_match_id)
	
	var temp_http = HTTPRequest.new()
	add_child(temp_http)
	temp_http.request(update_url, headers.duplicate(), HTTPClient.METHOD_PATCH, body)
	await temp_http.request_completed
	temp_http.queue_free()

# 3. إنهاء المباراة في السيرفر
func end_real_match() -> void:
	var body = JSON.stringify({ "status": "finished" })
	var update_url = matches_url + "?id=eq." + str(current_match_id)
	var temp_http = HTTPRequest.new()
	add_child(temp_http)
	temp_http.request(update_url, headers.duplicate(), HTTPClient.METHOD_PATCH, body)
	await temp_http.request_completed
	temp_http.queue_free()

# --------------------------------

func save_session():
	var save_dict = {
		"email": current_email,
		"name": current_player_name,
		"wave": current_wave,
		"kills": current_kills
	}
	var file = FileAccess.open(LOCAL_SESSION_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_dict))

func load_session():
	if FileAccess.file_exists(LOCAL_SESSION_PATH):
		var file = FileAccess.open(LOCAL_SESSION_PATH, FileAccess.READ)
		var json = JSON.new()
		if json.parse(file.get_as_text()) == OK:
			var data = json.get_data()
			current_email = data.get("email", "")
			current_player_name = data.get("name", "")
			current_wave = int(data.get("wave", 1))
			current_kills = int(data.get("kills", 0))

func logout():
	reset_player_memory()
	if FileAccess.file_exists(LOCAL_SESSION_PATH):
		DirAccess.remove_absolute(LOCAL_SESSION_PATH)
	if FileAccess.file_exists(OFFLINE_SAVE_PATH):
		DirAccess.remove_absolute(OFFLINE_SAVE_PATH)
	print("تم تسجيل الخروج وتصفير ذاكرة اللعبة تماماً.")

func fetch_leaderboard() -> Array:
	var req_url = table_url + "?select=player_name,wave,kills&order=wave.desc,kills.desc&limit=10"
	var temp_http = HTTPRequest.new()
	add_child(temp_http)
	temp_http.request(req_url, headers)
	var response = await temp_http.request_completed
	temp_http.queue_free()
	
	if response[1] == 200:
		var json = JSON.new()
		if json.parse(response[3].get_string_from_utf8()) == OK:
			return json.get_data()
	return []

func search_players_by_query(query_str: String) -> Array:
	var req_url = table_url + "?player_name=ilike.*" + query_str.uri_encode() + "*&select=player_name,wave,kills&order=wave.desc,kills.desc"
	var temp_http = HTTPRequest.new()
	add_child(temp_http)
	temp_http.request(req_url, headers)
	var response = await temp_http.request_completed
	temp_http.queue_free()
	
	if response[1] == 200:
		var json = JSON.new()
		if json.parse(response[3].get_string_from_utf8()) == OK:
			return json.get_data()
	return []
