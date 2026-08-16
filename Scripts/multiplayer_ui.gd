extends CanvasLayer

@export var mission_label: Label
@export var time_label: Label
@export var player_progress: ProgressBar
@export var enemy_progress: ProgressBar
@export var result_screen: Control 

var current_player_score: int = 0
var current_enemy_score: int = 0
var match_time: int = 0
var game_ended: bool = false

var bot_timer: Timer
var match_timer: Timer
var sync_timer: Timer 

func _ready() -> void:
	# أضفنا هذي عشان كود اللاعب يقدر يوصل لهالسكربت بسهولة ويبلغه بالخسارة
	add_to_group("multiplayer_manager")
	
	if not CloudManager.is_multiplayer_match:
		hide()
		return
		
	if player_progress: 
		player_progress.max_value = CloudManager.match_goal
		player_progress.value = 0
	if enemy_progress: 
		enemy_progress.max_value = CloudManager.match_goal
		enemy_progress.value = 0
	
	if mission_label:
		if CloudManager.match_mode == "kill_count":
			mission_label.text = "اقتل " + str(CloudManager.match_goal) + " عدو قبل " + CloudManager.enemy_name
		else:
			mission_label.text = "اصمد لـ " + str(CloudManager.match_goal) + " ويفات ضد " + CloudManager.enemy_name
		
	match_time = CloudManager.match_time_limit
	if match_time > 0:
		if time_label: time_label.text = str(match_time) + " ث"
		match_timer = Timer.new()
		match_timer.wait_time = 1.0
		match_timer.autostart = true
		match_timer.timeout.connect(_on_match_timer_tick)
		add_child(match_timer)
	else:
		if time_label: time_label.text = "وقت مفتوح"

	if CloudManager.enemy_is_bot:
		bot_timer = Timer.new()
		bot_timer.wait_time = CloudManager.current_bot_delay 
		bot_timer.autostart = true
		bot_timer.timeout.connect(_bot_progress_tick)
		add_child(bot_timer)
	else:
		sync_timer = Timer.new()
		sync_timer.wait_time = 2.0
		sync_timer.autostart = true
		sync_timer.timeout.connect(_sync_and_check_disconnect)
		add_child(sync_timer)

func _on_match_timer_tick() -> void:
	if game_ended: return
	match_time -= 1
	if time_label: time_label.text = str(match_time) + " ث"
	
	if match_time <= 0:
		evaluate_winner_by_time()

func add_player_score(amount: int = 1) -> void:
	if game_ended or not CloudManager.is_multiplayer_match: return
	
	current_player_score += amount
	if player_progress: player_progress.value = current_player_score
	
	if not CloudManager.enemy_is_bot:
		CloudManager.sync_my_score_to_server(current_player_score)
	
	if current_player_score >= CloudManager.match_goal:
		declare_winner("player")

func _bot_progress_tick() -> void:
	if game_ended: return
	
	if randf() > 0.15:
		current_enemy_score += 1
		if enemy_progress: enemy_progress.value = current_enemy_score
		
		if current_enemy_score >= CloudManager.match_goal:
			declare_winner("enemy")

func _sync_and_check_disconnect() -> void:
	if game_ended or CloudManager.current_match_id == -1: return
	
	var query_url = CloudManager.matches_url + "?id=eq." + str(CloudManager.current_match_id)
	var req = HTTPRequest.new()
	add_child(req)
	req.request(query_url, CloudManager.headers, HTTPClient.METHOD_GET)
	var response = await req.request_completed
	req.queue_free()
	
	if response.size() >= 2 and response[1] == 200:
		var json = JSON.new()
		if json.parse(response[3].get_string_from_utf8()) == OK:
			var data = json.get_data()
			if not data.is_empty():
				var match_status = data[0].get("status", "")
				
				if match_status == "cancelled" or match_status == "finished":
					print("انتهت المباراة أو انسحب الخصم من السيرفر!")
					declare_winner("player")
					return
				
				var enemy_score_field = "player2_score" if CloudManager.is_player_one else "player1_score"
				current_enemy_score = int(data[0].get(enemy_score_field, 0))
				
				if enemy_progress: enemy_progress.value = current_enemy_score
				
				if current_enemy_score >= CloudManager.match_goal:
					declare_winner("enemy")

func evaluate_winner_by_time() -> void:
	if current_player_score > current_enemy_score:
		declare_winner("player")
	elif current_enemy_score > current_player_score:
		declare_winner("enemy")
	else:
		declare_winner("draw")

func player_died() -> void:
	if not game_ended:
		print("تم تبليغ السكربت بخسارة اللاعب!")
		declare_winner("enemy")

func declare_winner(winner: String) -> void:
	if game_ended: return
	game_ended = true
	get_tree().paused = true 
	
	# إغلاق الغرفة في السيرفر فوراً لتصبح منتهية
	if not CloudManager.enemy_is_bot and CloudManager.current_match_id != -1:
		var finish_body = JSON.stringify({ "status": "finished" })
		var update_url = CloudManager.matches_url + "?id=eq." + str(CloudManager.current_match_id)
		var f_req = HTTPRequest.new()
		add_child(f_req)
		f_req.request(update_url, CloudManager.headers.duplicate(), HTTPClient.METHOD_PATCH, finish_body)
	
	var is_win = false
	var points = 0
	
	if winner == "player":
		is_win = true
		points = int(current_player_score / 2) 
		CloudManager.update_multiplayer_result(true, points)
	elif winner == "enemy":
		is_win = false
		points = 5 
		CloudManager.update_multiplayer_result(false, points)
	else:
		CloudManager.is_multiplayer_match = false
		is_win = false
		points = 0
		
	if result_screen:
		# نخلي شاشة النتيجة تشتغل حتى لو اللعبة (paused) عشان ما تعلق
		result_screen.process_mode = Node.PROCESS_MODE_ALWAYS
		result_screen.visible = true
		result_screen.show_result(is_win, points)
