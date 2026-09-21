extends Control

@export_category("عناصر الواجهة العامة")
@export var money_label: Label
@export var close_button: Button
@export_file("*.tscn") var main_menu_scene: String = "res://Scenes/main_menu.tscn"

@export_category("معاينة الشخصية (أعلى يمين المتجر)")
@export var preview_animated_sprite: AnimatedSprite2D

@export_category("أزرار التبويبات")
@export var tab_upgrades_button: Button
@export var tab_skins_button: Button

@export_category("حاويات العرض - كل وحدة لازم تكون جوة ScrollContainer عشان تتحرك فوق وتحت")
@export var upgrades_scroll: ScrollContainer
@export var upgrades_list: VBoxContainer
@export var skins_scroll: ScrollContainer
@export var skins_list: VBoxContainer

@export_category("بيانات المتجر (Resources تشتغل زي ScriptableObject)")
@export var item_row_scene: PackedScene   # مشهد الصف (شوف 05_shop_item_row.gd)
@export var characters: Array[CharacterData] = []

func _ready() -> void:
	if close_button:
		close_button.pressed.connect(_on_close_pressed)
	if tab_upgrades_button:
		tab_upgrades_button.pressed.connect(show_upgrades_tab)
	if tab_skins_button:
		tab_skins_button.pressed.connect(show_skins_tab)

	refresh_money_label()
	update_character_preview()
	show_upgrades_tab()

func _on_close_pressed() -> void:
	if main_menu_scene != "":
		get_tree().change_scene_to_file(main_menu_scene)

func refresh_money_label() -> void:
	if money_label:
		money_label.text = "رصيدك: " + str(CloudManager.money)

func find_character(character_id: String) -> CharacterData:
	for c in characters:
		if c.character_id == character_id:
			return c
	return null

func update_character_preview() -> void:
	if not preview_animated_sprite: return
	var selected_id = CloudManager.get_selected_character()
	var data = find_character(selected_id)
	if data and data.sprite_frames:
		preview_animated_sprite.sprite_frames = data.sprite_frames
		preview_animated_sprite.play(data.preview_animation)

# ============================================================
# التبويبات
# ============================================================
func show_upgrades_tab() -> void:
	if upgrades_scroll: upgrades_scroll.visible = true
	if skins_scroll: skins_scroll.visible = false
	build_upgrades_list()

func show_skins_tab() -> void:
	if upgrades_scroll: upgrades_scroll.visible = false
	if skins_scroll: skins_scroll.visible = true
	build_skins_list()

func clear_container(container: Node) -> void:
	for child in container.get_children():
		child.queue_free()

# ============================================================
# بناء قائمة التطويرات لِلشخصية المختارة حالياً
# ============================================================
func build_upgrades_list() -> void:
	if not upgrades_list or not item_row_scene: return
	clear_container(upgrades_list)

	var selected_id = CloudManager.get_selected_character()
	var char_data = find_character(selected_id)
	if not char_data:
		return

	for upgrade in char_data.upgrades:
		var row: ShopItemRow = item_row_scene.instantiate()
		upgrades_list.add_child(row)
		var current_level = CloudManager.get_upgrade_level(selected_id, upgrade.upgrade_id)
		row.setup_as_upgrade(upgrade, current_level)
		row.action_pressed.connect(_on_upgrade_row_pressed)

# ============================================================
# بناء قائمة الشخصيات/السكنز
# ============================================================
func build_skins_list() -> void:
	if not skins_list or not item_row_scene: return
	clear_container(skins_list)

	var selected_id = CloudManager.get_selected_character()

	for char_data in characters:
		var row: ShopItemRow = item_row_scene.instantiate()
		skins_list.add_child(row)
		var is_unlocked = char_data.price <= 0 or CloudManager.is_character_unlocked(char_data.character_id)
		var is_selected = (char_data.character_id == selected_id)
		row.setup_as_character(char_data, is_unlocked, is_selected)
		row.action_pressed.connect(_on_character_row_pressed)

# ============================================================
# ضغط زر تطوير
# ============================================================
func _on_upgrade_row_pressed(row: ShopItemRow) -> void:
	var upgrade: UpgradeData = row.upgrade_ref
	var selected_id = CloudManager.get_selected_character()
	var current_level = CloudManager.get_upgrade_level(selected_id, upgrade.upgrade_id)

	if current_level >= upgrade.max_level:
		return

	var price = upgrade.get_price_for_level(current_level)
	if CloudManager.spend_money(price):
		CloudManager.set_upgrade_level(selected_id, upgrade.upgrade_id, current_level + 1)
		CloudManager.sync_economy_to_server()
		refresh_money_label()
		row.refresh_upgrade_display(current_level + 1)
	else:
		flash_insufficient_funds(row)

# ============================================================
# ضغط زر شخصية (شراء أو اختيار)
# ============================================================
func _on_character_row_pressed(row: ShopItemRow) -> void:
	var char_data: CharacterData = row.character_ref
	var already_unlocked = char_data.price <= 0 or CloudManager.is_character_unlocked(char_data.character_id)

	if already_unlocked:
		CloudManager.select_character(char_data.character_id)
		CloudManager.sync_economy_to_server()
		update_character_preview()
		build_skins_list()
		return

	if CloudManager.spend_money(char_data.price):
		CloudManager.unlock_character(char_data.character_id)
		CloudManager.select_character(char_data.character_id)
		CloudManager.sync_economy_to_server()
		refresh_money_label()
		update_character_preview()
		build_skins_list()
	else:
		flash_insufficient_funds(row)

func flash_insufficient_funds(row: ShopItemRow) -> void:
	if not row: return
	var original_color = row.modulate
	row.modulate = Color.RED
	var tween = create_tween()
	tween.tween_property(row, "modulate", original_color, 0.4)
