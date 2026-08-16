extends Node2D

@export var spawn_markers: Array[Marker2D] 
@export var waves: Array[WaveData]         
@export var wave_label: Label              

var current_wave: int = 0
var current_kills: int = 0 
var total_kills_session: int = 0 
var timer: float = 0.0

func _ready() -> void:
	add_to_group("spawner")
	
	if wave_label:
		wave_label.modulate.a = 0.0
	
	if typeof(CloudManager) != TYPE_NIL:
		if not CloudManager.is_multiplayer_match:
			if CloudManager.current_wave > 0:
				current_wave = CloudManager.current_wave - 1
				if current_wave < 0: current_wave = 0
			total_kills_session = CloudManager.current_kills
		else:
			current_wave = 0
			current_kills = 0
			total_kills_session = 0
	
	if not waves.is_empty():
		start_wave()

func start_wave() -> void:
	current_kills = 0 
	
	if current_wave >= waves.size():
		return
		
	var wave_data = waves[current_wave]
	print("--- بدء الويف: ", wave_data.wave_title, " ---")
	
	if wave_label:
		wave_label.modulate = Color.WHITE
		
	play_wave_intro(wave_data.wave_title)

func play_wave_intro(title_text: String) -> void:
	if not wave_label:
		return
		
	Engine.time_scale = 0.25
	
	wave_label.text = title_text
	wave_label.modulate.a = 1.0
	wave_label.scale = Vector2(0.5, 0.5)
	
	var tween = create_tween().set_ignore_time_scale(true)
	tween.tween_property(wave_label, "scale", Vector2(1.2, 1.2), 0.4).from(Vector2(0.5, 0.5))
	tween.tween_property(wave_label, "scale", Vector2(1.0, 1.0), 0.2)
	
	await get_tree().create_timer(1.5, false, true).timeout
	
	var fade_tween = create_tween().set_ignore_time_scale(true)
	fade_tween.tween_property(wave_label, "modulate:a", 0.0, 0.4)
	await fade_tween.finished
	
	Engine.time_scale = 1.0

func _process(delta: float) -> void:
	if current_wave >= waves.size():
		return
		
	var wave_data = waves[current_wave]
	
	timer += delta
	if timer >= wave_data.spawn_interval:
		timer = 0.0
		spawn_enemy(wave_data)

func spawn_enemy(wave_data: WaveData) -> void:
	if wave_data.enemy_types.is_empty() or spawn_markers.is_empty():
		return
		
	var chosen_enemy = get_weighted_enemy(wave_data.enemy_types, wave_data.enemy_weights)
	if not chosen_enemy:
		return
		
	var random_marker = spawn_markers[randi() % spawn_markers.size()]
	var enemy_instance = chosen_enemy.instantiate()
	
	var random_chance = randf()
	var chosen_target: Node2D = null
	
	if random_chance < 0.7:
		chosen_target = get_tree().get_first_node_in_group("tower")
		if not chosen_target:
			chosen_target = get_tree().get_first_node_in_group("player")
	else:
		chosen_target = get_tree().get_first_node_in_group("player")
		if not chosen_target:
			chosen_target = get_tree().get_first_node_in_group("tower")
			
	if enemy_instance.has_method("set_target"):
		enemy_instance.set_target(chosen_target)
	
	enemy_instance.global_position = random_marker.global_position
	get_tree().current_scene.add_child(enemy_instance)

func get_weighted_enemy(types: Array[PackedScene], weights: Array[int]) -> PackedScene:
	if types.size() != weights.size() or weights.is_empty():
		return types[0] if not types.is_empty() else null
		
	var total_weight = 0
	for w in weights:
		total_weight += w
		
	if total_weight <= 0:
		return types[0]
		
	var random_val = randi() % total_weight
	var current_sum = 0
	
	for i in range(types.size()):
		current_sum += weights[i]
		if random_val < current_sum:
			return types[i]
			
	return types[0]

func on_enemy_defeated() -> void:
	if current_wave >= waves.size():
		return
		
	current_kills += 1
	var wave_data = waves[current_wave]
	
	if typeof(CloudManager) != TYPE_NIL:
		if CloudManager.is_multiplayer_match:
			if CloudManager.match_mode == "kill_count":
				var mp_ui = get_tree().current_scene.get_node_or_null("MultiplayerUI")
				if mp_ui: mp_ui.add_player_score(1)
		else:
			total_kills_session += 1
			CloudManager.update_progress(current_wave + 1, total_kills_session)
	
	if current_kills >= wave_data.kills_to_advance:
		advance_to_next_wave()

func advance_to_next_wave() -> void:
	if typeof(CloudManager) != TYPE_NIL and CloudManager.is_multiplayer_match:
		if CloudManager.match_mode == "wave_survival":
			var mp_ui = get_tree().current_scene.get_node_or_null("MultiplayerUI")
			if mp_ui: mp_ui.add_player_score(1)
			
	current_wave += 1
	if current_wave < waves.size():
		if typeof(CloudManager) != TYPE_NIL and not CloudManager.is_multiplayer_match:
			CloudManager.update_progress(current_wave + 1, total_kills_session)
			
		start_wave()
	else:
		if wave_label:
			wave_label.modulate = Color.GREEN
		play_wave_intro("لقد أنهيت الخريطة!")
		
		# إذا خلصت الويفات في الأونلاين ولسه الجيم شغال، ننهيه ونحسب الفايز
		if typeof(CloudManager) != TYPE_NIL and CloudManager.is_multiplayer_match:
			var mp_ui = get_tree().current_scene.get_node_or_null("MultiplayerUI")
			if mp_ui and not mp_ui.game_ended:
				mp_ui.evaluate_winner_by_time()
