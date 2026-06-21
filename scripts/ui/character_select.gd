# ============================================================
# CharacterSelect.gd - 角色职业选择界面
# 功能：
#   - 展示 3 个初始职业（野蛮人/法师/死灵法师）
#   - 显示各职业的属性预览和描述
#   - 选择后初始化 GameManager 并开始游戏
#   - 仅在首次游戏（无存档）时显示
# ============================================================
# 依赖：
#   - GameManager: 初始化角色数据
#   - CharacterPresets: 职业预设数据
#   - EventBus: 游戏开始事件
# ============================================================
extends Control

# ============================================================
# 状态
# ============================================================
var selected_class: String = "barbarian"  # 默认选中野蛮人
var class_buttons: Dictionary = {}        # class_id → Button

# ============================================================
# 初始化
# ============================================================
func _ready() -> void:
    # 全屏暗色背景
    var bg := ColorRect.new()
    bg.color = Color("#0a0806")  # 几乎全黑的暗色背景
    bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(bg)

    # 主容器（居中垂直排列）
    var main := VBoxContainer.new()
    main.name = "MainLayout"
    main.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
    main.offset_left = -300
    main.offset_right = 300
    main.offset_top = -250
    main.offset_bottom = 250
    main.alignment = BoxContainer.ALIGNMENT_CENTER
    main.add_theme_constant_override("separation", 16)
    add_child(main)

    # --- 标题 ---
    var title := Label.new()
    title.text = "暗黑破坏神 — 挂机刷宝"
    title.add_theme_font_size_override("font_size", 28)
    title.add_theme_color_override("font_color", Color("#c8a860"))
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    main.add_child(title)

    var subtitle := Label.new()
    subtitle.text = "选择一个英雄职业开始冒险"
    subtitle.add_theme_font_size_override("font_size", 16)
    subtitle.add_theme_color_override("font_color", Color("#8b7355"))
    subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    main.add_child(subtitle)

    # --- 职业选择卡片 ---
    var cards := HBoxContainer.new()
    cards.name = "ClassCards"
    cards.alignment = BoxContainer.ALIGNMENT_CENTER
    cards.add_theme_constant_override("separation", 16)
    main.add_child(cards)

    var classes := CharacterPresets.get_all_classes()
    for char_data in classes:
        var card := _build_class_card(char_data)
        cards.add_child(card)

    # --- 确认按钮 ---
    var start_btn := Button.new()
    start_btn.text = "⚔ 进入游戏"
    start_btn.add_theme_font_size_override("font_size", 20)
    start_btn.add_theme_color_override("font_color", Color("#ffd700"))
    start_btn.add_theme_color_override("font_hover_color", Color.WHITE)
    start_btn.custom_minimum_size = Vector2(200, 48)
    start_btn.pressed.connect(_on_start_pressed)
    main.add_child(start_btn)

    # --- 提示 ---
    var hint := Label.new()
    hint.text = "提示：游戏开始后可随时在战斗中切换或调整"
    hint.add_theme_font_size_override("font_size", 11)
    hint.add_theme_color_override("font_color", Color.GRAY)
    hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    main.add_child(hint)


