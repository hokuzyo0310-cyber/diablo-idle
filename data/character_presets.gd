# ============================================================
# CharacterPresets.gd — 角色职业预设数据 (静态数据类)
# ============================================================
# 职责：
#   定义 3 个初始职业的基础属性和初始装备
#   提供静态查询方法供 CharacterSelect UI 和 GameManager 使用
#
# 属性分布设计 (Diablo 2 风格, 总和均为 85 点):
#   野蛮人:  STR高(30), VIT中(25), ENE低(10)  → 近战坦克
#   法师:    ENE高(35), DEX中(25), STR低(10)  → 元素炮台
#   死灵:    平衡型, VIT中(20), ENE中(25)      → 召唤指挥官
#
# 依赖:
#   - scripts/ui/character_select.gd: 角色选择界面
#   - GameManager: 初始化角色数据
# ============================================================
extends Node

# ============================================================
# 野蛮人 — 近战坦克
# ============================================================
const BARBARIAN = {
    "class_id": "barbarian",
    "class_name": "野蛮人",
    "description": "近战坦克，高血量和物理伤害",
    "base_strength": 30,      # 力量最高 → 物理伤害优势
    "base_dexterity": 20,
    "base_vitality": 25,      # 体力较高 → 高生命值
    "base_energy": 10,        # 能量最低 → 法力有限
    "starting_weapon_id": "sword",   # 初始武器: 剑 (伤害 5-12)
    "starting_armor_id": "helm",     # 初始防具: 头盔 (防御 5)
}

# ============================================================
# 法师 — 元素炮台
# ============================================================
const SORCERESS = {
    "class_id": "sorceress",
    "class_name": "法师",
    "description": "元素炮台，低血量高魔法伤害",
    "base_strength": 10,      # 力量最低 → 物理脆弱
    "base_dexterity": 25,
    "base_vitality": 15,      # 体力较低 → 玻璃大炮
    "base_energy": 35,        # 能量最高 → 法力充沛 + 元素伤害高
    "starting_weapon_id": "dagger",  # 初始武器: 匕首 (伤害 3-8)
    "starting_armor_id": "robe",     # 初始防具: 法袍 (防御 5)
}

# ============================================================
# 死灵法师 — 召唤指挥官
# ============================================================
const NECROMANCER = {
    "class_id": "necromancer",
    "class_name": "死灵法师",
    "description": "召唤指挥官，中等血量和平衡伤害",
    "base_strength": 15,
    "base_dexterity": 25,
    "base_vitality": 20,      # 中等体力
    "base_energy": 25,        # 中等能量
    "starting_weapon_id": "staff",   # 初始武器: 法杖 (伤害 4-10)
    "starting_armor_id": "robe",     # 初始防具: 法袍
}

# ============================================================
# 静态查询方法
# ============================================================

# 获取所有职业数据
static func get_all_classes() -> Array[Dictionary]:
    return [BARBARIAN, SORCERESS, NECROMANCER]

# 根据 class_id 查找职业数据
# 找不到时默认返回野蛮人 (保底)
static func find_character_class(class_id: String) -> Dictionary:
    match class_id:
        "barbarian":
            return BARBARIAN
        "sorceress":
            return SORCERESS
        "necromancer":
            return NECROMANCER
        _:
            return BARBARIAN  # 默认: 野蛮人
