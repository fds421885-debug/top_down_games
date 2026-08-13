extends Node

# حط روابطك هنا
const SUPABASE_URL = "https://rtnvmeuomvnizlmfbqhb.supabase.co"
const SUPABASE_KEY = "حط_مفتاحك_الطويل_هنا"

var table_url = SUPABASE_URL + "/rest/v1/cloud_saves"

var headers = [
	"apikey: " + SUPABASE_KEY,
	"Authorization: Bearer " + SUPABASE_KEY,
	"Content-Type: application/json",
	"Prefer: return=representation"
]

var http_request: HTTPRequest

# بيانات اللاعب الحالية (بتكون محفوظة هنا طول ما اللعبة شغالة)
var current_email: String = ""
var current_player_name: String = ""
var current_wave: int = 1
var current_kills: int = 0

func _ready():
	http_request = HTTPRequest.new()
	add_child(http_request)

# 1. دالة تسجيل الدخول (تفحص إذا الحساب موجود أو جديد)
# ترجع Dictionary فيه الحالة
func login_or_register(email: String) -> Dictionary:
	current_email = email
	var query_url = table_url + "?email=eq." + email.uri_encode()
	
	var err = http_request.request(query_url, headers, HTTPClient.METHOD_GET)
	if err != OK: return {"success": false, "message": "خطأ في الاتصال بالنت"}
		
	var response = await http_request.request_completed
	var code = response[1]
	var body = response[3].get_string_from_utf8()
	
	if code == 200:
		var json = JSON.new()
		json.parse(body)
		var data = json.get_data()
		
		if data.is_empty():
			# الحساب جديد، ما لقيناه في السحابة
			return {"success": true, "is_new": true}
		else:
			# الحساب قديم وموجود! نحمل بياناته
			current_player_name = data[0].get("player_name", "")
			current_wave = int(data[0].get("wave", 1))
			current_kills = int(data[0].get("kills", 0))
			return {"success": true, "is_new": false}
			
	return {"success": false, "message": "خطأ من السيرفر"}

# 2. دالة حفظ اسم اللاعب الجديد في السحابة
func save_new_player(player_name: String) -> bool:
	current_player_name = player_name
	
	var body = JSON.stringify({
		"email": current_email,
		"player_name": current_player_name,
		"wave": 1,
		"kills": 0
	})
	
	var err = http_request.request(table_url, headers, HTTPClient.METHOD_POST, body)
	if err != OK: return false
	
	var response = await http_request.request_completed
	return response[1] == 201 or response[1] == 200

# 3. دالة حفظ التقدم (الويف والقتلات) على السحابة
func update_progress(new_wave: int, new_kills: int) -> void:
	current_wave = new_wave
	current_kills = new_kills
	
	var body = JSON.stringify({
		"wave": current_wave,
		"kills": current_kills
	})
	
	# نحدث البيانات بناءً على الإيميل
	var update_url = table_url + "?email=eq." + current_email.uri_encode()
	
	# نضيف هيدر جديد مخصص للتحديث في سوبابيس (PATCH)
	var patch_headers = headers.duplicate()
	
	http_request.request(update_url, patch_headers, HTTPClient.METHOD_PATCH, body)
	var response = await http_request.request_completed
	
	if response[1] == 200 or response[1] == 204:
		print("تم حفظ تقدمك في السحابة بنجاح! الويف: ", current_wave)
	else:
		print("فشل حفظ التقدم في السحابة.")
