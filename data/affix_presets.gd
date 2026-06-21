# ============================================================
# AffixPresets.gd — 词缀与稀有度预设数据 (静态数据类)
# ============================================================
# 职责：
#   1. 定义 6 级稀有度层级（普通→远古）及其权重和属性
#   2. 定义前缀词缀池（进攻向: 伤害/攻速/暴击/吸血等）
#   3. 定义后缀词缀池（防御/属性向: 防御/生命/属性/GF/MF等）
#   4. 提供静态查询方法供 LootManager 使用
#
# 数据设计原则：
#   - 所有数据以 const Dictionary/Array 定义 → 编译时常量，零运行时开销
#   - 每个词缀包含: 名称、影响属性、数值范围、选中权重
#   - 稀有度权重决定掉落分布比例
#
# 依赖:
#   - LootManager: 使用这些数据生成物品
# ============================================================
extends Node

# ============================================================
# 稀有度层级定义 (6 级)
# ============================================================
# drop_weight: 基础掉落权重 (受区域等级和 MF 加成后为实际权重)
#   总基础权重 = 100 + 40 + 15 + 5 + 1 + 0.1 = 161.1
#   普通概率 ≈ 100/161.1 ≈ 62%
#   远古概率 ≈ 0.1/161.1 ≈ 0.06%
const RARITY_TIERS = [
    {
        "tier_id": 0,
        "name": "普通",
        "color": "#ffffff",
        "min_affixes": 0,         # 无词缀 — 白板装备
        "max_affixes": 0,
        "drop_weight": 100.0,     # 最高权重 → 最常见
        "has_unique_power": false,
    },
    {
        "tier_id": 1,
        "name": "魔法",
        "color": "#4169e1",       # 皇家蓝
        "min_affixes": 1,         # 1-2 个词缀
        "max_affixes": 2,
        "drop_weight": 40.0,
        "has_unique_power": false,
    },
    {
        "tier_id": 2,
        "name": "稀有",
        "color": "#ffd700",       # 金色
        "min_affixes": 3,         # 3-4 个词缀
        "max_affixes": 4,
        "drop_weight": 15.0,
        "has_unique_power": false,
    },
    {
        "tier_id": 3,
        "name": "史诗",
        "color": "#daa520",       # 暗金色
        "min_affixes": 5,         # 5-6 个词缀
        "max_affixes": 6,
        "drop_weight": 5.0,
        "has_unique_power": false,
    },
    {
        "tier_id": 4,
        "name": "传奇",
        "color": "#ff8c00",       # 暗橙色
        "min_affixes": 6,         # 固定 6 词缀
        "max_affixes": 6,
        "drop_weight": 1.0,       # 1% 基础概率
        "has_unique_power": true,  # 传奇物品有独有能力
    },
    {
        "tier_id": 5,
        "name": "远古",
        "color": "#ff4444",       # 红色
        "min_affixes": 6,         # 固定 6 词缀
        "max_affixes": 6,
        "drop_weight": 0.1,       # 0.1% 基础概率 — 极其稀有
        "has_unique_power": true,  # 远古也有独有能力
    },
]

# ============================================================
# 前缀词缀池 — 进攻向 (8 个词缀)
# ============================================================
# stat: 影响的属性标识 (在 GameManager._recalculate_stats 和 CombatResolver 中匹配)
# min_value / max_value: 基础数值范围 (受 area_level 缩放)
# weight: 选中权重 (权重越高越常见)
const PREFIX_AFFIXES = [
    # --- 伤害类 ---
    {"name": "锋利的",   "stat": "increased_physical_damage",  "min_value": 5,  "max_value": 15,  "weight": 100.0},
    {"name": "炎热的",   "stat": "fire_damage",                "min_value": 3,  "max_value": 10,  "weight": 80.0},
    {"name": "冰冷的",   "stat": "cold_damage",                "min_value": 3,  "max_value": 10,  "weight": 80.0},
    {"name": "闪电的",   "stat": "lightning_damage",           "min_value": 3,  "max_value": 10,  "weight": 80.0},
    {"name": "剧毒的",   "stat": "poison_damage",              "min_value": 3,  "max_value": 10,  "weight": 60.0},

    # --- 战斗属性类 ---
    {"name": "吸血的",   "stat": "life_steal",                 "min_value": 2,  "max_value": 8,   "weight": 40.0},
    {"name": "致命的",   "stat": "critical_chance",            "min_value": 2,  "max_value": 8,   "weight": 50.0},
    {"name": "快速的",   "stat": "attack_speed",               "min_value": 5,  "max_value": 15,  "weight": 60.0},
]

# ============================================================
# 后缀词缀池 — 防御/属性向 (8 个词缀)
# ============================================================
const SUFFIX_AFFIXES = [
    # --- 防御类 ---
    {"name": "防御的",   "stat": "increased_defense",          "min_value": 5,  "max_value": 15,  "weight": 100.0},
    {"name": "生命的",   "stat": "increased_health",           "min_value": 10, "max_value": 40,  "weight": 90.0},

    # --- 属性加成类 — 每 2-8 点直接加到角色属性 ---
    {"name": "坚韧的",   "stat": "increased_vitality",         "min_value": 2,  "max_value": 8,   "weight": 70.0},
    {"name": "力量的",   "stat": "increased_strength",         "min_value": 2,  "max_value": 8,   "weight": 70.0},
    {"name": "敏捷的",   "stat": "increased_dexterity",        "min_value": 2,  "max_value": 8,   "weight": 70.0},
    {"name": "知识的",   "stat": "increased_energy",           "min_value": 2,  "max_value": 8,   "weight": 70.0},

    # --- 经济类 — 每 10-30% GF/MF ---
    {"name": "掘金者的", "stat": "increased_gold_find",        "min_value": 10, "max_value": 30,  "weight": 50.0},
    {"name": "幸运的",   "stat": "increased_magic_find",       "min_value": 10, "max_value": 30,  "weight": 50.0},
]

# ============================================================
# 静态查询方法
# ============================================================

# 获取指定层级的稀有度数据 (返回副本，防止外部意外修改常量)
func find_rarity_tier(tier_id: int) -> Dictionary:
    if tier_id >= 0 and tier_id < RARITY_TIERS.size():
        return RARITY_TIERS[tier_id].duplicate()
    return RARITY_TIERS[0].duplicate()  # 保底: 返回普通品质

# 获取所有稀有度层级 (返回副本)
func get_all_rarity_tiers() -> Array[Dictionary]:
    var result: Array[Dictionary] = []
    result.assign(RARITY_TIERS)
    return result

# 随机获取一个前缀词缀 (等概率)
func get_random_prefix() -> Dictionary:
    return PREFIX_AFFIXES[randi() % PREFIX_AFFIXES.size()].duplicate()

# 随机获取一个后缀词缀 (等概率)
func get_random_suffix() -> Dictionary:
    return SUFFIX_AFFIXES[randi() % SUFFIX_AFFIXES.size()].duplicate()

# 随机生成指定数量的词缀 (按稀有度限制最大数量)
# 主要用于测试或快速生成场景
func get_random_affixes(count: int, rarity: int = 1) -> Array[Dictionary]:
    var affixes: Array[Dictionary] = []
    var tier = find_rarity_tier(rarity)
    var actual_count = min(count, tier.max_affixes)

    for i in range(actual_count):
        # 随机选择前缀或后缀 (各 50% 概率)
        if randf() > 0.5:
            affixes.append(get_random_prefix())
        else:
            affixes.append(get_random_suffix())

    return affixes
