class_name WaveData
extends Resource

@export var wave_title: String = "Wave 1"
@export var kills_to_advance: int = 15          # كم قتلة مطلوبة عشان تخلص الويف
@export var spawn_interval: float = 1.2        # سرعة خروج الأعداء (بالثواني)
@export var enemy_types: Array[PackedScene]    # أنواع الأعداء في هذا الويف
@export var enemy_weights: Array[int]          # نسبة ظهور كل عدو (الوزن الأعلى يظهر بكثرة)
