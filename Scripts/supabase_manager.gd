extends Node

# رابط مشروعك (شلت الزيادة عشان يشتغل صح)
const SUPABASE_URL = "https://rtnvmeuomvnizlmfbqhb.supabase.co"

# مفتاحك اللي جبته
const SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJ0bnZtZXVvbXZuaXpsbWZicWhiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODY2MzAxMzEsImV4cCI6MjEwMjIwNjEzMX0.rsmaV5XNttyhAlipAPREns29FQz6PkbjFjHlcg2d68o"

# المسار المباشر لجدول الترتيب حقك
var table_url = SUPABASE_URL + "/rest/v1/leaderboard"

# التصاريح اللي ترسلها اللعبة للسيرفر عشان يقبل الطلب
var headers = [
	"apikey: " + SUPABASE_KEY,
	"Authorization: Bearer " + SUPABASE_KEY,
	"Content-Type: application/json",
	"Prefer: return=representation"
]

var http_request: HTTPRequest

func _ready():
	# نسوي عقدة اتصال بالنت برمجياً ونضيفها
	http_request = HTTPRequest.new()
	add_child(http_request)

# دالة رفع النتيجة لسوبابيس
func submit_score(player_name: String, wave: int, kills: int):
	# نحسب السكور بناءً على فكرتك الذكية (الويف * 100 ألف + القتلات)
	var final_score = (wave * 100000) + kills
	
	# نجهز البيانات كملف JSON
	var body = JSON.stringify({
		"player_name": player_name,
		"wave": wave,
		"kills": kills,
		"score": final_score
	})
	
	# نرسل البيانات
	var err = http_request.request(table_url, headers, HTTPClient.METHOD_POST, body)
	if err != OK:
		print("خطأ داخلي: ما قدرنا نرسل الطلب لسوبابيس.")
	else:
		# ننتظر رد السيرفر
		var response = await http_request.request_completed
		var response_code = response[1]
		
		# 201 يعني تم الإنشاء بنجاح، 200 يعني العملية تمت
		if response_code == 201 or response_code == 200:
			print("نجاح! تم رفع النتيجة لسوبابيس. السكور الإجمالي: ", final_score)
		else:
			print("فشل الرفع! كود الخطأ من السيرفر: ", response_code)
			var error_message = response[3].get_string_from_utf8()
			print("تفاصيل الخطأ: ", error_message)

# دالة جلب أفضل 10 لاعبين
func get_top_10() -> Array:
	# نطلب منه يرتب حسب السكور من الأعلى للأقل (desc) ويجيب 10 بس
	var query_url = table_url + "?select=*&order=score.desc&limit=10"
	
	var err = http_request.request(query_url, headers, HTTPClient.METHOD_GET)
	if err != OK:
		print("خطأ داخلي: ما قدرنا نطلب قائمة التوب 10.")
		return []
		
	var response = await http_request.request_completed
	var response_code = response[1]
	var body = response[3]
	
	if response_code == 200:
		var json = JSON.new()
		var parse_err = json.parse(body.get_string_from_utf8())
		if parse_err == OK:
			return json.get_data() # نرجع البيانات كمصفوفة
	
	print("فشل جلب قائمة التوب 10! كود الخطأ: ", response_code)
	return []
