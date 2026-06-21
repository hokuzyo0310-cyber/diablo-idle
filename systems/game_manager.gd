# ============================================================
# GameManager.gd — 游戏核心状态管理器 (Autoload 单例)
# ============================================================
# 这是整个游戏的中枢系统，职责包括：
#   1. 持有所有运行时游戏状态（货币、属性、装备、进度）
#   2. 通过 1Hz Timer 驱动自动战斗主循环（每 Tick = 1 秒）
#   3. 处理经验升级、属性分配、阶段推进
#   4. 离线进度计算与发放
#   5. 60秒自动存档
#
# 设计决策：
#   - 1Hz Tick: 挂机游戏不需要高频更新，1秒一次足够平滑，CPU负载极低
#   - 离线效率 50%: 在线全效率，离线半效率 → 鼓励在线但不惩罚离线
#   - 死亡惩罚: "搜打撤"模式 — 掉落该次进入关卡的装备/素材全丢，经验和金币保留
#   - 每级 5 属性点: Diablo 2 经典设定
#   - 总共 10 个阶段 (Act 1): Phase 1 MVP 范围
#
# 依赖:
#   - CombatResolver: 伤害/经验/金币计算 (scripts/combat/combat_resolver.gd)
#   - LootManager: 物品掉落生成 (systems/loot_manager.gd)
#   - EventBus: 状态变更通知 (systems/event_bus.gd)
#   - SaveManager: 存档/读档 (systems/save_manager.gd)
#   - StagePresets: 阶段数据 (data/stage_presets.gd)
#   - EnemyPresets: 敌人模板 (data/enemy_presets.gd)
# ============================================================
extends Node

# ============================================================
# 配置常量 — 修改游戏节奏从这里开始
# ============================================================
const TICK_INTERVAL: float = 1.0                # 游戏主循环间隔（秒）= 1Hz
const MAX_OFFLINE_SECONDS: float = 86400.0      # 离线收益上限 = 24 小时 = 86400 秒
const OFFLINE_EFFICIENCY: float = 0.5           # 离线效率系数 (50%) — 在线 100%

# ============================================================
# 货币系统 — 三种游戏货币
# ============================================================
# gold: 金币 — 主要用于购买基础物品、工匠升级
# souls: 灵魂货币 — 转生奖励货币，用于转生天赋树 (Phase 3 实现)
# blood_shards: 血石 — 高级货币，用于稀有锻造 (Phase 3 实现)
var gold: float = 0.0
var souls: float = 0.0
var blood_shards: float = 0.0

# ============================================================
# 角色核心属性 — Diablo 2 四属性系统
# ============================================================
# strength (STR): 每点 +1% 物理伤害
# dexterity (DEX): 每点 +0.5% 暴击几率
# vitality (VIT): 每点 +4 最大生命值
# energy (ENE):  每点 +2 最大法力值, +1% 元素伤害
var character_class: String = ""                 # 职业标识: barbarian / sorceress / necromancer
var level: int = 1                               # 角色等级 (无上限)
var experience: float = 0.0                      # 当前经验值
var experience_to_next: float = 100.0            # 升级所需经验 (随等级指数增长)

var strength: int = 20                           # 力量
var dexterity: int = 20                          # 敏捷
var vitality: int = 20                           # 体力
var energy: int = 20                             # 能量
var unspent_points: int = 0                      # 未分配属性点

# 派生属性 — 由四属性和装备计算得出
var max_health: float = 100.0                    # 最大生命值 = 40 + VIT*4 + 装备加成
var current_health: float = 100.0                # 当前生命值 (≤ max_health)
var max_mana: float = 50.0                       # 最大法力值 = 20 + ENE*2
var current_mana: float = 50.0                   # 当前法力值 (≤ max_mana)

