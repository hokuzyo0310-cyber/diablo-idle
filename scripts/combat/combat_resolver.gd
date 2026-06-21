# ============================================================
# CombatResolver.gd — 战斗计算引擎 (纯静态工具类)
# ============================================================
# 职责：
#   1. 玩家伤害计算 (物理 + 元素 + 暴击 + 攻速)
#   2. 敌人伤害计算 (受难度倍率和随机波动影响)
#   3. 玩家防御与减伤计算 (Diablo 2 公式)
#   4. 经验与金币奖励计算
#
# 设计决策：
#   - 所有方法均为 static → 不持有状态，纯函数式计算
#   - 伤害公式接近 Diablo 2 简化版，玩家可直观理解
#   - 暴击率上限 75% (防止溢出)
#   - 攻速下限 0.25/秒 (防止负攻速)
#   - 敌人伤害有 80%-120% 随机波动 (增加战斗变化)
#   - 防御减伤公式: def/(def+100) — Diablo 2 经典公式
#
# 伤害总公式 (玩家):
#   DPS = [ (武器伤害×(1+力量%)) + 元素伤害 ] × 暴击倍率 × 攻速
#
# 依赖:
#   - GameManager: 读取属性/装备数据
# ============================================================
class_name CombatResolver
extends RefCounted

# ============================================================
# 玩家伤害主入口 — 计算每秒伤害 (DPS)
# ============================================================
# 公式分解:
#   Step 1: 基础物理伤害 = rand(武器最小, 武器最大) × (1 + 力量/100)
#   Step 2: 元素伤害 = 火焰 + 冰冷 + 闪电 + 毒素 (来自装备词缀)
#   Step 3: 暴击判定 → rand() < 暴击率 → 伤害 × 暴击倍率
#   Step 4: DPS = (物理 + 元素) × 暴击倍率 × 攻速
static func calculate_player_damage() -> float:
    # --- Step 1: 基础物理伤害 ---
    var weapon_min: float = _get_weapon_min_damage()
    var weapon_max: float = _get_weapon_max_damage()
    # 力量加成: 每点 STR = +1% 物理伤害
    var str_bonus: float = GameManager.strength * _get_str_damage_per_point()
    # 敏捷加成: 每点 DEX = +0.5% 暴击几率 (在暴击判定中使用)
    var dex_bonus: float = GameManager.dexterity * _get_dex_damage_per_point()
    # 能量加成: 每点 ENE = +1% 元素伤害
    var ene_bonus: float = GameManager.energy * _get_ene_damage_per_point()

    # 在武器伤害范围内随机取值 (每次攻击伤害有波动)
    var base_min := weapon_min * (1.0 + str_bonus)
    var base_max := weapon_max * (1.0 + str_bonus)
    var base_damage := randf_range(base_min, base_max)

    # --- Step 2: 元素伤害 (固定值，无波动) ---
    var elemental_damage := _get_total_elemental_damage()

    # --- Step 3: 暴击判定 ---
    var crit_chance := _get_critical_chance() + dex_bonus
    var is_crit := randf() < crit_chance  # 每次攻击独立判定
    var crit_multiplier := _get_critical_multiplier() if is_crit else 1.0

    # --- Step 4: 攻速影响 ---
    # 每秒攻击次数 = 基础 1.0 + 装备攻速加成
    var attacks_per_second := _get_attacks_per_second()

    # --- 最终 DPS ---
    var total_damage := (base_damage + elemental_damage) * crit_multiplier
    var dps := total_damage * attacks_per_second

    return dps

# ============================================================
# 伤害子组件 — 每个属性独立计算方法，便于单独调整
# ============================================================

# 武器最小伤害 — 空手时默认 2.0
static func _get_weapon_min_damage() -> float:
    var weapon := GameManager.equipped_items.get("weapon_main", {})
    if weapon.is_empty():
        return 2.0
    return weapon.get("base_stats", {}).get("min_damage", 2.0)

# 武器最大伤害 — 空手时默认 5.0 (波动范围 2~5)
static func _get_weapon_max_damage() -> float:
    var weapon := GameManager.equipped_items.get("weapon_main", {})
    if weapon.is_empty():
        return 5.0
    return weapon.get("base_stats", {}).get("max_damage", 5.0)

# 每点力量增加 1% 物理伤害 (0.01 = 1%)
static func _get_str_damage_per_point() -> float:
    return 0.01

# 每点敏捷增加 0.5% 暴击几率 (在 calculate_player_damage 中与基础暴击率相加)
static func _get_dex_damage_per_point() -> float:
    return 0.005

# 每点能量增加 1% 元素伤害
static func _get_ene_damage_per_point() -> float:
    return 0.01

# 汇总所有装备上的元素伤害词缀
# 元素类型: 火焰/冰冷/闪电/毒素 (对应 Diablo 2 四元素)
static func _get_total_elemental_damage() -> float:
    var total := 0.0
    for item in GameManager.equipped_items.values():
        for affix in item.get("affixes", []):
            if affix.get("stat", "") in ["火焰伤害", "冰冷伤害", "闪电伤害", "毒素伤害"]:
                total += affix.get("value", 0.0)
    return total

