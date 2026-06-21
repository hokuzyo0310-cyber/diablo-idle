# ============================================================
# InventoryPanel.gd - 背包/装备管理面板
# 功能：
#   - 列表显示背包中所有物品（按稀有度颜色标识）
#   - 点击物品查看详情 Tooltip
#   - 装备/卸下/出售操作
#   - 排序/筛选（按稀有度、槽位、新增）
# ============================================================
# 依赖：
#   - GameManager: 物品数据源 (inventory, equipped_items)
#   - EventBus: 装备变更事件
# ============================================================
extends Control

# ============================================================
# UI 节点
# ============================================================
var item_list: ItemList                # 物品列表
var detail_panel: Control              # 右侧物品详情面板
var detail_label: Label                # 详情文本
var count_label: Label                 # 物品总数标签

# 排序/筛选控件
var sort_btn: OptionButton             # 排序方式下拉
var filter_btn: OptionButton           # 稀有度筛选下拉

# ============================================================
# 状态
# ============================================================
var selected_item_index: int = -1     # 当前选中物品索引
var current_items: Array = []          # 当前筛选/排序后的物品缓存
var current_sort_mode: String = "rarity"  # rarity / slot / new
var current_filter_rarity: String = "全部"  # 全部 / 普通 / 魔法 / ...

# ============================================================
# 初始化
# ============================================================
func _ready() -> void:
	# 面板背景
	var bg := ColorRect.new()
	bg.name = "PanelBG"
	bg.color = Color("#1a1210e6")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# 标题栏
	var title := Label.new()
	title.name = "Title"
	title.text = "== 背包 =="
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color("#c8a860"))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	title.offset_bottom = 36
	add_child(title)

	# 关闭按钮
	var close_btn := Button.new()
	close_btn.name = "CloseBtn"
	close_btn.text = "✕ 关闭"
	close_btn.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	close_btn.offset_top = 4
	close_btn.offset_bottom = 32
	close_btn.offset_right = -8
	close_btn.offset_left = close_btn.offset_right - 80
	close_btn.pressed.connect(queue_free)
	add_child(close_btn)

	# 工具栏
	_build_toolbar()

	# 主布局：左侧物品列表 + 右侧详情
	var main_layout := HBoxContainer.new()
	main_layout.name = "MainLayout"
	main_layout.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	main_layout.offset_top = 40
	main_layout.offset_left = 8
	main_layout.offset_right = -8
	main_layout.offset_bottom = -8
	main_layout.add_theme_constant_override("separation", 8)
	add_child(main_layout)

	# --- 左侧：物品列表 (使用 Godot 内置 ItemList) ---
	item_list = ItemList.new()
	item_list.name = "ItemList"
	item_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	item_list.size_flags_stretch_ratio = 3
	item_list.allow_reselect = true
	item_list.item_selected.connect(_on_item_selected)
	main_layout.add_child(item_list)

	# --- 右侧：物品详情 ---
	detail_panel = Control.new()
	detail_panel.name = "DetailPanel"
	detail_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_panel.size_flags_stretch_ratio = 2
	main_layout.add_child(detail_panel)

	var detail_title := Label.new()
	detail_title.name = "DetailTitle"
	detail_title.text = "物品详情"
	detail_title.add_theme_font_size_override("font_size", 16)
	detail_title.add_theme_color_override("font_color", Color("#c8a860"))
	detail_title.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	detail_title.offset_bottom = 28
	detail_panel.add_child(detail_title)

	detail_label = Label.new()
	detail_label.name = "DetailText"
	detail_label.add_theme_font_size_override("font_size", 13)
	detail_label.add_theme_color_override("font_color", Color.WHITE)
	detail_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	detail_label.offset_top = 32
	detail_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail_panel.add_child(detail_label)

	# 操作按钮行
	var btn_row := HBoxContainer.new()
	btn_row.name = "ActionButtons"
	btn_row.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	btn_row.offset_top = -36
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	detail_panel.add_child(btn_row)

	var equip_btn := Button.new()
	equip_btn.text = "装备"
	equip_btn.pressed.connect(_on_equip_pressed)
	btn_row.add_child(equip_btn)

	var sell_btn := Button.new()
	sell_btn.text = "出售"
	sell_btn.pressed.connect(_on_sell_pressed)
	btn_row.add_child(sell_btn)

	# 刷新列表 + 监听新掉落
	_refresh_item_list()
	EventBus.item_dropped.connect(_on_item_dropped)

func _on_item_dropped(_item: Dictionary) -> void:
	_refresh_item_list()


# ============================================================
# 工具栏
# ============================================================
func _build_toolbar() -> void:
	var toolbar := HBoxContainer.new()
	toolbar.name = "Toolbar"
	toolbar.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	toolbar.offset_top = 36
	toolbar.offset_bottom = 64
	toolbar.offset_left = 8
	toolbar.offset_right = -8
	add_child(toolbar)

	sort_btn = OptionButton.new()
	sort_btn.name = "SortBtn"
	sort_btn.add_item("按稀有度排序")
	sort_btn.add_item("按槽位排序")
	sort_btn.add_item("按最新排序")
	sort_btn.item_selected.connect(func(idx: int):
		match idx:
			0: current_sort_mode = "rarity"
			1: current_sort_mode = "slot"
			2: current_sort_mode = "new"
		_refresh_item_list()
	)
	toolbar.add_child(sort_btn)

	filter_btn = OptionButton.new()
	filter_btn.name = "FilterBtn"
	filter_btn.add_item("全部品质")
	var rarities := ["普通", "魔法", "稀有", "史诗", "传奇", "远古"]
	for r in rarities:
		filter_btn.add_item(r)
	filter_btn.item_selected.connect(func(idx: int):
		if idx == 0:
			current_filter_rarity = "全部"
		else:
			current_filter_rarity = rarities[idx - 1]
		_refresh_item_list()
	)
	toolbar.add_child(filter_btn)

	count_label = Label.new()
	count_label.name = "ItemCount"
	count_label.add_theme_color_override("font_color", Color("#8b7355"))
	toolbar.add_child(count_label)


