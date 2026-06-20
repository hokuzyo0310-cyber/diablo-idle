# EventBus.gd - Autoload 信号总线
# 所有跨系统通信均通过此单例的信号进行
# 不持有任何状态，仅定义信号
extends Node

# ============================================================
# 资源变化
# ============================================================
signal gold_changed(amount: float, total: float)
signal souls_changed(amount: float, total: float)
signal blood_shards_changed(amount: float, total: float)

# ============================================================
# 玩家状态
# ============================================================
signal health_changed(current: float, maximum: float)
signal mana_changed(current: float, maximum: float)
signal level_up(new_level: int)
signal experience_gained(amount: float, current: float, needed: float)
signal player_died()
signal player_revived()

# ============================================================
# 战斗事件
# ============================================================
signal damage_dealt_to_enemy(amount: float, enemy_name: String)
signal enemy_damaged_player(amount: float)
signal enemy_killed(enemy_name: String, stage: int)
signal boss_spawned(boss_name: String)
signal boss_killed(boss_name: String, stage: int)

# ============================================================
# 掉落事件
# ============================================================
signal item_dropped(item_data: Dictionary)
signal gold_dropped(amount: float)

# ============================================================
# 阶段推进
# ============================================================
signal stage_advanced(new_stage: int, stage_name: String)
signal stage_cleared(stage_num: int)
signal difficulty_unlocked(difficulty: String)

# ============================================================
# 装备变更
# ============================================================
signal item_equipped(item_data: Dictionary, slot: String)
signal item_unequipped(item_data: Dictionary, slot: String)
signal item_sold(item_data: Dictionary, price: float)
signal item_compared(item_data: Dictionary, equipped: Dictionary, slot: String)

# ============================================================
# 存档事件
# ============================================================
signal game_saved()
signal game_loaded()
signal offline_progress_applied(seconds: int, gold_earned: float, xp_earned: float)

# ============================================================
# 转生事件
# ============================================================
signal prestige_available()
signal prestige_triggered(prestige_count: int, souls_earned: float)
