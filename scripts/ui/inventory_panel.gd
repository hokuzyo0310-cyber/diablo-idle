# ============================================================
# InventoryPanel.gd - 背包/装备管理面板
# 功能：
#   - 网格显示背包中所有物品（按稀有度颜色标识）
#   - 点击物品查看详情 Tooltip
#   - 装备/卸下/出售操作
#   - 排序/筛选（按稀有度、槽位、新增）
# ============================================================
# 依赖：
#   - GameManager: 物品数据源 (inventory, equipped_items)
#   - EventBus: 装备变更事件
#   - MathHelper: 数值格式化
#   - StringHelper: 物品 Tooltip 文本生成
# ============================================================
extends Control

# ============================================================
# UI 节点
# ============================================================
var item_list: VBoxContainer          # 物品列表容器（可滚动）
var scroll: ScrollContainer           # 滚动容器
var detail_panel: Control             # 右侧物品详情面板
var detail_labels: Array[Label]       # 详情文本行

# 排序/筛选控件
var sort_btn: OptionButton            # 排序方式下拉
var filter_btn: OptionButton          # 稀有度筛选下拉

# ============================================================
# 状态
# ============================================================
var selected_item_index: int = -1     # 当前选中物品索引
var current_sort_mode: String = "rarity"  # rarity / slot / new
var current_filter_rarity: String = "全部"  # 全部 / 普通 / 魔法 / ...

# ============================================================
# 初始化
# ============================================================
func _ready() -> void:
    # 面板背景（暗石板色）
    var bg := ColorRect.new()
    bg.name = "PanelBG"
    bg.color = Color("#1a1210e6")  # 半透明深色背景
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

    # 工具栏（排序 + 筛选）
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

    # --- 左侧：物品列表（可滚动） ---
    scroll = ScrollContainer.new()
    scroll.name = "ItemScroll"
    scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    scroll.size_flags_stretch_ratio = 3
    main_layout.add_child(scroll)

    item_list = VBoxContainer.new()
    item_list.name = "ItemList"
    item_list.add_theme_constant_override("separation", 2)
    scroll.add_child(item_list)

    # --- 右侧：物品详情 ---
    detail_panel = Control.new()
    detail_panel.name = "DetailPanel"
    detail_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    detail_panel.size_flags_stretch_ratio = 2
    main_layout.add_child(detail_panel)

    # 详情面板标题
    var detail_title := Label.new()
    detail_title.name = "DetailTitle"
    detail_title.text = "物品详情"
    detail_title.add_theme_font_size_override("font_size", 16)
    detail_title.add_theme_color_override("font_color", Color("#c8a860"))
    detail_title.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
    detail_title.offset_bottom = 28
    detail_panel.add_child(detail_title)

    # 详情文本
    var detail_text := Label.new()
    detail_text.name = "DetailText"
    detail_text.add_theme_font_size_override("font_size", 13)
    detail_text.add_theme_color_override("font_color", Color.WHITE)
    detail_text.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    detail_text.offset_top = 32
    detail_text.vertical_alignment = VERTICAL_ALIGNMENT_TOP
    detail_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    detail_panel.add_child(detail_text)
    detail_labels = [detail_text]

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

    var compare_btn := Button.new()
    compare_btn.text = "对比"
    compare_btn.pressed.connect(_on_compare_pressed)
    btn_row.add_child(compare_btn)

    var sell_btn := Button.new()
    sell_btn.text = "出售"
    sell_btn.pressed.connect(_on_sell_pressed)
    btn_row.add_child(sell_btn)

    # 刷新列表
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

    # 排序下拉
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

    # 稀有度筛选下拉
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

    # 物品总数标签
    var count_label := Label.new()
    count_label.name = "ItemCount"
    count_label.text = "共 %d 件" % GameManager.inventory.size()
    count_label.add_theme_color_override("font_color", Color("#8b7355"))
    toolbar.add_child(count_label)


# ============================================================
# 物品列表刷新
# ============================================================
func _refresh_item_list() -> void:
    # 清空现有列表
    for child in item_list.get_children():
        child.queue_free()

    var items := _get_filtered_sorted_items()

    if items.is_empty():
        var empty_label := Label.new()
        empty_label.text = "背包为空"
        empty_label.add_theme_color_override("font_color", Color.GRAY)
        item_list.add_child(empty_label)
        return

    for i in range(items.size()):
        var item: Dictionary = items[i]
        var btn := _make_item_button(item, i)
        item_list.add_child(btn)


func _get_filtered_sorted_items() -> Array:
    var items: Array = GameManager.inventory.duplicate()

    # 1. 稀有度筛选
    if current_filter_rarity != "全部":
        items = items.filter(func(d: Dictionary): return d.get("rarity", "普通") == current_filter_rarity)

    # 2. 排序
    var rarity_order := {"普通": 0, "魔法": 1, "稀有": 2, "史诗": 3, "传奇": 4, "远古": 5}
    match current_sort_mode:
        "rarity":
            items.sort_custom(func(a: Dictionary, b: Dictionary):
                return rarity_order.get(a.get("rarity", "普通"), 0) > rarity_order.get(b.get("rarity", "普通"), 0)
            )
        "slot":
            items.sort_custom(func(a: Dictionary, b: Dictionary):
                return a.get("slot", "") < b.get("slot", "")
            )
        # "new" 默认保持原始顺序（最近的在后面）
        _:
            pass

    return items


