# GameManager.gd - Autoload 游戏管理器
# 持有所有运行时游戏状态，通过 1Hz Timer 驱动自动战斗
extends Node

# ============================================================
# 配置常量
# ============================================================
const TICK_INTERVAL: float = 1.0
const MAX_OFFLINE_SECONDS: float = 86400.0  # 24 小时
const OFFLINE_EFFICIENCY: float = 0.5       # 离线效率 50%

# ============================================================
# 货币
# ============================================================
var gold: float = 0.0
var souls: float = 0.0
var blood_shards: float = 0.0

# ============================================================
# 角色属性
# ============================================================
var character_class: String = ""
var level: int = 1
var experience: float = 0.0
var experience_to_next: float = 100.0

var strength: int = 20
var dexterity: int = 20
var vitality: int = 20
var energy: int = 20
var unspent_points: int = 0

var max_health: float = 100.0
var current_health: float = 100.0
var max_mana: float = 50.0
var current_mana: float = 50.0

# ============================================================
# 装备
# ============================================================
var equipped_items: Dictionary = {}  # slot_name -> ItemData (Dictionary)
var inventory: Array[Dictionary] = []

# ============================================================
# 战斗状态
# ============================================================
var dps: float = 10.0
var gold_per_second: float = 1.0
var current_stage: int = 1
var current_enemy_data: Dictionary = {}
var enemies_in_stage: Array[Dictionary] = []
var enemy_index: int = 0

# ============================================================
# 进度
# ============================================================
var difficulty: String = "普通"
var prestige_count: int = 0
var total_kills: int = 0
var total_gold_earned: float = 0.0

# ============================================================
# 内部
# ============================================================
var game_tick: Timer
var autosave_timer: Timer
var is_initialized: bool = false

# ============================================================
# 初始化
# ============================================================
func _ready() -> void:
    _setup_timers()
    is_initialized = true

func _setup_timers() -> void:
    # 游戏主 Tick（1 秒间隔）
    game_tick = Timer.new()
    game_tick.name = "GameTick"
    game_tick.wait_time = TICK_INTERVAL
    game_tick.timeout.connect(_on_tick)
    add_child(game_tick)
    game_tick.start()

    # 自动存档（60 秒间隔）
    autosave_timer = Timer.new()
    autosave_timer.name = "AutosaveTimer"
    autosave_timer.wait_time = 60.0
    autosave_timer.timeout.connect(_on_autosave)
    add_child(autosave_timer)
    autosave_timer.start()

# ============================================================
# 游戏主循环
# ============================================================
func _on_tick() -> void:
    if not is_initialized:
        return

    _process_combat_tick()
    _update_stats()

func _process_combat_tick() -> void:
    if current_enemy_data.is_empty():
        _initialize_current_stage()
        if enemies_in_stage.is_empty():
            return

    # 玩家造成伤害
    if current_health <= 0:
        _handle_player_death()
        return

    var player_damage = CombatResolver.calculate_player_damage()
    if current_enemy_data.is_empty():
        _initialize_current_enemy()
        if current_enemy_data.is_empty():
            return

    current_enemy_data.current_health -= player_damage
    EventBus.damage_dealt_to_enemy.emit(player_damage, current_enemy_data.get("display_name", "敌人"))

    # 敌人反击
    if current_enemy_data.current_health > 0:
        var enemy_damage = CombatResolver.calculate_enemy_damage(current_enemy_data)
        var defense = CombatResolver.calculate_player_defense()
        var reduction = CombatResolver.calculate_damage_reduction(defense)
        var reduced_damage = enemy_damage * (1.0 - reduction)
        current_health -= reduced_damage
        EventBus.enemy_damaged_player.emit(reduced_damage)

        if current_health <= 0:
            _handle_player_death()
    else:
        _handle_enemy_defeat()

