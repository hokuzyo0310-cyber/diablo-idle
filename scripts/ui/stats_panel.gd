# ============================================================
# StatsPanel.gd - 角色属性面板
# 功能：
#   - 显示四属性 STR/DEX/VIT/ENE 及其派生效果
#   - 属性点分配按钮（每级 5 点可自由分配）
#   - 显示装备纸娃娃（装备槽围绕角色）
#   - 详细战斗属性：DPS、生命、法力、抗性、MF、GF
# ============================================================
# 依赖：
#   - GameManager: 角色数据
#   - EventBus: 属性变更通知
#   - MathHelper: 数值格式化
# ============================================================
extends Control

# ============================================================
# UI 节点引用
# ============================================================
var attr_labels: Dictionary = {}     # "strength" → Label
var attr_buttons: Dictionary = {}    # "strength" → [-, +] Buttons
var unspent_label: Label             # 剩余属性点
var details_label: Label             # 派生属性详情
var class_label: Label               # 职业名称
var equipment_display: Control       # 装备纸娃娃容器

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
    title.text = "== 角色属性 =="
    title.add_theme_font_size_override("font_size", 20)
    title.add_theme_color_override("font_color", Color("#c8a860"))
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
    title.offset_bottom = 36
    add_child(title)

    # 关闭按钮
    var close_btn := Button.new()
    close_btn.text = "✕ 关闭"
    close_btn.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
    close_btn.offset_top = 4
    close_btn.offset_bottom = 32
    close_btn.offset_right = -8
    close_btn.offset_left = close_btn.offset_right - 80
    close_btn.pressed.connect(queue_free)
    add_child(close_btn)

    # 主布局（左右分栏）
    var main := HBoxContainer.new()
    main.name = "Main"
    main.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    main.offset_top = 40
    main.offset_left = 8
    main.offset_right = -8
    main.offset_bottom = -8
    main.add_theme_constant_override("separation", 12)
    add_child(main)

    # --- 左侧：属性分配 ---
    var left := _build_attribute_section()
    main.add_child(left)

    # --- 右侧：装备纸娃娃 + 派生属性 ---
    var right := VBoxContainer.new()
    right.name = "RightPanel"
    right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    right.size_flags_stretch_ratio = 1.0
    main.add_child(right)

    # 职业显示
    class_label = Label.new()
    class_label.name = "ClassLabel"
    class_label.add_theme_font_size_override("font_size", 16)
    class_label.add_theme_color_override("font_color", Color("#c8a860"))
    right.add_child(class_label)

    # 装备纸娃娃
    equipment_display = _build_equipment_display()
    right.add_child(equipment_display)

    # 派生属性详情
    details_label = Label.new()
    details_label.name = "Details"
    details_label.add_theme_font_size_override("font_size", 13)
    details_label.add_theme_color_override("font_color", Color.WHITE)
    details_label.autowrap_mode = TextServer.AUTOWRAP_OFF
    details_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
    right.add_child(details_label)

    # 初始刷新
    _refresh_all()