# ============================================================
# 装备系统
# ============================================================
# equipped_items: 已装备物品字典 — slot_name(String) → item_data(Dictionary)
#   slot_name 包括: head, neck, weapon_main, body, offhand, hands, ring_1, ring_2, belt, feet
# inventory: 背包物品数组 — Array[Dictionary]
#   每个物品 Dictionary 结构由 LootManager.generate_item() 定义
var equipped_items: Dictionary = {}
var inventory: Array[Dictionary] = []

# ============================================================
# 战斗运行时状态 — 每 Tick 更新
# ============================================================
var dps: float = 10.0                            # 每秒伤害 (Damage Per Second)，每 Tick 重算
var gold_per_second: float = 1.0                 # 金币每秒产出，受装备 GF 加成影响
var current_stage: int = 1                       # 当前阶段编号 (1-10, Act 1)
var current_enemy_data: Dictionary = {}          # 当前正在战斗的敌人数据快照
var enemies_in_stage: Array[Dictionary] = []     # 本阶段剩余敌人队列
var enemy_index: int = 0                         # 当前敌人在 enemies_in_stage 中的索引

# ============================================================
# 进度追踪 — 跨存档永久记录
# ============================================================
var difficulty: String = "普通"                   # 当前难度: 普通 / 噩梦 / 地狱
var prestige_count: int = 0                      # 转生次数
var total_kills: int = 0                         # 总击杀数 (统计用)
var total_gold_earned: float = 0.0               # 累计获得金币 (统计用)

# ============================================================
# 内部定时器
# ============================================================
var game_tick: Timer                             # 主游戏循环定时器 (1Hz)
var autosave_timer: Timer                        # 自动存档定时器 (60s)
var is_initialized: bool = false                 # 初始化完成标志 → 防止未就绪时 Tick

# ============================================================
# 初始化 — Godot 节点生命周期
# ============================================================
func _ready() -> void:
    _setup_timers()
    is_initialized = true

# 创建并启动两个核心定时器
func _setup_timers() -> void:
    # --- 游戏主 Tick 定时器 (1 秒间隔) ---
    # 这是整个游戏引擎的心跳，每秒执行一次完整的战斗循环:
    #   玩家造成伤害 → 敌人反击 → 检查死亡 → 处理掉落 → 推进敌人
    game_tick = Timer.new()
    game_tick.name = "GameTick"
    game_tick.wait_time = TICK_INTERVAL
    game_tick.timeout.connect(_on_tick)
    add_child(game_tick)
    game_tick.start()

    # --- 自动存档定时器 (60 秒间隔) ---
    # 每 60 秒自动保存一次，防止意外关闭丢失进度
    # 保存到 user://save.json (由 SaveManager 管理)
    autosave_timer = Timer.new()
    autosave_timer.name = "AutosaveTimer"
    autosave_timer.wait_time = 60.0
    autosave_timer.timeout.connect(_on_autosave)
    add_child(autosave_timer)
    autosave_timer.start()

# ============================================================
# 游戏主循环 — 每秒执行一次
# ============================================================
# 这是整个自动战斗的入口点，流程如下:
#   1. _process_combat_tick() — 处理一个战斗回合
#   2. _update_stats() — 重新计算 DPS/GPS 等派生属性
func _on_tick() -> void:
    if not is_initialized:
        return

    _process_combat_tick()
    _update_stats()