func _handle_enemy_defeat() -> void:
    # 发放奖励
    var xp = CombatResolver.calculate_experience_reward(current_enemy_data)
    var gold = CombatResolver.calculate_gold_reward(current_enemy_data)
    add_experience(xp)
    add_gold(gold)
    total_kills += 1

    # 生成掉落物
    var item = LootManager.generate_item(current_stage, 0.0)
    if not item.is_empty():
        inventory.append(item)

    EventBus.enemy_killed.emit(current_enemy_data.get("display_name", "敌人"), current_stage)

    # 推进到下一只敌人
    enemy_index += 1
    if enemy_index >= enemies_in_stage.size():
        _advance_stage()
    else:
        _initialize_current_enemy()

func _initialize_current_stage() -> void:
    var stage_data = StagePresets.find_stage(current_stage)
    if stage_data.is_empty():
        return

    enemies_in_stage.clear()
    enemy_index = 0

    # 生成普通敌人
    var enemy_count = randi_range(stage_data.enemy_count_min, stage_data.enemy_count_max)
    for i in range(enemy_count):
        var enemy_template_id = stage_data.enemy_templates[randi() % stage_data.enemy_templates.size()]
        var enemy_template = EnemyPresets.find_enemy_template(enemy_template_id)
        var enemy = _create_enemy_from_template(enemy_template, stage_data.area_level)
        enemies_in_stage.append(enemy)

    # Boss 战处理
    if stage_data.get("is_boss", false) and not stage_data.boss_template.is_empty():
        var boss_template = EnemyPresets.get_enemy_template(stage_data.boss_template)
        var boss = _create_enemy_from_template(boss_template, stage_data.area_level)
        boss.is_boss = true
        enemies_in_stage.append(boss)
        EventBus.boss_spawned.emit(boss.get("display_name", "Boss"))

    _initialize_current_enemy()

func _create_enemy_from_template(template: Dictionary, area_level: int) -> Dictionary:
    var scaling = pow(1.12, area_level - 1)
    var difficulty_mult = match(difficulty):
        "普通": 1.0
        "噩梦": 2.0
        "地狱": 4.0
        _: 1.0

    return {
        "enemy_id": template.get("enemy_id", ""),
        "display_name": template.get("display_name", "敌人"),
        "is_boss": template.get("is_boss", false),
        "max_health": template.get("base_health", 10) * scaling * difficulty_mult,
        "current_health": template.get("base_health", 10) * scaling * difficulty_mult,
        "damage": template.get("base_damage", 1) * scaling * difficulty_mult,
        "defense": template.get("base_defense", 0) * scaling,
        "xp_multiplier": template.get("xp_multiplier", 1.0),
        "gold_multiplier": template.get("gold_multiplier", 1.0),
        "area_level": area_level,
    }

func _initialize_current_enemy() -> void:
    if enemy_index < enemies_in_stage.size():
        current_enemy_data = enemies_in_stage[enemy_index]
    else:
        current_enemy_data = {}

func _advance_stage() -> void:
    EventBus.stage_cleared.emit(current_stage)

    # 检查是否是 Boss 阶段
    var stage_data = StagePresets.find_stage(current_stage)
    if stage_data.get("is_boss", false):
        var boss_template = EnemyPresets.get_enemy_template(stage_data.boss_template)
        EventBus.boss_killed.emit(boss_template.get("display_name", "Boss"), current_stage)

    # 推进到下一阶段
    current_stage += 1
    if current_stage > 10:
        current_stage = 10  # 暂时限制为第 10 阶段

    enemies_in_stage.clear()
    current_enemy_data = {}

func _handle_player_death() -> void:
    EventBus.player_died.emit()
    # 搜打撤惩罚：掉落装备和素材
    for item in inventory:
        pass  # TODO: 掉落处理
    inventory.clear()
    # 复活
    await get_tree().create_timer(2.0).timeout
    current_health = max_health
    EventBus.player_revived.emit()