# ============================================================
# 物品列表刷新
# ============================================================
func _refresh_item_list() -> void:
	item_list.clear()
	current_items = _get_filtered_sorted_items()

	var cnt: int = GameManager.inventory.size()
	var shown: int = current_items.size()
	count_label.text = "共 %d 件" % cnt
	print("[背包面板] 背包 %d 件，筛选后 %d 件" % [cnt, shown])

	if current_items.is_empty():
		item_list.add_item("（背包为空）", null, false)
		item_list.set_item_disabled(0, true)
		return

	var rarity_colors := {
		"普通": Color.WHITE,
		"魔法": Color("#4169e1"),
		"稀有": Color("#ffd700"),
		"史诗": Color("#daa520"),
		"传奇": Color("#ff8c00"),
		"远古": Color("#ff4444"),
	}

	for i in range(current_items.size()):
		var item: Dictionary = current_items[i]
		var name: String = item.get("display_name", item.get("base_name", "物品"))
		var rarity: String = item.get("rarity", "普通")
		var text: String = "%s  [Lv.%d %s]" % [name, item.get("item_level", 1), item.get("slot", "?")]
		item_list.add_item(text)
		item_list.set_item_custom_fg_color(i, rarity_colors.get(rarity, Color.WHITE))


func _get_filtered_sorted_items() -> Array:
	var items: Array = []
	for inv_item in GameManager.inventory:
		items.append(inv_item)

	if current_filter_rarity != "全部":
		var filtered: Array = []
		for d in items:
			if d.get("rarity", "普通") == current_filter_rarity:
				filtered.append(d)
		items = filtered

	if current_sort_mode == "rarity":
		var order := {"普通": 0, "魔法": 1, "稀有": 2, "史诗": 3, "传奇": 4, "远古": 5}
		for i in range(items.size()):
			for j in range(i + 1, items.size()):
				var ri: int = order.get(items[i].get("rarity", "普通"), 0)
				var rj: int = order.get(items[j].get("rarity", "普通"), 0)
				if ri < rj:
					var tmp = items[i]
					items[i] = items[j]
					items[j] = tmp

	return items


# ============================================================
# ItemList 选择回调
# ============================================================
func _on_item_selected(idx: int) -> void:
	if idx < 0 or idx >= current_items.size():
		return
	selected_item_index = idx
	_show_item_detail(current_items[idx])


# ============================================================
# 物品详情显示
# ============================================================
func _show_item_detail(item: Dictionary) -> void:
	var text := ""

	var name: String = item.get("display_name", item.get("base_name", "未知"))
	var rarity: String = item.get("rarity", "普通")
	text += "[%s] %s\n" % [rarity, name]
	text += "物品等级: %d\n\n" % item.get("item_level", 1)

	var stats: Dictionary = item.get("base_stats", {})
	if stats.get("min_damage", 0.0) > 0:
		text += "伤害: %.0f - %.0f\n" % [stats["min_damage"], stats["max_damage"]]
	if stats.get("defense", 0.0) > 0:
		text += "防御: %.0f\n" % stats["defense"]

	for affix in item.get("affixes", []):
		var affix_name: String = affix.get("name", "?")
		var stat_name: String = affix.get("stat", "?")
		var val: float = affix.get("value", 0.0)
		text += "%s: +%.1f %s\n" % [affix_name, val, stat_name]

	if item.get("has_unique_power", false):
		text += "\n[传奇能力] %s\n" % item.get("unique_power", "")

	text += "\n售价: %d 金币" % item.get("sell_price", 10)

	detail_label.text = text


# ============================================================
# 操作回调
# ============================================================
func _on_equip_pressed() -> void:
	if selected_item_index < 0 or selected_item_index >= current_items.size():
		return

	var item: Dictionary = current_items[selected_item_index]
	var slot: String = item.get("slot", "")

	# 检查该槽位是否已有装备 → 卸下
	if GameManager.equipped_items.has(slot) and not GameManager.equipped_items[slot].is_empty():
		GameManager.inventory.append(GameManager.equipped_items[slot])
		EventBus.item_unequipped.emit(GameManager.equipped_items[slot], slot)

	GameManager.equipped_items[slot] = item
	GameManager.inventory.erase(item)
	GameManager._recalculate_stats()
	EventBus.item_equipped.emit(item, slot)

	selected_item_index = -1
	_refresh_item_list()
	detail_label.text = "已装备: %s" % item.get("display_name", "")


func _on_sell_pressed() -> void:
	if selected_item_index < 0 or selected_item_index >= current_items.size():
		return

	var item: Dictionary = current_items[selected_item_index]
	var price: int = item.get("sell_price", 10)
	GameManager.add_gold(price)
	GameManager.inventory.erase(item)
	EventBus.item_sold.emit(item, price)

	selected_item_index = -1
	_refresh_item_list()
	detail_label.text = "已出售，获得 %d 金币" % price
