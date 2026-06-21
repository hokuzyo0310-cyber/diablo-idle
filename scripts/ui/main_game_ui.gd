# ============================================================
# MainGameUI.gd - 主游戏界面控制器
# 负责构建和管理所有游戏内 UI 元素：
#   HUD（血球/蓝球/资源）、战斗区域、阶段进度条、底部导航栏
# ============================================================
# 依赖关系：
#   - EventBus: 所有 UI 更新通过信号驱动
#   - GameManager: 读取游戏状态数据
#   - MathHelper: 大数字格式化
#   - StringHelper: 文本颜色/格式化
# ============================================================
extends Control

# ============================================================
# UI 节点引用（均在 _ready 中动态创建）
# ============================================================
# -- 顶部 HUD --
var health_orb: ColorRect          # 血球（暗黑风格圆形生命显示）
var mana_orb: ColorRect            # 蓝球（暗黑风格圆形法力显示）
var health_label: Label             # 生命值文字 "123/456"
var mana_label: Label               # 法力值文字 "50/100"
var gold_label: Label               # 金币显示
var souls_label: Label              # 灵魂货币显示
var level_label: Label              # 角色等级显示

# -- 战斗区域 --
var monster_name_label: Label       # 当前怪物名称
var monster_hp_bar: ProgressBar     # 怪物血条
var monster_texture: TextureRect    # 怪物贴图占位
var damage_label: Label             # 伤害数字飘字
var combat_log_label: Label         # 战斗日志（最近事件）

# -- 阶段进度 --
var stage_progress_bar: ProgressBar # 阶段进度条
var stage_name_label: Label         # 当前阶段名称
var stage_enemy_label: Label        # "3/5" 敌人进度

# -- 底部导航栏 --
var nav_bar: HBoxContainer          # 导航按钮容器
var btn_combat: Button              # [挂机] 标签
var btn_inventory: Button           # [背包] 标签
var btn_character: Button           # [角色] 标签
var btn_skills: Button              # [技能] 标签
var btn_map: Button                 # [地图] 标签
var btn_prestige: Button            # [转生] 标签
var btn_settings: Button            # [设置] 标签

# -- 子面板 --
var inventory_panel: Control        # 背包面板（引用 scripts/ui/inventory_panel.gd）
var stats_panel: Control            # 角色属性面板（引用 scripts/ui/stats_panel.gd）
var current_open_panel: Control     # 当前打开的子面板

# ============================================================
# 样式常量 — 暗黑破坏神风格配色方案
# ============================================================
# 背景色板：深棕到炭黑渐变 (#1a1210 → #2d2120)
const COLOR_BG_DARK := Color("#1a1210")       # 最深背景
const COLOR_BG_MID := Color("#2d2120")        # 中深背景
const COLOR_BG_LIGHT := Color("#3a2a28")      # 较浅背景（面板底色）

# UI 镶边：暗石板纹理 + 金色/铜色镶边
const COLOR_GOLD := Color("#c8a860")           # 金色镶边/文字
const COLOR_COPPER := Color("#8b7355")         # 铜色二级文字
const COLOR_PANEL_BG := Color("#1a1210cc")     # 半透明面板背景

# 各稀有度对应颜色
const RARITY_COLORS := {
    "普通": Color.WHITE,
    "魔法": Color("#4169e1"),
    "稀有": Color("#ffd700"),
    "史诗": Color("#daa520"),
    "传奇": Color("#ff8c00"),
    "远古": Color("#ff4444"),
}

# 导航按钮尺寸
const NAV_BTN_WIDTH := 80
const NAV_BTN_HEIGHT := 36

# ============================================================
# 初始化 — 构建整个 UI
# ============================================================
func _ready() -> void:
    # 设置根节点 Control 为全屏（自适应布局）
    # anchor: 四边全展 → 填满整个窗口
    anchor_left = 0.0
    anchor_top = 0.0
    anchor_right = 1.0
    anchor_bottom = 1.0
    offset_left = 0
    offset_top = 0
    offset_right = 0
    offset_bottom = 0

    # 分三部分构建界面：
    #   1. 顶部 HUD — 血球/蓝球/资源显示
    #   2. 中央战斗区 — 怪物显示、伤害数字、日志
    #   3. 底部导航 — 进度条 + 标签按钮
    _build_hud()
    _build_battle_area()
    _build_navigation()

    # 连接 EventBus 信号 → UI 更新回调
    _connect_signals()

    # 初始化 UI 状态（从 GameManager 读取当前值）
    _refresh_all_displays()

    print("✓ 主游戏界面构建完成")