# ============================================================
# 资源操作
# ============================================================
func add_gold(amount: float) -> void:
    gold += amount
    total_gold_earned += amount
    EventBus.gold_changed.emit(amount, gold)

func spend_gold(amount: float) -> bool:
    if gold >= amount:
        gold -= amount
        EventBus.gold_changed.emit(-amount, gold)
        return true
    return false

func add_souls(amount: float) -> void:
    souls += amount
    EventBus.souls_changed.emit(amount, souls)

# ============================================================
# 经验与升级
# ============================================================
func add_experience(amount: float) -> void:
    experience += amount
    EventBus.experience_gained.emit(amount, experience, experience_to_next)

    while experience >= experience_to_next:
        experience -= experience_to_next
        _level_up()

func _level_up() -> void:
    level += 1
    experience_to_next = _calculate_xp_for_level(level)
    unspent_points += 5  # 每级 5 属性点
    EventBus.level_up.emit(level)

func _calculate_xp_for_level(lvl: int) -> float:
    return 100.0 * pow(1.15, lvl - 1)

# ============================================================
# 属性分配
# ============================================================
func allocate_attribute(attr: String) -> bool:
    if unspent_points <= 0:
        return false
    match attr:
        "strength": strength += 1
        "dexterity": dexterity += 1
        "vitality": vitality += 1
        "energy": energy += 1
        _: return false
    unspent_points -= 1
    _recalculate_stats()
    return true

func _recalculate_stats() -> void:
    # 基础属性计算
    max_health = 40.0 + vitality * 4.0
    current_health = mini(current_health, max_health)
    max_mana = 20.0 + energy * 2.0
    current_mana = mini(current_mana, max_mana)

    # 装备加成
    for item in equipped_items.values():
        if item.is_empty():
            continue

        # 基础防御
        max_health += item.get("base_stats", {}).get("defense", 0) * 2

        # 词缀加成
        for affix in item.get("affixes", []):
            match affix.get("stat", ""):
                "increased_health":
                    max_health += affix.get("value", 0)
                "increased_vitality":
                    vitality += int(affix.get("value", 0))
                _:
                    pass

    current_health = mini(current_health, max_health)

# ============================================================
# DPS 计算
# ============================================================
func _update_stats() -> void:
    # 计算 DPS
    self.dps = CombatResolver.calculate_player_damage()

    # 计算金币生成速度
    var base_gps = 1.0
    var mf_bonus = 1.0
    for item in equipped_items.values():
        for affix in item.get("affixes", []):
            if "gold" in affix.get("stat", "").to_lower():
                mf_bonus += affix.get("value", 0) / 100.0

    self.gold_per_second = base_gps * mf_bonus

# ============================================================
# 离线进度
# ============================================================
func apply_offline_ticks(offline_seconds: float) -> void:
    var capped := minf(offline_seconds, MAX_OFFLINE_SECONDS)
    var effective_ticks := int(capped * OFFLINE_EFFICIENCY)
    var simulated := mini(effective_ticks, 3600)  # 最多模拟 3600 tick

    var gold_earned := 0.0
    var xp_earned := 0.0

    # 模拟前 N 个 tick
    for _i in range(simulated):
        gold_earned += gold_per_second
        xp_earned += gold_per_second * 0.5  # XP ≈ 金币 50%

    # 剩余直接批量计算
    if effective_ticks > 3600:
        var remaining := effective_ticks - 3600
        gold_earned += gold_per_second * remaining
        xp_earned += gold_per_second * 0.5 * remaining

    gold += gold_earned
    add_experience(xp_earned)

    EventBus.offline_progress_applied.emit(int(offline_seconds), gold_earned, xp_earned)

# ============================================================
# 存档回调
# ============================================================
func _on_autosave() -> void:
    SaveManager.save_game()

func _notification(what: int) -> void:
    if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_WM_GO_BACK_REQUEST:
        SaveManager.save_game()