# ============================================================
# 战斗 Tick 处理 — 核心战斗回合逻辑
# ============================================================
# 单次 Tick 流程 (一个完整的战斗回合):
#   1. 确保当前阶段已初始化 (有敌人队列)
#   2. 玩家对当前敌人造成伤害
#   3. 若敌人未死 → 敌人反击玩家
#   4. 若敌人死亡 → 发放经验/金币/掉落 → 推进到下一个敌人
#   5. 若玩家死亡 → 触发惩罚 → 等待复活
func _process_combat_tick() -> void:
    # 步骤 1: 如果当前没有活跃敌人，初始化当前阶段
    if current_enemy_data.is_empty():
        _initialize_current_stage()
        if enemies_in_stage.is_empty():
            return  # 阶段没有敌人配置 → 跳过

    # 如果玩家已死亡，跳过伤害计算，等待复活
    if current_health <= 0:
        _handle_player_death()
        return

    # 步骤 2: 玩家造成伤害
    # DPS 计算由 CombatResolver.calculate_player_damage() 负责
    # 公式: ((武器伤害 * (1+力量加成)) + 元素伤害) * 暴击倍率 * 攻速
    var player_damage = CombatResolver.calculate_player_damage()

    # 确保当前敌人数据有效
    if current_enemy_data.is_empty():
        _initialize_current_enemy()
        if current_enemy_data.is_empty():
            return

    # 对敌人施加伤害 (直接扣减血量)
    current_enemy_data.current_health -= player_damage
    EventBus.damage_dealt_to_enemy.emit(player_damage, current_enemy_data.get("display_name", "敌人"))

    # 步骤 3 & 4: 敌人反击 或 死亡处理
    if current_enemy_data.current_health > 0:
        # 敌人存活 → 反击玩家
        # 伤害计算: 敌人基础伤害 * 难度倍率 * 随机波动(80%~120%)
        var enemy_damage = CombatResolver.calculate_enemy_damage(current_enemy_data)
        # 玩家防御减伤 — 公式: 防御/(防御+100)
        # 例: 100防御 = 50%减伤, 300防御 = 75%减伤
        var defense = CombatResolver.calculate_player_defense()
        var reduction = CombatResolver.calculate_damage_reduction(defense)
        var reduced_damage = enemy_damage * (1.0 - reduction)
        current_health -= reduced_damage
        EventBus.enemy_damaged_player.emit(reduced_damage)

        if current_health <= 0:
            _handle_player_death()
    else:
        # 敌人死亡 → 发放奖励 + 推进
        _handle_enemy_defeat()

# ============================================================
# 敌人击杀处理 — 发放奖励、生成掉落、推进队列
# ============================================================
func _handle_enemy_defeat() -> void:
    # 1. 计算并发放经验值和金币
    #    经验公式: 10 * xp_mult * 1.05^(area_level-1) * 难度倍率
    #    金币公式: 5 * gold_mult * 1.10^(area_level-1) * (1+GF/100)
    var xp = CombatResolver.calculate_experience_reward(current_enemy_data)
    var gold = CombatResolver.calculate_gold_reward(current_enemy_data)
    add_experience(xp)
    add_gold(gold)
    total_kills += 1

    # 2. 生成掉落物品 — 每只敌人保底 1 件，额外再骰 1 件
    #    基础掉落率 100%，双倍产出但不影响高稀有度权重
    for _drop in range(2):
        var item = LootManager.generate_item(current_stage, 0.0)
        if not item.is_empty():
            inventory.append(item)

    # 3. 广播击杀事件 (UI 会监听此事件更新显示)
    EventBus.enemy_killed.emit(current_enemy_data.get("display_name", "敌人"), current_stage)

    # 4. 推进到下一个敌人或下一阶段
    enemy_index += 1
    if enemy_index >= enemies_in_stage.size():
        # 当前阶段所有敌人已清空 → 推进阶段
        _advance_stage()
    else:
        # 还有敌人 → 加载下一个
        _initialize_current_enemy()

