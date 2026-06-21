# ============================================================
# EnemyPresets.gd — 敌人模板预设数据 (静态数据类)
# ============================================================
# 职责：
#   定义所有敌人和 Boss 的基础模板数据
#   提供静态查询方法供 GameManager 使用
#
# 数据设计：
#   - base_health: 基础生命值 (创建时会乘以区域等级缩放+难度倍率)
#   - base_damage: 基础伤害 (同上)
#   - base_defense: 基础防御 (仅受区域等级缩放)
#   - xp_multiplier: 经验倍率 (Boss 有更高倍率)
#   - gold_multiplier: 金币倍率
#
# 扩展:
#   - 后续可添加元素抗性 (fire_resist/cold_resist/lightning_resist/poison_resist)
#   - 后续可添加怪物技能/特殊行为
#   - 后续可添加贴图路径 (sprite_path)
#
# 依赖:
#   - GameManager: 使用这些模板创建运行时敌人
# ============================================================
extends Node

# ============================================================
# 普通敌人模板 (4 种)
# ============================================================
const ENEMIES = {
    "skeleton": {
        "enemy_id": "skeleton",
        "display_name": "骷髅战士",
        "is_boss": false,
        "base_health": 15,          # 基础生命 — 最低 (适合前期小怪)
        "base_damage": 3,           # 基础伤害
        "base_defense": 1,          # 基础防御
        "xp_multiplier": 1.0,       # 标准经验
        "gold_multiplier": 1.0,     # 标准金币
    },
    "zombie": {
        "enemy_id": "zombie",
        "display_name": "腐尸",
        "is_boss": false,
        "base_health": 20,          # 中等血量，低伤害 — 肉盾型
        "base_damage": 2,
        "base_defense": 2,          # 较高防御
        "xp_multiplier": 1.1,       # 略多经验
        "gold_multiplier": 1.1,
    },
    "demon": {
        "enemy_id": "demon",
        "display_name": "恶魔",
        "is_boss": false,
        "base_health": 25,          # 高血量，高伤害 — 精英型
        "base_damage": 4,
        "base_defense": 1,
        "xp_multiplier": 1.2,
        "gold_multiplier": 1.2,
    },
    "fallen": {
        "enemy_id": "fallen",
        "display_name": "堕落者",
        "is_boss": false,
        "base_health": 18,          # 平衡型
        "base_damage": 3,
        "base_defense": 1,
        "xp_multiplier": 1.0,
        "gold_multiplier": 1.0,
    },
}

# ============================================================
# Boss 模板 (2 个 — Phase 1 MVP)
# ============================================================
const BOSSES = {
    "andariel": {
        "enemy_id": "andariel",
        "display_name": "安达瑞尔",   # 扭曲树精 (Act 1 Boss)
        "is_boss": true,             # 标记为 Boss → 名称红色高亮
        "base_health": 100,          # Boss 血量显著高于普通敌人
        "base_damage": 8,            # 高伤害
        "base_defense": 3,           # 高防御
        "xp_multiplier": 5.0,        # 5 倍经验 — Boss 是主要经验来源
        "gold_multiplier": 5.0,      # 5 倍金币
    },
    "duriel": {
        "enemy_id": "duriel",
        "display_name": "杜瑞尔",
        "is_boss": true,
        "base_health": 150,          # 更高生命 — 相当于 Act 2 Boss 强度
        "base_damage": 10,
        "base_defense": 4,
        "xp_multiplier": 6.0,
        "gold_multiplier": 6.0,
    },
}

# ============================================================
# 静态查询方法
# ============================================================

# 查找敌人模板 (返回副本)
# 会先在普通敌人中查找，再在 Boss 中查找
# 找不到则返回默认的 skeleton 模板
func find_enemy_template(enemy_id: String) -> Dictionary:
    if ENEMIES.has(enemy_id):
        return ENEMIES[enemy_id].duplicate()
    if BOSSES.has(enemy_id):
        return BOSSES[enemy_id].duplicate()
    # 保底: 返回骷髅战士模板
    return ENEMIES["skeleton"].duplicate()

# 获取所有普通敌人 ID 列表
func get_all_normal_enemies() -> Array[String]:
    var result: Array[String] = []
    result.assign(ENEMIES.keys())
    return result

# 获取所有 Boss ID 列表
func get_all_bosses() -> Array[String]:
    var result: Array[String] = []
    result.assign(BOSSES.keys())
    return result
