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
    # TODO: 战斗逻辑实现（见 combat_resolver.gd）
    pass

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
    # 基础生命 = 体力 × 4
    max_health = 40.0 + vitality * 4.0
    current_health = mini(current_health, max_health)
    # 基础法力 = 能量 × 2
    max_mana = 20.0 + energy * 2.0
    current_mana = mini(current_mana, max_mana)
    # TODO: 装备加成

# ============================================================
# DPS 计算
# ============================================================
func _update_stats() -> void:
    # TODO: 基于属性、装备、技能计算实际 DPS 和 gold_per_second
    pass

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
