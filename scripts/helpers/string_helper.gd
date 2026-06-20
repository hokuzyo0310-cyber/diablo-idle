# StringHelper.gd - 字符串工具
# 物品名称生成、描述格式化、颜色标记
class_name StringHelper
extends RefCounted

# ============================================================
# 物品命名
# ============================================================
static func build_item_name(base_name: String, affixes: Array[Dictionary]) -> String:
    """组装物品显示名称: "[品质前缀] 基础名称 [of 品质后缀]" """
    var parts: Array[String] = []

    # 收集前缀（进攻向词缀）
    for a in affixes:
        if a.get("quality_name") and a.get("stat", "") in [
            "物理伤害", "火焰伤害", "冰冷伤害", "闪电伤害", "毒素伤害",
            "攻击速度", "暴击几率", "暴击伤害", "魔法发现"
        ]:
            parts.append(a.quality_name)
            break  # 只取第一个前缀名

    # 基础名称
    parts.append(base_name)

    # 收集后缀（防御/属性向词缀）
    for a in affixes:
        if a.get("quality_name") and a.get("stat", "") in [
            "防御", "力量", "敏捷", "体力", "能量",
            "生命", "法力", "金币获取"
        ]:
            parts.append("of %s" % a.quality_name)
            break  # 只取第一个后缀名

    return " ".join(parts)

# ============================================================
# 颜色标记（BBCode）
# ============================================================
static func color_text(text: String, color: Color) -> String:
    """使用 Godot BBCode 给文本着色"""
    return "[color=#%s]%s[/color]" % [color.to_html(false), text]

static func rarity_color_text(text: String, rarity_color: String) -> String:
    """用稀有度颜色着色物品名称"""
    return "[color=%s]%s[/color]" % [rarity_color, text]

static func damage_number_text(amount: float, element: String = "physical") -> String:
    """生成伤害数字的色码文本"""
    var color := "#ffffff"  # 物理 = 白
    match element:
        "fire": color = "#ff4444"
        "cold": color = "#44aaff"
        "lightning": color = "#ffff44"
        "poison": color = "#44ff44"
        "arcane": color = "#cc44ff"
        "holy": color = "#ffdd44"
        "shadow": color = "#8844ff"
    return "[center][color=%s]%s[/color][/center]" % [color, MathHelper.format_number(amount)]

# ============================================================
# 属性描述生成
# ============================================================
static func affix_description(affix: Dictionary) -> String:
    """生成单条词缀的描述文本"""
    var name := affix.get("quality_name", "")
    var stat := affix.get("stat", "")
    var value := affix.get("value", 0.0)
    var sign := "+" if value >= 0 else ""

    # 判断是百分比还是固定值
    var is_pct := stat in ["物理伤害", "火焰伤害", "冰冷伤害", "闪电伤害", "毒素伤害",
                           "攻击速度", "暴击几率", "暴击伤害", "魔法发现", "金币获取",
                           "防御"]
    if is_pct:
        return "%s %s%s%% %s" % [name, sign, str(value), stat]
    else:
        return "%s %s%s %s" % [name, sign, str(value), stat]

static func item_tooltip(item: Dictionary) -> String:
    """生成物品的完整提示框文本"""
    var lines: Array[String] = []

    # 名称（带稀有度颜色）
    var name := item.get("display_name", item.get("base_name", "未知物品"))
    var rarity_color := item.get("rarity_color", "#ffffff")
    lines.append("[center]%s[/center]" % rarity_color_text(name, rarity_color))

    # 稀有度标签
    lines.append("[center][%s]%s[/%s][/center]" % [rarity_color, item.get("rarity", ""), rarity_color])

    # 基础属性
    var base_stats: Dictionary = item.get("base_stats", {})
    if base_stats.get("min_damage", 0.0) > 0:
        lines.append("伤害: %d - %d" % [base_stats.min_damage, base_stats.max_damage])
    if base_stats.get("defense", 0.0) > 0:
        lines.append("防御: %d" % base_stats.defense)

    # 词缀
    for affix in item.get("affixes", []):
        lines.append(affix_description(affix))

    # 独特能力
    if item.get("has_unique_power", false):
        lines.append("[color=#ff8c00]独特: %s[/color]" % item.get("unique_power", "未知"))

    # 需求
    lines.append("物品等级: %d" % item.get("item_level", 1))

    return "\n".join(lines)