# ============================================================
# 1. 顶部 HUD 构建 — 血球/蓝球 + 资源显示
# ============================================================
func _build_hud() -> void:
    # HUD 容器：水平排列，贴顶
    var hud := HBoxContainer.new()
    hud.name = "HUD"
    hud.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
    # 调整顶部间距，避免过于贴边
    hud.offset_top = 4
    hud.offset_left = 8
    hud.offset_right = -8
    hud.offset_bottom = 84
    hud.add_theme_constant_override("separation", 12)
    add_child(hud)

    # --- 左侧：等级 + 头像占位 ---
    var left_group := VBoxContainer.new()
    left_group.name = "LeftGroup"
    left_group.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
    hud.add_child(left_group)

    level_label = Label.new()
    level_label.name = "LevelLabel"
    level_label.add_theme_font_size_override("font_size", 14)
    level_label.add_theme_color_override("font_color", COLOR_GOLD)
    level_label.text = "Lv.1"
    left_group.add_child(level_label)

    # 头像占位（后续替换为 sprite）
    var portrait := ColorRect.new()
    portrait.name = "Portrait"
    portrait.color = COLOR_BG_LIGHT
    portrait.custom_minimum_size = Vector2(48, 48)
    portrait.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
    left_group.add_child(portrait)

    # --- 生命球（暗黑风格血球） ---
    var health_group := VBoxContainer.new()
    health_group.name = "HealthGroup"
    health_group.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
    hud.add_child(health_group)

    health_label = Label.new()
    health_label.name = "HealthLabel"
    health_label.add_theme_font_size_override("font_size", 13)
    health_label.add_theme_color_override("font_color", Color.RED)
    health_label.text = "100/100"
    health_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    health_group.add_child(health_label)

    health_orb = ColorRect.new()
    health_orb.name = "HealthOrb"
    health_orb.color = Color.RED
    health_orb.custom_minimum_size = Vector2(64, 36)
    health_orb.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
    # 使用圆角矩形近似血球（后续替换为真正的球形贴图）
    health_group.add_child(health_orb)

    # --- 法力球（暗黑风格蓝球） ---
    var mana_group := VBoxContainer.new()
    mana_group.name = "ManaGroup"
    mana_group.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
    hud.add_child(mana_group)

    mana_label = Label.new()
    mana_label.name = "ManaLabel"
    mana_label.add_theme_font_size_override("font_size", 13)
    mana_label.add_theme_color_override("font_color", Color.BLUE)
    mana_label.text = "50/50"
    mana_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    mana_group.add_child(mana_label)

    mana_orb = ColorRect.new()
    mana_orb.name = "ManaOrb"
    mana_orb.color = Color.BLUE
    mana_orb.custom_minimum_size = Vector2(64, 36)
    mana_orb.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
    mana_group.add_child(mana_orb)

    # --- 弹性空间 — 将右侧资源推到右边 ---
    var spacer := Control.new()
    spacer.name = "HUDSpacer"
    spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    hud.add_child(spacer)

    # --- 右侧：金钱 / 灵魂 / 血石 ---
    var resource_group := VBoxContainer.new()
    resource_group.name = "ResourceGroup"
    resource_group.size_flags_horizontal = Control.SIZE_SHRINK_END
    resource_group.alignment = BoxContainer.ALIGNMENT_END
    hud.add_child(resource_group)

    gold_label = _make_resource_label("💰 金币: 0")
    resource_group.add_child(gold_label)

    souls_label = _make_resource_label("💀 灵魂: 0")
    resource_group.add_child(souls_label)

    # 血石标签（暂不显示，预留）
    # var blood_label = _make_resource_label("🩸 血石: 0")
    # resource_group.add_child(blood_label)