# 暴击率 — 基础 5% + 装备词缀
# 上限 75% (防止必暴，保持战斗变化)
static func _get_critical_chance() -> float:
    var base := 0.05
    for item in GameManager.equipped_items.values():
        for affix in item.get("affixes", []):
            if affix.get("stat", "") == "暴击几率":
                base += affix.get("value", 0.0) / 100.0  # 词缀值是百分比，除以 100
    return clampf(base, 0.0, 0.75)

# 暴击倍率 — 基础 1.5× (即暴击时伤害 ×1.5)
# 装备上的暴击伤害词缀可提升此倍率
static func _get_critical_multiplier() -> float:
    var base := 1.5
    for item in GameManager.equipped_items.values():
        for affix in item.get("affixes", []):
            if affix.get("stat", "") == "暴击伤害":
                base += affix.get("value", 0.0) / 100.0
    return base

# 攻击速度 — 基础 1.0 次/秒
# 下限 0.25 次/秒 (防止被减速到无法攻击)
static func _get_attacks_per_second() -> float:
    var base := 1.0
    for item in GameManager.equipped_items.values():
        for affix in item.get("affixes", []):
            if affix.get("stat", "") == "攻击速度":
                base += affix.get("value", 0.0) / 100.0
    return maxf(base, 0.25)

# ============================================================
# 敌人伤害计算
# ============================================================
# 基础伤害受难度倍率影响:
#   普通 ×1.0, 噩梦 ×2.0, 地狱 ×4.0
# 随机波动: 80%~120% (每次攻击伤害有变化)
static func calculate_enemy_damage(enemy_data: Dictionary) -> float:
    var base_damage := enemy_data.get("damage", 5.0)

    # 难度倍率 — 噩梦敌人伤害翻倍，地狱再翻倍
    var difficulty_multiplier := 1.0
    match GameManager.difficulty:
        "噩梦":
            difficulty_multiplier = 2.0
        "地狱":
            difficulty_multiplier = 4.0

    # 最终伤害 = 基础 × 难度 × 随机波动 (80%~120%)
    return base_damage * difficulty_multiplier * (0.8 + randf() * 0.4)

# ============================================================
# 玩家防御系统
# ============================================================
# 防御力 = 所有装备的基础防御 + 词缀防御加成
static func calculate_player_defense() -> float:
    var defense := 0.0
    for item in GameManager.equipped_items.values():
        # 装备基础防御
        defense += item.get("base_stats", {}).get("defense", 0.0)
        # 词缀防御加成
        for affix in item.get("affixes", []):
            if affix.get("stat", "") == "防御":
                defense += affix.get("value", 0.0)
    return defense

# 防御减伤公式 (Diablo 2 经典公式)
#   reduction = defense / (defense + 100)
#   例: 0 防 = 0% 减伤, 100 防 = 50% 减伤, 300 防 = 75% 减伤, 900 防 = 90% 减伤
#   这是递增递减设计 → 前期每点防御价值很高，后期收益递减
static func calculate_damage_reduction(defense: float) -> float:
    return defense / (defense + 100.0)

# ============================================================
# 经验与金币奖励计算
# ============================================================

# 经验奖励公式:
#   10 × xp_multiplier × 1.05^(area_level-1) × 难度倍率
#   举例: Lv1 骷髅战士 (xp=1.0) → 10 × 1.0 × 1.0 × 1.0 = 10 XP
#         Lv10 Boss (xp=5.0, hell) → 10 × 5.0 × 1.05^9 × 5.0 ≈ 387 XP
static func calculate_experience_reward(enemy_data: Dictionary) -> float:
    var base_xp := 10.0 * enemy_data.get("xp_multiplier", 1.0)
    var area_level := enemy_data.get("area_level", 1)
    # 区域等级经验加成 — 每级 +5%
    var level_bonus := pow(1.05, area_level - 1)
    # 难度经验倍率 — 难点 = 更多经验
    var difficulty_mult := 1.0
    match GameManager.difficulty:
        "噩梦":
            difficulty_mult = 2.5
        "地狱":
            difficulty_mult = 5.0
    return base_xp * level_bonus * difficulty_mult

# 金币奖励公式:
#   5 × gold_multiplier × 1.10^(area_level-1) × (1 + GF/100)
#   GF (Gold Find) 来自装备词缀，每 100 GF = 金币翻倍
static func calculate_gold_reward(enemy_data: Dictionary) -> float:
    var base_gold := 5.0 * enemy_data.get("gold_multiplier", 1.0)
    var area_level := enemy_data.get("area_level", 1)
    # 区域等级金币加成 — 每级 +10%
    var level_bonus := pow(1.1, area_level - 1)
    # 装备上的 GF (Gold Find) 加成
    var gold_find := _get_total_gold_find()
    return base_gold * level_bonus * (1.0 + gold_find / 100.0)

# 汇总所有装备上的 "金币获取" 词缀
static func _get_total_gold_find() -> float:
    var gf := 0.0
    for item in GameManager.equipped_items.values():
        for affix in item.get("affixes", []):
            if affix.get("stat", "") == "金币获取":
                gf += affix.get("value", 0.0)
    return gf