# ============================================================
# 左侧：属性分配区域
# ============================================================
func _build_attribute_section() -> VBoxContainer:
    var section := VBoxContainer.new()
    section.name = "AttrSection"
    section.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    section.size_flags_stretch_ratio = 1.5
    section.add_theme_constant_override("separation", 8)

    # 剩余属性点
    unspent_label = Label.new()
    unspent_label.name = "UnspentLabel"
    unspent_label.add_theme_font_size_override("font_size", 16)
    unspent_label.add_theme_color_override("font_color", Color("#ffd700"))
    section.add_child(unspent_label)

    # 四个属性行
    var attrs := [
        {"id": "strength",  "name": "力量 STR", "desc": "+1% 物理伤害/点"},
        {"id": "dexterity", "name": "敏捷 DEX", "desc": "+0.5% 暴击/点"},
        {"id": "vitality",  "name": "体力 VIT", "desc": "+4 生命/点"},
        {"id": "energy",    "name": "能量 ENE", "desc": "+2 法力, +1% 元素伤害/点"},
    ]

    for attr in attrs:
        var row := HBoxContainer.new()
        row.name = attr["id"].capitalize() + "Row"
        row.add_theme_constant_override("separation", 4)
        section.add_child(row)

        # 属性名称
        var name_label := Label.new()
        name_label.text = attr["name"]
        name_label.add_theme_font_size_override("font_size", 14)
        name_label.add_theme_color_override("font_color", Color("#c8a860"))
        name_label.custom_minimum_size = Vector2(100, 0)
        row.add_child(name_label)

        # - 按钮
        var minus := Button.new()
        minus.text = "−"
        minus.custom_minimum_size = Vector2(28, 28)
        minus.pressed.connect(Callable(self, "_on_attr_minus").bind(attr["id"]))
        row.add_child(minus)

        # 数值标签
        var val_label := Label.new()
        val_label.name = "Label_" + attr["id"]
        val_label.add_theme_font_size_override("font_size", 14)
        val_label.add_theme_color_override("font_color", Color.WHITE)
        val_label.custom_minimum_size = Vector2(40, 0)
        val_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        row.add_child(val_label)
        attr_labels[attr["id"]] = val_label

        # + 按钮
        var plus := Button.new()
        plus.text = "+"
        plus.custom_minimum_size = Vector2(28, 28)
        plus.pressed.connect(Callable(self, "_on_attr_plus").bind(attr["id"]))
        row.add_child(plus)

        # 说明
        var desc := Label.new()
        desc.text = attr["desc"]
        desc.add_theme_font_size_override("font_size", 11)
        desc.add_theme_color_override("font_color", Color("#8b7355"))
        row.add_child(desc)

        attr_buttons[attr["id"]] = {"minus": minus, "plus": plus}

    return section


# ============================================================
# 右侧：装备纸娃娃（装备槽环绕角色）
# ============================================================
func _build_equipment_display() -> Control:
    var container := Control.new()
    container.name = "EquipmentPaperDoll"
    container.custom_minimum_size = Vector2(200, 280)

    # 装备槽位定义：位置 (x, y) 相对纸娃娃中心
    var slots := {
        "head":         Vector2(100, 10),    # 头盔
        "neck":         Vector2(100, 52),    # 项链
        "weapon_main":  Vector2(14, 120),    # 主手武器
        "body":         Vector2(100, 110),   # 盔甲
        "offhand":      Vector2(186, 120),   # 副手
        "hands":        Vector2(14, 170),    # 手套
        "ring_1":       Vector2(50, 170),    # 戒指 1
        "ring_2":       Vector2(150, 170),   # 戒指 2
        "belt":         Vector2(100, 210),   # 腰带
        "feet":         Vector2(100, 250),   # 靴子
    }

    for slot_name in slots:
        var pos: Vector2 = slots[slot_name]
        var slot_rect := ColorRect.new()
        slot_rect.name = "Slot_" + slot_name
        slot_rect.color = Color("#2d2120")
        slot_rect.custom_minimum_size = Vector2(36, 36)
        slot_rect.position = pos - Vector2(18, 18)

        # 已装备物品提示
        var item := GameManager.equipped_items.get(slot_name, {})
        if not item.is_empty():
            slot_rect.color = Color("#3a2a28")
            # 物品名称小标签
            var lbl := Label.new()
            lbl.name = "EqName_" + slot_name
            lbl.text = item.get("base_name", "?")
            lbl.add_theme_font_size_override("font_size", 9)
            lbl.add_theme_color_override("font_color", Color("#c8a860"))
            lbl.position = Vector2(-10, 34)
            slot_rect.add_child(lbl)

        # slot_name 的小标签
        var slot_label := Label.new()
        slot_label.name = "SlotLabel_" + slot_name
        slot_label.text = slot_name.left(3)
        slot_label.add_theme_font_size_override("font_size", 8)
        slot_label.add_theme_color_override("font_color", Color("#8b7355"))
        slot_label.position = Vector2(0, -10)
        slot_rect.add_child(slot_label)

        container.add_child(slot_rect)

    return container


