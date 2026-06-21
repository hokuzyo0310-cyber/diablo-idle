# ============================================================
# EventBus.gd — 全局事件信号总线 (Autoload 单例)
# ============================================================
# 这是整个项目的通信中枢，遵循观察者模式:
#   - 所有跨系统通信均通过此处的信号进行
#   - 发送方只负责 emit，不关心谁在监听
#   - 接收方只负责 connect，不关心谁在发送
#   - 完全解耦，任何系统可以独立替换
#
# 设计原则:
#   - EventBus 不持有任何状态，仅定义信号
#   - 信号命名清晰描述事件 (动词_名词 或 名词_动词ed)
#   - 携带必要的上下文参数，但不泄露内部实现
#
# 使用方式:
#   发送事件: EventBus.gold_changed.emit(amount, total)
#   监听事件: EventBus.gold_changed.connect(_on_gold_changed)
# ============================================================
extends Node

# ============================================================
# 资源变化信号 — 货币数量变更时发出
# ============================================================
signal gold_changed(amount: float, total: float)
# amount: 变化量 (正=获得, 负=花费)
# total:  变化后的总额

signal souls_changed(amount: float, total: float)
signal blood_shards_changed(amount: float, total: float)

# ============================================================
# 玩家状态信号 — 生命/法力/升级/复活
# ============================================================
signal health_changed(current: float, maximum: float)
# current: 当前生命值
# maximum: 最大生命值

signal mana_changed(current: float, maximum: float)

signal level_up(new_level: int)
# new_level: 升级后的等级

signal experience_gained(amount: float, current: float, needed: float)
# amount:  本次获得经验
# current: 当前总经验
# needed:  升级所需经验

signal player_died()
# 玩家死亡 — UI 应显示复活倒计时

signal player_revived()
# 玩家复活 — UI 应恢复战斗状态

# ============================================================
# 战斗事件信号 — 战斗过程中的关键事件
# ============================================================
signal damage_dealt_to_enemy(amount: float, enemy_name: String)
# amount:     本次造成的伤害值
# enemy_name: 受到伤害的敌人名称

signal enemy_damaged_player(amount: float)
# amount: 玩家受到的伤害值 (已经过减伤计算)

signal enemy_killed(enemy_name: String, stage: int)
# enemy_name: 被击杀的敌人名称
# stage:      当前阶段编号

signal boss_spawned(boss_name: String)
# boss_name: Boss 名称 — UI 应高亮提示

signal boss_killed(boss_name: String, stage: int)
# boss_name: Boss 名称
# stage:     Boss 所在阶段编号

# ============================================================
# 掉落事件信号
# ============================================================
signal item_dropped(item_data: Dictionary)
# item_data: 完整的物品数据 — UI 可显示掉落提示

signal gold_dropped(amount: float)

# ============================================================
# 阶段推进信号
# ============================================================
signal stage_advanced(new_stage: int, stage_name: String)
# new_stage:   新的阶段编号
# stage_name:  新阶段名称

signal stage_cleared(stage_num: int)
# stage_num: 刚通关的阶段编号

signal difficulty_unlocked(difficulty: String)
# difficulty: 新解锁的难度名称

# ============================================================
# 装备变更信号
# ============================================================
signal item_equipped(item_data: Dictionary, slot: String)
# item_data: 被装备的物品
# slot:      装备到的槽位

signal item_unequipped(item_data: Dictionary, slot: String)
# item_data: 被卸下的物品
# slot:      从哪个槽位卸下

signal item_sold(item_data: Dictionary, price: float)
# item_data: 被出售的物品
# price:     出售价格

signal item_compared(item_data: Dictionary, equipped: Dictionary, slot: String)
# item_data: 背包中的物品
# equipped:  当前装备的同槽位物品
# slot:      槽位名称

# ============================================================
# 存档事件信号
# ============================================================
signal game_saved()
# 游戏已保存 — UI 可显示 "💾 已保存"

signal game_loaded()
# 存档已加载 — UI 应刷新所有显示

signal offline_progress_applied(seconds: int, gold_earned: float, xp_earned: float)
# seconds:     离线秒数
# gold_earned: 离线获得的经验
# xp_earned:   离线获得的金币

# ============================================================
# 转生事件信号 (Phase 3 实现)
# ============================================================
signal prestige_available()
# 转生条件已满足 — UI 应提示玩家

signal prestige_triggered(prestige_count: int, souls_earned: float)
# prestige_count: 转生次数
# souls_earned:   本次转生获得的灵魂货币
