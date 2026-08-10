extends Node2D

@export var spawn_markers: Array[Marker2D] # أماكن الرسبنة على الخريطة
@export var waves: Array[WaveData]         # قائمة الويفات المتتابعة

var current_wave: int = 0
var current_kills: int = 0
var timer: float = 0.0

func _ready() -> void:
	add_to_group("spawner")
	if not waves.is_empty():
		start_wave()

func start_wave() -> void:
	current_kills = 0
	print("--- بدء الويف: ", waves[current_wave].wave_title, " ---")

func _process(delta: float) -> void:
	if current_wave >= waves.size():
		return # انتهت جميع الويفات (فوز)
		
	var wave_data = waves[current_wave]
	
	timer += delta
	if timer >= wave_data.spawn_interval:
		timer = 0.0
		spawn_enemy(wave_data)

func spawn_enemy(wave_data: WaveData) -> void:
	if wave_data.enemy_types.is_empty() or spawn_markers.is_empty():
		return
		
	# اختيار العدو بناءً على الوزن (Weight) لترجيح كفة عدو معين
	var chosen_enemy = get_weighted_enemy(wave_data.enemy_types, wave_data.enemy_weights)
	if not chosen_enemy:
		return
		
	# اختيار نقطة رسبنة عشوائية من الـ Markers اللي حددتها
	var random_marker = spawn_markers[randi() % spawn_markers.size()]
	
	var enemy_instance = chosen_enemy.instantiate()
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
	print("القتلى: ", current_kills, " / ", wave_data.kills_to_advance)
	
	if current_kills >= wave_data.kills_to_advance:
		advance_to_next_wave()

func advance_to_next_wave() -> void:
	current_wave += 1
	if current_wave < waves.size():
		start_wave()
	else:
		print("مبروك! أنهيت جميع الويفات بنجاح!")
 