# ============================================================
# 2. 中央战斗区域 — 怪物显示 + 伤害飘字 + 战斗日志
# ============================================================
func _build_battle_area() -> void:
    # 战斗区容器：居中，占据大部分空间
    var battle := VBoxContainer.new()
    battle.name = "BattleArea"
    battle.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
    battle.offset_top = 88
    battle.offset_left = 40
    battle.offset_right = -40
    battle.offset_bottom = -140
    battle.alignment = BoxContainer.ALIGNMENT_CENTER
    add_child(battle)

    # 怪物名称
    monster_name_label = Label.new()
    monster_name_label.name = "MonsterName"
    monster_name_label.add_theme_font_size_override("font_size", 22)
    monster_name_label.add_theme_color_override("font_color", COLOR_GOLD)
    monster_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    monster_name_label.text = "等待战斗..."
    battle.add_child(monster_name_label)

    # 怪物血条
    monster_hp_bar = ProgressBar.new()
    monster_hp_bar.name = "MonsterHPBar"
    monster_hp_bar.custom_minimum_size = Vector2(300, 18)
    monster_hp_bar.max_value = 100
    monster_hp_bar.value = 100
    monster_hp_bar.show_percentage = false
    # 血条样式：深红背景 + 亮红填充
    monster_hp_bar.add_theme_color_override("font_color", Color.RED)
    monster_hp_bar.add_theme_stylebox_override("fill", _make_stylebox(Color.RED))
    monster_hp_bar.add_theme_stylebox_override("background", _make_stylebox(Color("#4a1010")))
    battle.add_child(monster_hp_bar)

    # 间距
    var gap1 := Control.new()
    gap1.custom_minimum_size = Vector2(0, 16)
    battle.add_child(gap1)

    # 怪物贴图占位（后续替换为 AnimatedSprite2D）
    monster_texture = TextureRect.new()
    monster_texture.name = "MonsterTexture"
    monster_texture.custom_minimum_size = Vector2(128, 128)
    monster_texture.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
    # 用纯色占位，后续替换为怪物精灵
    var placeholder := ColorRect.new()
    placeholder.name = "MonsterPlaceholder"
    placeholder.color = Color.DIM_GRAY
    placeholder.custom_minimum_size = Vector2(128, 128)
    placeholder.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
    battle.add_child(placeholder)

    var gap2 := Control.new()
    gap2.custom_minimum_size = Vector2(0, 12)
    battle.add_child(gap2)

    # 伤害数字飘字（临时显示最近一次伤害）
    damage_label = Label.new()
    damage_label.name = "DamageLabel"
    damage_label.add_theme_font_size_override("font_size", 18)
    damage_label.add_theme_color_override("font_color", Color.YELLOW)
    damage_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    damage_label.text = ""
    battle.add_child(damage_label)

    # 战斗日志（最后几行事件）
    combat_log_label = Label.new()
    combat_log_label.name = "CombatLog"
    combat_log_label.add_theme_font_size_override("font_size", 12)
    combat_log_label.add_theme_color_override("font_color", COLOR_COPPER)
    combat_log_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    combat_log_label.text = ""
    battle.add_child(combat_log_label)