# ============================================================
# 阶段管理 — 初始化阶段、生成敌人队列
# ============================================================
# 初始化当前阶段:
#   1. 从 StagePresets 获取阶段配置
#   2. 随机生成敌人数量 (在 enemy_count_min ~ max 之间)
#   3. 从阶段敌人池中随机选取敌人模板
#   4. 如果是 Boss 阶段，额外生成 Boss 敌人
#   5. 对所有敌人应用区域等级缩放 (每级 +12%) 和难度倍率
func _initialize_current_stage() -> void:
    var stage_data = StagePresets.find_stage(current_stage)
    if stage_data.is_empty():
        return

    enemies_in_stage.clear()
    enemy_index = 0

    # --- 生成普通敌人 ---
    var enemy_count = randi_range(stage_data.enemy_count_min, stage_data.enemy_count_max)
    for i in range(enemy_count):
        # 从阶段允许的敌人模板池中随机选择
        var enemy_template_id = stage_data.enemy_templates[randi() % stage_data.enemy_templates.size()]
        var enemy_template = EnemyPresets.find_enemy_template(enemy_template_id)
        var enemy = _create_enemy_from_template(enemy_template, stage_data.area_level)
        enemies_in_stage.append(enemy)

    # --- Boss 战处理 ---
    # 每 5 阶段一个 Boss (stage 5 = 扭曲树精, stage 10 = 扭曲树精之王)
    if stage_data.get("is_boss", false) and not stage_data.boss_template.is_empty():
        var boss_template = EnemyPresets.find_enemy_template(stage_data.boss_template)
        var boss = _create_enemy_from_template(boss_template, stage_data.area_level)
        boss.is_boss = true
        enemies_in_stage.append(boss)  # Boss 在敌人队列末尾
        EventBus.boss_spawned.emit(boss.get("display_name", "Boss"))

    # 加载第一个敌人
    _initialize_current_enemy()

# 从敌人模板创建运行时敌人数据快照
# 应用两层缩放:
#   1. 区域等级缩放: 每级 +12% (指数增长) → pow(1.12, area_level-1)
#   2. 难度倍率: 普通×1, 噩梦×2, 地狱×4
func _create_enemy_from_template(template: Dictionary, area_level: int) -> Dictionary:
    # 区域等级缩放系数 — 1 级=1.0, 5 级≈1.57, 10 级≈2.77
    var scaling = pow(1.12, area_level - 1)

    # 难度倍率 — 修改 difficulty 字符串切换难度
    var difficulty_mult: float = 1.0
    match difficulty:
        "噩梦": difficulty_mult = 2.0
        "地狱": difficulty_mult = 4.0

    # 返回运行时敌人数据快照 (Dictionary 而非 Object — 性能优先)
    return {
        "enemy_id": template.get("enemy_id", ""),
        "display_name": template.get("display_name", "敌人"),
        "is_boss": template.get("is_boss", false),
        # 生命值和伤害同时受区域等级和难度影响
        "max_health": template.get("base_health", 10) * scaling * difficulty_mult,
        "current_health": template.get("base_health", 10) * scaling * difficulty_mult,
        "damage": template.get("base_damage", 1) * scaling * difficulty_mult,
        "defense": template.get("base_defense", 0) * scaling,  # 防御只受区域等级影响
        # 奖励倍率 — 用于经验和金币计算公式
        "xp_multiplier": template.get("xp_multiplier", 1.0),
        "gold_multiplier": template.get("gold_multiplier", 1.0),
        "area_level": area_level,
    }

# 从敌人队列中加载当前索引的敌人
func _initialize_current_enemy() -> void:
    if enemy_index < enemies_in_stage.size():
        current_enemy_data = enemies_in_stage[enemy_index]
    else:
        current_enemy_data = {}

# 阶段通关 → 推进到下一阶段
func _advance_stage() -> void:
    EventBus.stage_cleared.emit(current_stage)

    # Boss 战额外广播 (Boss 死亡事件)
    var stage_data = StagePresets.find_stage(current_stage)
    if stage_data.get("is_boss", false):
        var boss_template = EnemyPresets.find_enemy_template(stage_data.boss_template)
        EventBus.boss_killed.emit(boss_template.get("display_name", "Boss"), current_stage)

    # 推进阶段 (暂时限制到 10 — Phase 1 MVP 仅包含 Act 1)
    current_stage += 1
    if current_stage > 10:
        current_stage = 10  # 固定在最终 Boss 阶段重复刷

    # 清空当前状态，下次 Tick 会重新初始化新阶段
    enemies_in_stage.clear()
    current_enemy_data = {}