# ============================================================
# 职业卡片构建
# ============================================================
func _build_class_card(char_data: Dictionary) -> Control:
    var class_id: String = char_data.get("class_id", "")
    var name: String = char_data.get("class_name", "")
    var desc: String = char_data.get("description", "")

    # 卡片容器
    var card := PanelContainer.new()
    card.name = "Card_" + class_id
    card.custom_minimum_size = Vector2(180, 300)
    var default_style := StyleBoxFlat.new()
    default_style.bg_color = Color("#1a1210")
    default_style.border_width_left = 2
    default_style.border_width_right = 2
    default_style.border_width_top = 2
    default_style.border_width_bottom = 2
    default_style.border_color = Color("#3a2a28")
    default_style.corner_radius_top_left = 8
    default_style.corner_radius_top_right = 8
    default_style.corner_radius_bottom_left = 8
    default_style.corner_radius_bottom_right = 8
    card.add_theme_stylebox_override("panel", default_style)

    var content := VBoxContainer.new()
    content.name = "Content"
    content.alignment = BoxContainer.ALIGNMENT_CENTER
    content.add_theme_constant_override("separation", 8)
    card.add_child(content)

    # 职业名称
    var name_label := Label.new()
    name_label.text = name
    name_label.add_theme_font_size_override("font_size", 20)
    name_label.add_theme_color_override("font_color", Color("#c8a860"))
    name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    content.add_child(name_label)

    # 职业英文名
    var eng_label := Label.new()
    eng_label.text = class_id.capitalize()
    eng_label.add_theme_font_size_override("font_size", 12)
    eng_label.add_theme_color_override("font_color", Color("#8b7355"))
    eng_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    content.add_child(eng_label)

    # 描述
    var desc_label := Label.new()
    desc_label.text = desc
    desc_label.add_theme_font_size_override("font_size", 12)
    desc_label.add_theme_color_override("font_color", Color.WHITE)
    desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    desc_label.custom_minimum_size = Vector2(160, 40)
    content.add_child(desc_label)

    # 属性预览
    var attrs := "STR: %d  DEX: %d\nVIT: %d  ENE: %d" % [
        char_data.get("base_strength", 20),
        char_data.get("base_dexterity", 20),
        char_data.get("base_vitality", 20),
        char_data.get("base_energy", 20),
    ]
    var attr_label := Label.new()
    attr_label.text = attrs
    attr_label.add_theme_font_size_override("font_size", 12)
    attr_label.add_theme_color_override("font_color", Color("#daa520"))
    attr_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    content.add_child(attr_label)

    # 选择按钮
    var select_btn := Button.new()
    select_btn.text = "选择" if selected_class != class_id else "★ 已选"
    select_btn.pressed.connect(func():
        _select_class(class_id)
    )
    content.add_child(select_btn)
    class_buttons[class_id] = select_btn

    return card


# ============================================================
# 职业选择逻辑
# ============================================================
func _select_class(class_id: String) -> void:
    selected_class = class_id
    # 更新按钮状态
    for cid in class_buttons:
        var btn: Button = class_buttons[cid]
        btn.text = "选择" if cid != class_id else "★ 已选"

func _on_start_pressed() -> void:
    # 初始化 GameManager 中的角色数据
    _apply_class_to_game_manager(selected_class)

    # 切换到主游戏场景
    # 注意：主场景文件路径为 scenes/main_game.tscn
    var main_scene_path := "res://scenes/main_game.tscn"
    if ResourceLoader.exists(main_scene_path):
        get_tree().change_scene_to_file(main_scene_path)
    else:
        # 首次运行可能还未生成 .tscn 文件 — 使用脚本直接创建
        _fallback_start_game()


func _apply_class_to_game_manager(class_id: String) -> void:
    var class_data := CharacterPresets.find_character_class(class_id)

    GameManager.character_class = class_id
    GameManager.level = 1
    GameManager.experience = 0.0
    GameManager.experience_to_next = 100.0

    # 应用职业基础属性
    GameManager.strength = class_data.get("base_strength", 20)
    GameManager.dexterity = class_data.get("base_dexterity", 20)
    GameManager.vitality = class_data.get("base_vitality", 20)
    GameManager.energy = class_data.get("base_energy", 20)
    GameManager.unspent_points = 0

    # 初始金币
    GameManager.gold = 100.0
    GameManager.souls = 0.0

    # 初始装备
    var weapon_id: String = class_data.get("starting_weapon_id", "sword")
    var armor_id: String = class_data.get("starting_armor_id", "helm")
    _give_starter_gear(weapon_id, armor_id)

    # 计算属性
    GameManager._recalculate_stats()

    print("[角色选择] 已选择职业: %s" % class_data.get("class_name", class_id))


func _give_starter_gear(weapon_id: String, armor_id: String) -> void:
    # 赠送初始武器和防具
    var weapon := EquipmentPresets.find_equipment(weapon_id)
    if not weapon.is_empty():
        GameManager.equipped_items["weapon_main"] = weapon

    var armor := EquipmentPresets.find_equipment(armor_id)
    if not armor.is_empty():
        GameManager.equipped_items[armor.get("slot", "body")] = armor


func _fallback_start_game() -> void:
    # 如果 .tscn 文件不存在，直接创建 MainGameUI 实例作为临时场景
    var root := get_tree().root
    # 清除当前场景的所有子节点
    for child in root.get_children():
        if child is Control:
            child.queue_free()

    # 创建主游戏 UI
    var main_ui: Control = load("res://scripts/ui/main_game_ui.gd").new()
    main_ui.name = "MainGameUI"
    root.add_child(main_ui)

    # 开始游戏
    GameManager.is_initialized = true
    GameManager._setup_timers()
    GameManager.current_stage = 1

    print("✓ 游戏已启动（回退模式）")