# ============================================================
# 3. 底部导航区域 — 阶段进度条 + 标签切换按钮
# ============================================================
func _build_navigation() -> void:
    # 底部容器：垂直排列（进度在上，导航在下）
    var bottom := VBoxContainer.new()
    bottom.name = "BottomArea"
    bottom.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
    bottom.offset_top = -120   # 从底部向上 120px
    bottom.offset_left = 8
    bottom.offset_right = -8
    bottom.offset_bottom = -4
    bottom.alignment = BoxContainer.ALIGNMENT_CENTER
    add_child(bottom)

    # --- 阶段进度条行 ---
    var stage_row := HBoxContainer.new()
    stage_row.name = "StageRow"
    stage_row.alignment = BoxContainer.ALIGNMENT_CENTER
    bottom.add_child(stage_row)

    stage_name_label = Label.new()
    stage_name_label.name = "StageName"
    stage_name_label.add_theme_font_size_override("font_size", 14)
    stage_name_label.add_theme_color_override("font_color", COLOR_GOLD)
    stage_name_label.text = "阶段 1"
    stage_row.add_child(stage_name_label)

    stage_progress_bar = ProgressBar.new()
    stage_progress_bar.name = "StageProgress"
    stage_progress_bar.custom_minimum_size = Vector2(300, 14)
    stage_progress_bar.max_value = 5   # 默认 5 只敌人
    stage_progress_bar.value = 0
    stage_progress_bar.show_percentage = false
    stage_progress_bar.add_theme_stylebox_override("fill", _make_stylebox(COLOR_GOLD))
    stage_progress_bar.add_theme_stylebox_override("background", _make_stylebox(Color("#3a2a28")))
    stage_row.add_child(stage_progress_bar)

    stage_enemy_label = Label.new()
    stage_enemy_label.name = "EnemyCount"
    stage_enemy_label.add_theme_font_size_override("font_size", 13)
    stage_enemy_label.add_theme_color_override("font_color", COLOR_COPPER)
    stage_enemy_label.text = "0/5"
    stage_row.add_child(stage_enemy_label)

    # --- 底部导航按钮栏 ---
    nav_bar = HBoxContainer.new()
    nav_bar.name = "NavBar"
    nav_bar.alignment = BoxContainer.ALIGNMENT_CENTER
    nav_bar.add_theme_constant_override("separation", 4)
    bottom.add_child(nav_bar)

    # 定义导航按钮：名称 → 回调方法
    var nav_buttons := {
        "⚔ 挂机":  "_on_combat_tab",
        "🎒 背包":  "_on_inventory_tab",
        "👤 角色":  "_on_character_tab",
        "✨ 技能":  "_on_skills_tab",
        "🗺 地图":  "_on_map_tab",
        "💫 转生":  "_on_prestige_tab",
        "⚙ 设置":  "_on_settings_tab",
    }

    for btn_text in nav_buttons:
        var btn := Button.new()
        btn.text = btn_text
        btn.custom_minimum_size = Vector2(NAV_BTN_WIDTH, NAV_BTN_HEIGHT)
        btn.add_theme_font_size_override("font_size", 12)
        # 暗黑风格按钮配色
        btn.add_theme_color_override("font_color", COLOR_COPPER)
        btn.add_theme_color_override("font_hover_color", COLOR_GOLD)
        btn.add_theme_stylebox_override("normal", _make_stylebox(COLOR_BG_MID))
        btn.add_theme_stylebox_override("hover", _make_stylebox(COLOR_BG_LIGHT))
        btn.add_theme_stylebox_override("pressed", _make_stylebox(COLOR_BG_DARK))
        # 连接信号
        btn.pressed.connect(Callable(self, nav_buttons[btn_text]))
        nav_bar.add_child(btn)


# ============================================================
# 信号连接 — 将 EventBus 事件绑定到 UI 更新回调
# ============================================================
func _connect_signals() -> void:
    # 资源变化
    EventBus.gold_changed.connect(_on_gold_changed)
    EventBus.souls_changed.connect(_on_souls_changed)

    # 战斗事件
    EventBus.damage_dealt_to_enemy.connect(_on_damage_dealt)
    EventBus.enemy_damaged_player.connect(_on_player_damaged)
    EventBus.enemy_killed.connect(_on_enemy_killed)
    EventBus.boss_spawned.connect(_on_boss_spawn)
    EventBus.boss_killed.connect(_on_boss_killed)
    EventBus.stage_cleared.connect(_on_stage_cleared)
    EventBus.stage_advanced.connect(_on_stage_advanced)

    # 玩家状态
    EventBus.health_changed.connect(_on_health_changed)
    EventBus.level_up.connect(_on_level_up)
    EventBus.player_died.connect(_on_player_died)
    EventBus.player_revived.connect(_on_player_revived)

    # 掉落
    EventBus.item_dropped.connect(_on_item_dropped)

    # 存档
    EventBus.game_saved.connect(_on_game_saved)
    EventBus.game_loaded.connect(_on_game_loaded)


# ============================================================
# UI 刷新 — 将 GameManager 数据同步到 UI 元素
# ============================================================
func _refresh_all_displays() -> void:
    _update_health_display()
    _update_mana_display()
    _update_resource_display()
    _update_level_display()
    _update_stage_display()
    _update_monster_display()