# ============================================================
# 玩家死亡处理 — "搜打撤" 惩罚机制
# ============================================================
# 惩罚: 该次进入关卡获得的装备和素材全部掉落
# 保留: 经验和金币不变 (已经在 _handle_enemy_defeat 中发放)
# 复活: 等待 2 秒后自动满血复活
func _handle_player_death() -> void:
    EventBus.player_died.emit()

    # TODO: 搜打撤惩罚 — 丢弃本阶段获取的所有物品
    # 当前简化实现: 直接清空背包 (Phase 1 MVP)
    for item in inventory:
        pass
    inventory.clear()

    # 2 秒复活等待时间 (暗黑经典死亡暂停)
    await get_tree().create_timer(2.0).timeout
    current_health = max_health
    EventBus.player_revived.emit()

# ============================================================
# 资源操作 — 金币和灵魂货币
# ============================================================
# 增加金币 (同时累加 total_gold_earned 用于统计)
func add_gold(amount: float) -> void:
    gold += amount
    total_gold_earned += amount
    EventBus.gold_changed.emit(amount, gold)  # (变化量, 当前总量)

# 花费金币 — 返回 true 表示成功，false 表示余额不足
func spend_gold(amount: float) -> bool:
    if gold >= amount:
        gold -= amount
        EventBus.gold_changed.emit(-amount, gold)
        return true
    return false

# 增加灵魂货币 (转生奖励 — Phase 3 实现)
func add_souls(amount: float) -> void:
    souls += amount
    EventBus.souls_changed.emit(amount, souls)

# ============================================================
# 经验与升级系统
# ============================================================
# 增加经验 → 检查升级 → 可能连续升多级 (while 循环)
func add_experience(amount: float) -> void:
    experience += amount
    EventBus.experience_gained.emit(amount, experience, experience_to_next)

    # 可能连续升级 (一次获得大量经验时)
    while experience >= experience_to_next:
        experience -= experience_to_next
        _level_up()

# 升级处理:
#   - 等级 +1
#   - 重新计算下一级所需经验 (指数增长)
#   - 获得 5 个属性分配点
#   - 注意: 升级不会自动回满生命值 (暗黑经典设计)
func _level_up() -> void:
    level += 1
    experience_to_next = _calculate_xp_for_level(level)
    unspent_points += 5
    EventBus.level_up.emit(level)

# 经验公式 (分段):
#   前 5 级加速: 极低门槛，1-2 分钟内可快速体验升级
#   Lv5 之后: 标准指数增长 100 × 1.15^(level-1)
#   Lv1→2:   30 XP
#   Lv2→3:   60 XP
#   Lv3→4:   87 XP
#   Lv4→5:  148 XP
#   Lv5→6:  251 XP (过渡)
#   Lv6→7:  201 XP (标准公式接管)
func _calculate_xp_for_level(lvl: int) -> float:
    if lvl <= 2:
        return 30.0 * float(lvl)           # 1→30, 2→60
    elif lvl <= 5:
        return 30.0 * pow(1.7, lvl - 1)    # 3→87, 4→148, 5→251
    else:
        return 100.0 * pow(1.15, lvl - 1)  # 标准曲线 6→201, 7→231...

# ============================================================
# 属性分配系统
# ============================================================
# 分配 1 个属性点到指定属性
# 返回 true 表示分配成功
# 注意: 分配后不可撤销 (Diablo 经典规则)
func allocate_attribute(attr: String) -> bool:
    if unspent_points <= 0:
        return false
    match attr:
        "strength":
            strength += 1
        "dexterity":
            dexterity += 1
        "vitality":
            vitality += 1
        "energy":
            energy += 1
        _:
            return false  # 无效属性名
    unspent_points -= 1
    _recalculate_stats()  # 属性变化后重新计算派生属性
    return true

