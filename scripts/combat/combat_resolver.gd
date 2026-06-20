# CombatResolver.gd - 战斗计算
# 伤害公式、命中计算、元素伤害结算
class_name CombatResolver
extends RefCounted

# ============================================================
# 伤害计算
# ============================================================
static func calculate_player_damage() -> float:
    # 获取基础数据
    var weapon_min: float = _get_weapon_min_damage()
    var weapon_max: float = _get_weapon_max_damage()
    var str_bonus: float = GameManager.strength * _get_str_damage_per_point()
    var dex_bonus: float = GameManager.dexterity * _get_dex_damage_per_point()
    var ene_bonus: float = GameManager.energy * _get_ene_damage_per_point()

    # 基础物理伤害
    var base_min := weapon_min * (1.0 + str_bonus)
    var base_max := weapon_max * (1.0 + str_bonus)
    var base_damage := randf_range(base_min, base_max)

    # 元素伤害
    var elemental_damage := _get_total_elemental_damage()

    # 暴击判定
    var crit_chance := _get_critical_chance() + dex_bonus
    var is_crit := randf() < crit_chance
    var crit_multiplier := _get_critical_multiplier() if is_crit else 1.0

    # 攻速影响
    var attacks_per_second := _get_attacks_per_second()

    # 最终伤害
    var total_damage := (base_damage + elemental_damage) * crit_multiplier
    var dps := total_damage * attacks_per_second

    return dps

# ============================================================
# 伤害子组件
# ============================================================
static func _get_weapon_min_damage() -> float:
    var weapon := GameManager.equipped_items.get("weapon_main", {})
    if weapon.is_empty():
        return 2.0  # 空手基础伤害
    return weapon.get("base_stats", {}).get("min_damage", 2.0)

static func _get_weapon_max_damage() -> float:
    var weapon := GameManager.equipped_items.get("weapon_main", {})
    if weapon.is_empty():
        return 5.0
    return weapon.get("base_stats", {}).get("max_damage", 5.0)

static func _get_str_damage_per_point() -> float:
    return 0.01  # 每点力量 +1% 物理伤害

static func _get_dex_damage_per_point() -> float:
    return 0.005  # 每点敏捷 +0.5% 暴击几率（在 crit_chance 中使用）

static func _get_ene_damage_per_point() -> float:
    return 0.01  # 每点能量 +1% 元素伤害

static func _get_total_elemental_damage() -> float:
    var total := 0.0
    for item in GameManager.equipped_items.values():
        for affix in item.get("affixes", []):
            if affix.get("stat", "") in ["火焰伤害", "冰冷伤害", "闪电伤害", "毒素伤害"]:
                total += affix.get("value", 0.0)
    return total

static func _get_critical_chance() -> float:
    var base := 0.05  # 5% 基础暴击率
    for item in GameManager.equipped_items.values():
        for affix in item.get("affixes", []):
            if affix.get("stat", "") == "暴击几率":
                base += affix.get("value", 0.0) / 100.0
    return clampf(base, 0.0, 0.75)  # 上限 75%

static func _get_critical_multiplier() -> float:
    var base := 1.5  # 基础暴击倍率 150%
    for item in GameManager.equipped_items.values():
        for affix in item.get("affixes", []):
            if affix.get("stat", "") == "暴击伤害":
                base += affix.get("value", 0.0) / 100.0
    return base

static func _get_attacks_per_second() -> float:
    var base := 1.0
    for item in GameManager.equipped_items.values():
        for affix in item.get("affixes", []):
            if affix.get("stat", "") == "攻击速度":
                base += affix.get("value", 0.0) / 100.0
    return maxf(base, 0.25)  # 下限 0.25 次/秒

# ============================================================
# 敌人伤害
# ============================================================
static func calculate_enemy_damage(enemy_data: Dictionary) -> float:
    var base_damage := enemy_data.get("damage", 5.0)
    # 难度倍率
    var difficulty_multiplier := 1.0
    match GameManager.difficulty:
        "噩梦": difficulty_multiplier = 2.0
        "地狱": difficulty_multiplier = 4.0
    return base_damage * difficulty_multiplier * (0.8 + randf() * 0.4)  # 80%-120% 波动

# ============================================================
# 玩家防御
# ============================================================
static func calculate_player_defense() -> float:
    var defense := 0.0
    for item in GameManager.equipped_items.values():
        defense += item.get("base_stats", {}).get("defense", 0.0)
        for affix in item.get("affixes", []):
            if affix.get("stat", "") == "防御":
                defense += affix.get("value", 0.0)
    return defense

static func calculate_damage_reduction(defense: float) -> float:
    # 防御减伤公式（类 Diablo 2）
    return defense / (defense + 100.0)

# ============================================================
# 经验与金币计算
# ============================================================
static func calculate_experience_reward(enemy_data: Dictionary) -> float:
    var base_xp := enemy_data.get("xp_reward", 10.0)
    var difficulty_mult := 1.0
    match GameManager.difficulty:
        "噩梦": difficulty_mult = 2.5
        "地狱": difficulty_mult = 5.0
    return base_xp * difficulty_mult

static func calculate_gold_reward(enemy_data: Dictionary) -> float:
    var base_gold := enemy_data.get("gold_reward", 5.0)
    var gold_find := _get_total_gold_find()
    return base_gold * (1.0 + gold_find / 100.0)

static func _get_total_gold_find() -> float:
    var gf := 0.0
    for item in GameManager.equipped_items.values():
        for affix in item.get("affixes", []):
            if affix.get("stat", "") == "金币获取":
                gf += affix.get("value", 0.0)
    return gf