# ============================================================
# 顶部 HUD 更新回调
# ============================================================
func _update_health_display() -> void:
    var cur := GameManager.current_health
    var max_hp := GameManager.max_health
    health_label.text = "%.0f/%.0f" % [cur, max_hp]

    # 血球填充比例（ColorRect 宽度缩放模拟血量百分比）
    var ratio := clampf(cur / max_hp if max_hp > 0 else 0.0, 0.0, 1.0)
    health_orb.custom_minimum_size.x = 64.0 * ratio
    # 血量低于 25% 时闪烁警告（改变颜色深度）
    health_orb.color = Color.RED if ratio > 0.25 else Color.DARK_RED

func _update_mana_display() -> void:
    var cur := GameManager.current_mana
    var max_mp := GameManager.max_mana
    mana_label.text = "%.0f/%.0f" % [cur, max_mp]
    var ratio := clampf(cur / max_mp if max_mp > 0 else 0.0, 0.0, 1.0)
    mana_orb.custom_minimum_size.x = 64.0 * ratio

func _update_resource_display() -> void:
    gold_label.text = "💰 %s" % MathHelper.format_number(GameManager.gold)
    souls_label.text = "💀 %s" % MathHelper.format_number(GameManager.souls)

func _update_level_display() -> void:
    level_label.text = "Lv.%d" % GameManager.level

func _update_stage_display() -> void:
    stage_name_label.text = "阶段 %d" % GameManager.current_stage
    # 更新阶段进度条
    var total_enemies := GameManager.enemies_in_stage.size()
    if total_enemies > 0:
        stage_progress_bar.max_value = total_enemies
        stage_progress_bar.value = GameManager.enemy_index
        stage_enemy_label.text = "%d/%d" % [GameManager.enemy_index, total_enemies]

func _update_monster_display() -> void:
    if GameManager.current_enemy_data.is_empty():
        monster_name_label.text = "没有敌人"
        monster_hp_bar.value = 0
        return

    var enemy := GameManager.current_enemy_data
    monster_name_label.text = enemy.get("display_name", "未知敌人")

    var cur := enemy.get("current_health", 0.0)
    var max_hp := enemy.get("max_health", 100.0)
    monster_hp_bar.max_value = max_hp
    monster_hp_bar.value = cur

    # Boss 名称用红色高亮
    if enemy.get("is_boss", false):
        monster_name_label.add_theme_color_override("font_color", Color.RED)
    else:
        monster_name_label.add_theme_color_override("font_color", COLOR_GOLD)


# ============================================================
# EventBus 回调 — 实时响应用户事件
# ============================================================

# --- 资源变化 ---
func _on_gold_changed(amount: float, _total: float) -> void:
    _update_resource_display()

func _on_souls_changed(_amount: float, _total: float) -> void:
    _update_resource_display()

# --- 战斗伤害 ---
func _on_damage_dealt(amount: float, enemy_name: String) -> void:
    # 飘字显示伤害数值
    damage_label.text = MathHelper.format_number(amount)
    # 2 秒后自动淡出（简化实现：直接清空）
    _fade_damage_label()

    # 更新怪物血条
    _update_monster_display()

    # 战斗日志
    combat_log_label.text = "你对 %s 造成 %s 点伤害" % [enemy_name, MathHelper.format_number(amount)]

func _on_player_damaged(amount: float) -> void:
    _update_health_display()
    combat_log_label.text = "受到 %.0f 点伤害" % amount

# 伤害数字淡出协程
func _fade_damage_label() -> void:
    # 简化版：使用 Timer 延迟清空
    var timer := get_tree().create_timer(1.5)
    timer.timeout.connect(func():
        if is_instance_valid(damage_label):
            damage_label.text = ""
    )

# --- 击杀事件 ---
func _on_enemy_killed(enemy_name: String, _stage: int) -> void:
    combat_log_label.text = "✝ %s 被击杀了！" % enemy_name
    _update_stage_display()
    _update_resource_display()

func _on_boss_spawn(boss_name: String) -> void:
    combat_log_label.text = "⚠ Boss 出现: %s！" % boss_name
    _update_monster_display()

func _on_boss_killed(boss_name: String, _stage: int) -> void:
    combat_log_label.text = "🏆 Boss %s 被击败！" % boss_name