# ============================================================
# 物品按钮工厂 — 每个物品一行按钮，显示稀有度颜色
# ============================================================
func _make_item_button(item: Dictionary, index: int) -> Button:
    var btn := Button.new()
    btn.name = "Item_%d" % index

    # 按钮文本 = 物品名称
    var name := item.get("display_name", item.get("base_name", "物品"))
    btn.text = "%s  [Lv.%d %s]" % [name, item.get("item_level", 1), item.get("slot", "?")]
    btn.alignment = HORIZONTAL_ALIGNMENT_LEFT

    # 按稀有度着色
    var rarity := item.get("rarity", "普通")
    var rarity_colors := {
        "普通": Color.WHITE,
        "魔法": Color("#4169e1"),
        "稀有": Color("#ffd700"),
        "史诗": Color("#daa520"),
        "传奇": Color("#ff8c00"),
        "远古": Color("#ff4444"),
    }
    btn.add_theme_color_override("font_color", rarity_colors.get(rarity, Color.WHITE))
    btn.add_theme_font_size_override("font_size", 13)

    # 点击选中 → 显示详情
    btn.pressed.connect(func():
        selected_item_index = index
        _show_item_detail(item)
    )

    return btn


# ============================================================
# 物品详情显示
# ============================================================
func _show_item_detail(item: Dictionary) -> void:
    # 组装详情文本（Tooltip 格式）
    var text := ""

    # 名称（稀有度颜色）
    var name := item.get("display_name", item.get("base_name", "未知"))
    var rarity := item.get("rarity", "普通")
    text += "[%s] %s [/]\n" % [rarity, name]
    text += "物品等级: %d\n\n" % item.get("item_level", 1)

    # 基础属性
    var stats: Dictionary = item.get("base_stats", {})
    if stats.get("min_damage", 0.0) > 0:
        text += "伤害: %.0f - %.0f\n" % [stats["min_damage"], stats["max_damage"]]
    if stats.get("defense", 0.0) > 0:
        text += "防御: %.0f\n" % stats["defense"]

    # 词缀
    for affix in item.get("affixes", []):
        var affix_name := affix.get("name", "?")
        var stat_name := affix.get("stat", "?")
        var val := affix.get("value", 0.0)
        text += "%s: +%.1f %s\n" % [affix_name, val, stat_name]

    # 独特能力
    if item.get("has_unique_power", false):
        text += "\n[传奇能力] %s\n" % item.get("unique_power", "")

    # 售价
    text += "\n售价: %d 金币" % item.get("sell_price", 10)

    detail_labels[0].text = text


# ============================================================
# 操作回调
# ============================================================
func _on_equip_pressed() -> void:
    if selected_item_index < 0:
        return
    # 简化：直接装备选中物品
    var items := _get_filtered_sorted_items()
    if selected_item_index >= items.size():
        return

    var item: Dictionary = items[selected_item_index]
    var slot := item.get("slot", "")

    # 检查该槽位是否已有装备
    if GameManager.equipped_items.has(slot) and not GameManager.equipped_items[slot].is_empty():
        # 卸下旧装备 → 放回背包
        GameManager.inventory.append(GameManager.equipped_items[slot])
        EventBus.item_unequipped.emit(GameManager.equipped_items[slot], slot)

    # 装备新物品
    GameManager.equipped_items[slot] = item
    GameManager.inventory.erase(item)
    GameManager._recalculate_stats()
    EventBus.item_equipped.emit(item, slot)

    selected_item_index = -1
    _refresh_item_list()
    detail_labels[0].text = "已装备: %s" % item.get("display_name", "")

func _on_compare_pressed() -> void:
    if selected_item_index < 0:
        return
    var items := _get_filtered_sorted_items()
    if selected_item_index >= items.size():
        return

    var item: Dictionary = items[selected_item_index]
    var slot := item.get("slot", "")

    var text := "=== 对比 ===\n\n[新物品]\n"
    text += _format_item_short(item)

    if GameManager.equipped_items.has(slot) and not GameManager.equipped_items[slot].is_empty():
        text += "\n\n[当前装备]\n"
        text += _format_item_short(GameManager.equipped_items[slot])

    detail_labels[0].text = text

func _on_sell_pressed() -> void:
    if selected_item_index < 0:
        return
    var items := _get_filtered_sorted_items()
    if selected_item_index >= items.size():
        return

    var item: Dictionary = items[selected_item_index]
    var price := item.get("sell_price", 10)
    GameManager.add_gold(price)
    GameManager.inventory.erase(item)
    EventBus.item_sold.emit(item, price)

    selected_item_index = -1
    _refresh_item_list()
    detail_labels[0].text = "已出售，获得 %d 金币" % price

func _format_item_short(item: Dictionary) -> String:
    var text := "%s [Lv.%d]\n" % [item.get("display_name", "?"), item.get("item_level", 1)]
    var stats: Dictionary = item.get("base_stats", {})
    if stats.get("min_damage", 0.0) > 0:
        text += "伤害: %.0f-%.0f\n" % [stats["min_damage"], stats["max_damage"]]
    if stats.get("defense", 0.0) > 0:
        text += "防御: %.0f\n" % stats["defense"]
    return text