# 重新计算所有派生属性 (生命/法力等)
# 此方法在以下情况被调用:
#   1. 属性分配后
#   2. 装备变更后
#   3. 加载存档后
func _recalculate_stats() -> void:
    # --- 基础属性计算 ---
    # 生命公式: 40 + VIT × 4
    #   VIT=20 → 120 HP, VIT=100 → 440 HP
    max_health = 40.0 + vitality * 4.0
    current_health = min(current_health, max_health)  # 上限钳制

    # 法力公式: 20 + ENE × 2
    #   ENE=20 → 60 MP, ENE=100 → 220 MP
    max_mana = 20.0 + energy * 2.0
    current_mana = min(current_mana, max_mana)

    # --- 装备加成 ---
    for item in equipped_items.values():
        if item.is_empty():
            continue

        # 防御值换算生命: 1 防御 = 2 生命 (简化设计)
        max_health += item.get("base_stats", {}).get("defense", 0) * 2

        # 遍历装备上的所有词缀
        for affix in item.get("affixes", []):
            match affix.get("stat", ""):
                "increased_health":
                    max_health += affix.get("value", 0)
                "increased_vitality":
                    vitality += int(affix.get("value", 0))  # 词缀直接加属性点
                _:
                    pass  # 其他词缀 (增伤/攻速等) 在 CombatResolver 中计算

    # 最终钳制 — 确保当前生命不超过最大值
    current_health = min(current_health, max_health)

# ============================================================
# 派生属性更新 — 每 Tick 重算 DPS 和 GPS
# ============================================================
func _update_stats() -> void:
    # DPS = 每秒伤害 — 由 CombatResolver 根据装备和属性计算
    self.dps = CombatResolver.calculate_player_damage()

    # GPS = 每秒金币产出 — 基础 1.0 × (1 + GF加成)
    # GF (Gold Find) 来自装备上的 "金币获取" 词缀
    var base_gps = 1.0
    var gf_bonus = 1.0
    for item in equipped_items.values():
        for affix in item.get("affixes", []):
            if "gold" in affix.get("stat", "").to_lower():
                gf_bonus += affix.get("value", 0) / 100.0

    self.gold_per_second = base_gps * gf_bonus

# ============================================================
# 离线进度 — 玩家离线时模拟收益
# ============================================================
# 离线收益计算策略:
#   - 上限 24 小时 (MAX_OFFLINE_SECONDS)
#   - 效率 50% (OFFLINE_EFFICIENCY)
#   - 前 3600 tick (1小时) 逐秒模拟
#   - 超过 3600 tick 的部分直接批量计算 (性能优化)
#
# 收益类型:
#   - 金币: GPS × 有效秒数
#   - 经验: GPS × 有效秒数 × 0.5 (经验约为金币的 50%)
func apply_offline_ticks(offline_seconds: float) -> void:
    # 钳制到 24 小时上限
    var capped := minf(offline_seconds, MAX_OFFLINE_SECONDS)
    # 应用 50% 离线效率
    var effective_ticks := int(capped * OFFLINE_EFFICIENCY)
    # 最多逐秒模拟 3600 tick (≈1小时在线)
    var simulated: int = min(effective_ticks, 3600)

    var gold_earned := 0.0
    var xp_earned := 0.0

    # 逐秒模拟 (适用于短离线)
    for _i in range(simulated):
        gold_earned += gold_per_second
        xp_earned += gold_per_second * 0.5

    # 批量计算剩余时间 (适用于长离线)
    if effective_ticks > 3600:
        var remaining := effective_ticks - 3600
        gold_earned += gold_per_second * remaining
        xp_earned += gold_per_second * 0.5 * remaining

    # 应用收益
    gold += gold_earned
    add_experience(xp_earned)

    EventBus.offline_progress_applied.emit(int(offline_seconds), gold_earned, xp_earned)

# ============================================================
# 存档回调 — 自动保存 + 窗口关闭保存
# ============================================================
func _on_autosave() -> void:
    SaveManager.save_game()

# Godot 窗口关闭通知 — 在退出前自动存档
func _notification(what: int) -> void:
    if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_WM_GO_BACK_REQUEST:
        SaveManager.save_game()
