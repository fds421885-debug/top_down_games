extends Node

# --- إعدادات الشبكة والغرف ---
const PORT = 8910
const MAX_PLAYERS = 4

var peer = ENetMultiplayerPeer.new()
var is_host: bool = false
var room_code: String = ""
var current_mode: String = "" # "1v1", "2v2", "friends"
var is_bot_match: bool = false

# إشارات (Signals) عشان نربط الواجهة (UI) بالتحديثات لحظة بلحظة
signal matchmaking_status_changed(text: String)
signal match_found_successfully(is_bot: bool)
signal room_created_ui(code: String)

# ==========================================
# 1. نظام الماتشميكنج (1v1 أو 2v2)
# ==========================================
func start_matchmaking(mode: String) -> void:
	current_mode = mode
	is_host = false
	is_bot_match = false
	
	emit_matchmaking_status("جاري البحث عن لاعبين في نطاق (MENA)...")
	
	# عداد البحث لمدة 15 ثانية عن لاعبين حقيقيين
	var search_timer = get_tree().create_timer(15.0)
	await search_timer.timeout
	
	# لو خلصت ال15 ثانية وما لقينا أحد، ندخل في العداد العشوائي للبوتات (من 1 إلى 5 ثواني)
	var random_fallback_delay = randi_range(1, 5)
	emit_matchmaking_status("لم يتم العثور على لاعبين، جاري تحضير الخصوم...")
	await get_tree().create_timer(float(random_fallback_delay)).timeout
	
	# تحويل اللاعب للعب ضد بوتات بنظام محلي
	is_bot_match = true
	is_host = true # اللاعب هو الهوست المحلي للعبة البوتات
	emit_signal("match_found_successfully", true)
	print("تم تفعيل مباراة البوتات بنجاح. أنت الهوست.")

# ==========================================
# 2. نظام اللعب مع الأصدقاء (غرفة خاصة برمز 6 أرقام)
# ==========================================
func create_friend_room(mode: String) -> void:
	current_mode = mode
	is_host = true
	is_bot_match = false
	
	# توليد رمز عشوائي من 6 أرقام فريد من نوعه
	room_code = str(randi_range(100000, 999999))
	
	# فتح السيرفر المحلي لجهاز اللاعب
	var err = peer.create_server(PORT, MAX_PLAYERS)
	if err == OK:
		get_tree().multiplayer.multiplayer_peer = peer
		print("تم إنشاء غرفة الأصدقاء بنجاح برمز: ", room_code)
		emit_signal("room_created_ui", room_code)
	else:
		print("فشل إنشاء الغرفة المحلية!")

func join_friend_room(code: String, host_ip: String) -> void:
	room_code = code
	is_host = false
	is_bot_match = false
	
	peer.create_client(host_ip, PORT)
	get_tree().multiplayer.multiplayer_peer = peer
	print("جاري الانضمام لغرفة الصديق برمز: ", code)

# ==========================================
# 3. بدء المعركة من الهوست
# ==========================================
func host_start_friend_match() -> void:
	if not is_host: return
	
	print("الهوست ضغط بدء اللعب! عداد 5 ثواني لتثبيت الاتصال...")
	await get_tree().create_timer(5.0).timeout
	
	# هنا يتم نقل اللاعبين لمشهد المعركة لاحقاً
	print("جاري الانتقال لمشهد المعركة...")

func emit_matchmaking_status(text: String) -> void:
	emit_signal("matchmatchmaking_status_changed", text)
	print(text)
