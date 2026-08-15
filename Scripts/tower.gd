extends StaticBody2D

@export_category("Tower Health")
@export var max_health: int = 100
@export var health_bar: ProgressBar

var current_health: int = 100

func _ready() -> void:
	add_to_group("tower")
	current_health = max_health
	update_health_bar()

func take_damage(amount: int) -> void:
	current_health -= amount
	if current_health < 0:
		current_health = 0
		
	update_health_bar()
	print("البرج انضرب! الدم المتبقي: ", current_health)
	
	if current_health <= 0:
		destroy_tower()

func update_health_bar() -> void:
	if health_bar:
		health_bar.value = current_health
		if current_health <= 25:
			health_bar.modulate = Color.RED
		else:
			health_bar.modulate = Color.WHITE

func destroy_tower() -> void:
	print("دُمّر البرج! جاري إعادة تحميل المرحلة...")
	get_tree().reload_current_scene()
