class_name UpgradeData
extends Resource

## معرف فريد للتطوير (يُستخدم بالحفظ بالسحابة) - مثال: "speed" أو "max_health" أو "dash_cooldown"
@export var upgrade_id: String = ""

## الاسم الظاهر للاعب داخل المتجر
@export var display_name: String = "تطوير جديد"

## أيقونة التطوير (تظهر في صف المتجر)
@export var icon: Texture2D

## اسم المتغيّر (Export Variable) في سكربت اللاعب اللي بيتغيّر فعلياً، مثال: "max_speed"
## اتركه فاضي لو التطوير للعرض فقط بدون تأثير مباشر على متغير جاهز
@export var target_property: String = ""

## القيمة الأساسية قبل أي تطوير (تظهر بالمتجر كمرجع)
@export var base_value: float = 0.0

## مقدار الزيادة مع كل مستوى تطوير
@export var value_per_level: float = 10.0

## سعر أول مستوى تطوير
@export var base_price: int = 100

## كم يرتفع السعر مع كل مستوى إضافي
@export var price_increase_per_level: int = 50

## أعلى مستوى ممكن يوصله هذا التطوير (بعده الزر يوقف)
@export var max_level: int = 5

func get_price_for_level(current_level: int) -> int:
	return base_price + (price_increase_per_level * current_level)

func get_value_for_level(level: int) -> float:
	return base_value + (value_per_level * level)
