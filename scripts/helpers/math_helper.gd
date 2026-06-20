# MathHelper.gd - 数学工具
# 大数字格式化、指数公式、概率计算
class_name MathHelper
extends RefCounted

# ============================================================
# 大数字格式化
# ============================================================
const SUFFIXES := ["", "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc"]

static func format_number(value: float) -> String:
    """格式化大数字为缩写形式。1,234 -> "1.2K", 1,234,567 -> "1.2M" """
    if absf(value) < 1000.0:
        return str(int(value))

    var v := absf(value)
    var sign := "-" if value < 0 else ""
    var tier := 0

    while v >= 1000.0 and tier < SUFFIXES.size() - 1:
        v /= 1000.0
        tier += 1

    if v >= 100.0:
        return "%s%.0f%s" % [sign, v, SUFFIXES[tier]]
    elif v >= 10.0:
        return "%s%.1f%s" % [sign, v, SUFFIXES[tier]]
    else:
        return "%s%.2f%s" % [sign, v, SUFFIXES[tier]]

static func format_percent(value: float) -> String:
    """格式化百分比。0.15 -> "+15%" """
    var sign := "+" if value >= 0 else ""
    return "%s%.1f%%" % [sign, value * 100.0]

static func format_time_seconds(seconds: float) -> String:
    """格式化时间。3661 -> "1h 1m 1s" """
    var h := int(seconds / 3600.0)
    var m := int(fmod(seconds, 3600.0) / 60.0)
    var s := int(fmod(seconds, 60.0))

    var parts: Array[String] = []
    if h > 0: parts.append("%dh" % h)
    if m > 0: parts.append("%dm" % m)
    if s > 0 or parts.is_empty(): parts.append("%ds" % s)
    return " ".join(parts)

# ============================================================
# 指数/对数公式
# ============================================================
static func xp_for_level(level: int, base: float = 100.0, growth: float = 1.15) -> float:
    """计算升到指定等级所需总经验"""
    return base * pow(growth, level - 1)

static func enemy_hp_for_stage(stage: int, base: float = 50.0, growth: float = 1.12) -> float:
    """计算指定阶段敌人基础生命值"""
    return base * pow(growth, stage - 1)

static func gold_drop_for_stage(stage: int, base: float = 5.0, growth: float = 1.10) -> float:
    """计算指定阶段基础金币掉落"""
    return base * pow(growth, stage - 1)

static func upgrade_cost(level: int, base_cost: float = 100.0, multiplier: float = 1.25) -> float:
    """计算升级成本（铁匠、天赋等）"""
    return base_cost * pow(multiplier, level)

static func prestige_bonus(prestige_count: int, bonus_per_prestige: float = 0.25) -> float:
    """计算转生加成倍率"""
    return 1.0 + prestige_count * bonus_per_prestige

static func diminishing_return(value: float, divisor: float = 1.0) -> float:
    """递减收益公式（软上限）"""
    return value / (1.0 + divisor * value)

# ============================================================
# 概率与随机
# ============================================================
static func weighted_random(weights: Array[float]) -> int:
    """加权随机选择，返回选中索引"""
    var total := 0.0
    for w in weights:
        total += w
    var roll := randf() * total
    var cumulative := 0.0
    for i in range(weights.size()):
        cumulative += weights[i]
        if roll <= cumulative:
            return i
    return weights.size() - 1

static func roll_chance(chance: float) -> bool:
    """概率判定。chance 0.05 = 5%"""
    return randf() < chance

static func random_variance(base: float, variance: float = 0.2) -> float:
    """在 base ± variance 范围内随机"""
    return base * (1.0 - variance + randf() * variance * 2.0)

# ============================================================
# 钳制与映射
# ============================================================
static func clamp_percent(value: float, min_val: float = 0.0, max_val: float = 1.0) -> float:
    return clampf(value, min_val, max_val)

static func lerp_step(current: float, target: float, speed: float, delta: float) -> float:
    """平滑插值（用于 UI 动画）"""
    return move_toward(current, target, absf(target - current) * speed * delta)