# ============================================================
# 刷新所有显示
# ============================================================
func _refresh_all() -> void:
    _update_attr_labels()
    _update_unspent_label()
    _update_details()
    _update_class_label()
    _update_equipment_display()


# 更新四个属性的数值标签
func _update_attr_labels() -> void:
    attr_labels["strength"].text = str(GameManager.strength)
    attr_labels["dexterity"].text = str(GameManager.dexterity)
    attr_labels["vitality"].text = str(GameManager.vitality)
    attr_labels["energy"].text = str(GameManager.energy)

# 更新剩余属性点标签
func _update_unspent_label() -> void:
    unspent_label.text = "剩余属性点: %d" % GameManager.unspent_points

# 更新职业标签
func _update_class_label() -> void:
    var class_name := "未选择"
    match GameManager.character_class:
        "barbarian": class_name = "野蛮人 Barbarian"
        "sorceress": class_name = "法师 Sorceress"
        "necromancer": class_name = "死灵法师 Necromancer"
    class_label.text = class_name + "  Lv.%d" % GameManager.level

# 更新派生属性详情
func _update_details() -> void:
    var text := ""
    text += "=== 战斗属性 ===\n"
    text += "DPS: %s\n" % MathHelper.format_number(GameManager.dps)
    text += "生命: %.0f / %.0f\n" % [GameManager.current_health, GameManager.max_health]
    text += "法力: %.0f / %.0f\n" % [GameManager.current_mana, GameManager.max_mana]
    text += "经验: %.0f / %.0f\n" % [GameManager.experience, GameManager.experience_to_next]
    text += "金币产出/秒: %s\n" % MathHelper.format_number(GameManager.gold_per_second)
    text += "\n=== 进度 ===\n"
    text += "当前阶段: %d\n" % GameManager.current_stage
    text += "难度: %s\n" % GameManager.difficulty
    text += "总击杀: %d\n" % GameManager.total_kills
    text += "转生次数: %d\n" % GameManager.prestige_count

    details_label.text = text

# 更新装备纸娃娃显示
func _update_equipment_display() -> void:
    for child in equipment_display.get_children():
        # 更新每个槽位的颜色（有装备 = 亮色，无装备 = 暗色）
        for slot_rect in child.get_children():
            if slot_rect is Label and slot_rect.name.begins_with("EqName_"):
                var slot_name := slot_rect.name.replace("EqName_", "")
                var item := GameManager.equipped_items.get(slot_name, {})
                if not item.is_empty():
                    slot_rect.text = item.get("base_name", "?")
                    # 按稀有度着色
                    var rarity := item.get("rarity", "普通")
                    var colors := {
                        "普通": Color.WHITE,
                        "魔法": Color("#4169e1"),
                        "稀有": Color("#ffd700"),
                        "史诗": Color("#daa520"),
                        "传奇": Color("#ff8c00"),
                        "远古": Color("#ff4444"),
                    }
                    slot_rect.add_theme_color_override("font_color", colors.get(rarity, Color.WHITE))
                else:
                    slot_rect.text = "--"


# ============================================================
# 属性分配按钮回调
# ============================================================
func _on_attr_plus(attr: String) -> void:
    # 调用 GameManager 的属性分配方法
    if GameManager.allocate_attribute(attr):
        _refresh_all()
        # 通知 UI 其他部分刷新（如 HUD）
        EventBus.level_up.emit(GameManager.level)  # 借用信号触发刷新
    else:
        _show_warning("属性点不足！")

func _on_attr_minus(attr: String) -> void:
    # 注意：当前设计不支持收回属性点（暗黑经典规则：分配后不可撤回）
    _show_warning("属性点分配后无法收回")


# ============================================================
# 辅助方法
# ============================================================
func _show_warning(msg: String) -> void:
    var warn := Label.new()
    warn.text = msg
    warn.add_theme_color_override("font_color", Color.RED)
    warn.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    warn.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
    warn.offset_top = 36
    add_child(warn)
    # 2 秒后自动移除
    var timer := get_tree().create_timer(2.0)
    timer.timeout.connect(func():
        if is_instance_valid(warn):
            warn.queue_free()
    )
