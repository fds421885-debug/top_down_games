class_name CharacterData
extends Resource

## معرف فريد للشخصية (يُستخدم للحفظ بالسحابة) - لازم يكون مختلف عن كل الباقي
## الشخصية الافتراضية المجانية لازم يكون معرفها "default"
@export var character_id: String = ""

## اسم الشخصية الظاهر للاعب في المتجر
@export var display_name: String = "المحارب"

## سعر فتح الشخصية بالفلوس - خليه 0 للشخصية الافتراضية/المجانية
@export var price: int = 0

## أيقونة مصغّرة تظهر في صف المتجر
@export var icon: Texture2D

## فريمات الأنميشن الخاصة بهالشخصية - تُستخدم في اللعب الفعلي وفي المعاينة بالمتجر
## لازم تحتوي نفس أسماء الأنميشن المستخدمة بسكربت اللاعب (مثلاً: idle, run, attack)
@export var sprite_frames: SpriteFrames

## اسم الأنميشن اللي يتشغل وقت المعاينة بالمتجر (عادةً "idle")
@export var preview_animation: String = "idle"

## قائمة التطويرات الخاصة بهذي الشخصية فقط (كل شخصية عندها تطويراتها ومستوياتها المستقلة)
@export var upgrades: Array[UpgradeData] = []