# --- 阶段推进 ---
func _on_stage_cleared(stage_num: int) -> void:
    combat_log_label.text = "阶段 %d 通关！" % stage_num

func _on_stage_advanced(new_stage: int, _stage_name: String) -> void:
    _update_stage_display()
    _update_monster_display()

# --- 玩家状态 ---
func _on_health_changed(_cur: float, _max_hp: float) -> void:
    _update_health_display()

func _on_level_up(new_level: int) -> void:
    _update_level_display()
    combat_log_label.text = "🎉 升级！当前等级: %d" % new_level

func _on_player_died() -> void:
    combat_log_label.text = "☠ 你死了！等待复活..."

func _on_player_revived() -> void:
    _update_health_display()
    combat_log_label.text = "复活了！继续战斗"

# --- 掉落 ---
func _on_item_dropped(item_data: Dictionary) -> void:
    var name := item_data.get("display_name", item_data.get("base_name", "物品"))
    var rarity := item_data.get("rarity", "普通")
    combat_log_label.text = "获得物品: %s [%s]" % [name, rarity]

# --- 存档 ---
func _on_game_saved() -> void:
    combat_log_label.text = "💾 游戏已自动保存"

func _on_game_loaded() -> void:
    _refresh_all_displays()
    combat_log_label.text = "📂 存档已加载"


# ============================================================
# 导航按钮回调 — 打开/切换子面板
# ============================================================
func _on_combat_tab() -> void:
    _close_current_panel()
    combat_log_label.text = "回到挂机界面"

func _on_inventory_tab() -> void:
    _toggle_panel("inventory")

func _on_character_tab() -> void:
    _toggle_panel("stats")

func _on_skills_tab() -> void:
    combat_log_label.text = "技能面板 — 尚未实现"

func _on_map_tab() -> void:
    combat_log_label.text = "地图面板 — 尚未实现"

func _on_prestige_tab() -> void:
    combat_log_label.text = "转生面板 — 尚未实现"

func _on_settings_tab() -> void:
    combat_log_label.text = "设置面板 — 尚未实现"


# ============================================================
# 子面板管理
# ============================================================
func _toggle_panel(panel_name: String) -> void:
    if current_open_panel and is_instance_valid(current_open_panel):
        current_open_panel.queue_free()
        current_open_panel = null

    match panel_name:
        "inventory":
            inventory_panel = _create_inventory_panel()
            current_open_panel = inventory_panel
        "stats":
            stats_panel = _create_stats_panel()
            current_open_panel = stats_panel
        _:
            return

    if current_open_panel:
        # 面板覆盖在战斗区域上方
        current_open_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
        current_open_panel.offset_top = 88
        current_open_panel.offset_left = 20
        current_open_panel.offset_right = -20
        current_open_panel.offset_bottom = -108
        add_child(current_open_panel)
        combat_log_label.text = "%s 面板已打开" % panel_name

func _close_current_panel() -> void:
    if current_open_panel and is_instance_valid(current_open_panel):
        current_open_panel.queue_free()
        current_open_panel = null

# 背包面板工厂 — 委托给 InventoryPanel 脚本
func _create_inventory_panel() -> Control:
    var panel := load("res://scripts/ui/inventory_panel.gd").new()
    return panel

# 属性面板工厂 — 委托给 StatsPanel 脚本
func _create_stats_panel() -> Control:
    var panel := load("res://scripts/ui/stats_panel.gd").new()
    return panel


# ============================================================
# 辅助方法
# ============================================================
# 创建简单的纯色 StyleBoxFlat（用于按钮、血条等背景/填充）
func _make_stylebox(color: Color) -> StyleBoxFlat:
    var sb := StyleBoxFlat.new()
    sb.bg_color = color
    sb.corner_radius_top_left = 3
    sb.corner_radius_top_right = 3
    sb.corner_radius_bottom_left = 3
    sb.corner_radius_bottom_right = 3
    return sb

# 创建资源标签（金币/灵魂等）
func _make_resource_label(text: String) -> Label:
    var lbl := Label.new()
    lbl.text = text
    lbl.add_theme_font_size_override("font_size", 14)
    lbl.add_theme_color_override("font_color", COLOR_GOLD)
    lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    return lbl
