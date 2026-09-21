class_name ShopItemRow
extends PanelContainer

signal action_pressed(row: ShopItemRow)

@export_category("عناصر الصف (اسحبها من نفس الصف)")
@export var icon_rect: TextureRect
@export var name_label: Label
@export var status_label: Label
@export var progress_label: Label
@export var action_button: Button

var upgrade_ref: UpgradeData
var character_ref: CharacterData
var row_kind: String = "" # "upgrade" أو "character"

func _ready() -> void:
	if action_button and not action_button.pressed.is_connected(_on_action_button_pressed):
		action_button.pressed.connect(_on_action_button_pressed)

func _on_action_button_pressed() -> void:
	action_pressed.emit(self)

# ============================================================
# وضع "تطوير قدرة"
# ============================================================
func setup_as_upgrade(data: UpgradeData, current_level: int) -> void:
	row_kind = "upgrade"
	upgrade_ref = data
	if icon_rect: icon_rect.texture = data.icon
	if name_label: name_label.text = data.display_name
	refresh_upgrade_display(current_level)

func refresh_upgrade_display(current_level: int) -> void:
	if not upgrade_ref: return
	var current_money: int = 0
	if typeof(CloudManager) != TYPE_NIL:
		current_money = CloudManager.money

	if current_level >= upgrade_ref.max_level:
		if status_label:
			status_label.text = "المستوى: " + str(current_level) + " / " + str(upgrade_ref.max_level) + " (مكتمل)"
		if progress_label:
			progress_label.text = ""
		if action_button:
			action_button.text = "مكتمل"
			action_button.disabled = true
		return

	var current_value = upgrade_ref.get_value_for_level(current_level)
	var next_value = upgrade_ref.get_value_for_level(current_level + 1)
	var price = upgrade_ref.get_price_for_level(current_level)

	if status_label:
		status_label.text = "المستوى " + str(current_level) + " → " + str(current_level + 1) + "   (" + str(current_value) + " ← " + str(next_value) + ")"

	if progress_label:
		if current_money >= price:
			progress_label.text = "السعر: " + str(price)
		else:
			progress_label.text = "السعر: " + str(price) + "  (باقي لك " + str(price - current_money) + ")"

	if action_button:
		action_button.text = "تطوير (" + str(price) + ")"
		action_button.disabled = current_money < price

# ============================================================
# وضع "شخصية/سكن"
# ============================================================
func setup_as_character(data: CharacterData, is_unlocked: bool, is_selected: bool) -> void:
	row_kind = "character"
	character_ref = data
	if icon_rect: icon_rect.texture = data.icon
	if name_label: name_label.text = data.display_name
	refresh_character_display(is_unlocked, is_selected)

func refresh_character_display(is_unlocked: bool, is_selected: bool) -> void:
	if not character_ref: return
	var current_money: int = 0
	if typeof(CloudManager) != TYPE_NIL:
		current_money = CloudManager.money

	if is_selected:
		if status_label: status_label.text = "مختارة الآن"
		if progress_label: progress_label.text = ""
		if action_button:
			action_button.text = "مُفعّلة"
			action_button.disabled = true
	elif is_unlocked:
		if status_label: status_label.text = "مملوكة"
		if progress_label: progress_label.text = ""
		if action_button:
			action_button.text = "اختيار"
			action_button.disabled = false
	else:
		if status_label: status_label.text = "مقفلة"
		if progress_label:
			if current_money >= character_ref.price:
				progress_label.text = "السعر: " + str(character_ref.price)
			else:
				progress_label.text = "السعر: " + str(character_ref.price) + "  (باقي لك " + str(character_ref.price - current_money) + ")"
		if action_button:
			action_button.text = "شراء (" + str(character_ref.price) + ")"
			action_button.disabled = current_money < character_ref.price
