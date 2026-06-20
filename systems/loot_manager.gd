# LootManager.gd - Autoload 掉落管理器
# 负责物品生成：稀有度骰子、词缀选择、数值骰子、物品命名
extends Node

# ============================================================
# 数据引用（通过 @export 或在 _ready 中加载 .tres 资源）
# ============================================================
var rarity_tiers: Array = []     # Array[RarityTier]
var base_items: Array = []       # Array[BaseItemData]
var affix_pools: Dictionary = {} # String -> AffixPool

# ============================================================
# 初始化
# ============================================================
func _ready() -> void:
    _load_data_resources()

func _load_data_resources() -> void:
    # TODO: 从 data/ 目录加载 .tres 资源文件
    # 开发初期可使用硬编码数据进行测试
    _init_placeholder_data()

func _init_placeholder_data() -> void:
    # 临时占位数据，后续替换为 .tres 文件
    pass

# ============================================================
# 物品生成主入口
# ============================================================
func generate_item(area_level: int, magic_find: float = 0.0) -> Dictionary:
    # 1. 选择基础物品类型
    var base: Dictionary = _pick_base_item(area_level)
    if base.is_empty():
        return {}

    # 2. 骰稀有度
    var rarity: Dictionary = _roll_rarity(area_level, magic_find)

    # 3. 确定词缀数量
    var num_affixes := randi_range(rarity.get("min_affixes", 0), rarity.get("max_affixes", 0))
    var num_prefixes := ceili(num_affixes / 2.0)
    var num_suffixes := num_affixes - num_prefixes

    # 4. 选择并骰词缀
    var selected_affixes: Array[Dictionary] = []
    selected_affixes.append_array(_roll_affixes("prefix", num_prefixes, area_level, rarity, base))
    selected_affixes.append_array(_roll_affixes("suffix", num_suffixes, area_level, rarity, base))

    # 5. 组装物品数据
    var item := _build_item_data(base, rarity, selected_affixes, area_level)

    # 6. 生成显示名称
    item["display_name"] = _build_display_name(base, selected_affixes)

    EventBus.item_dropped.emit(item)
    return item

# ============================================================
# 稀有度骰子
# ============================================================
func _roll_rarity(area_level: int, magic_find: float) -> Dictionary:
    # 占位稀有度表
    var tiers := [
        {"name": "普通", "color": "#ffffff", "min_affixes": 0, "max_affixes": 0, "weight": 100.0, "has_unique": false},
        {"name": "魔法", "color": "#4169e1", "min_affixes": 1, "max_affixes": 2, "weight": 40.0, "has_unique": false},
        {"name": "稀有", "color": "#ffd700", "min_affixes": 3, "max_affixes": 4, "weight": 15.0, "has_unique": false},
        {"name": "史诗", "color": "#daa520", "min_affixes": 5, "max_affixes": 6, "weight": 5.0, "has_unique": false},
        {"name": "传奇", "color": "#ff8c00", "min_affixes": 6, "max_affixes": 6, "weight": 1.0, "has_unique": true},
        {"name": "远古", "color": "#ff4444", "min_affixes": 6, "max_affixes": 6, "weight": 0.1, "has_unique": true},
    ]

    var total_weight := 0.0
    for tier in tiers:
        total_weight += tier.weight * (1.0 + area_level * 0.02) * (1.0 + magic_find / 100.0)

    var roll := randf() * total_weight
    var cumulative := 0.0
    for tier in tiers:
        cumulative += tier.weight * (1.0 + area_level * 0.02) * (1.0 + magic_find / 100.0)
        if roll <= cumulative:
            return tier

    return tiers[0]

# ============================================================
# 词缀生成
# ============================================================
func _roll_affixes(affix_type: String, count: int, area_level: int, rarity: Dictionary, base: Dictionary) -> Array[Dictionary]:
    var results: Array[Dictionary] = []
    var available := _get_available_affixes(affix_type, base)

    for _i in range(count):
        if available.is_empty():
            break

        var idx := randi() % available.size()
        var affix := available[idx]
        var rolled := _roll_single_affix(affix, area_level, rarity)
        results.append(rolled)
        available.remove_at(idx)  # 避免重复词缀

    return results

func _get_available_affixes(affix_type: String, base: Dictionary) -> Array[Dictionary]:
    # TODO: 从 AffixPool .tres 加载实际词缀
    # 占位词缀数据
    var prefix_pool := [
        {"name": "锋利", "stat": "物理伤害", "min": 5.0, "max": 20.0, "tiers": ["粗糙", "锋利", "精良", "残忍", "虐杀"]},
        {"name": "燃烧", "stat": "火焰伤害", "min": 3.0, "max": 15.0, "tiers": ["微热", "燃烧", "炽热", "烈焰", "熔火"]},
        {"name": "迅捷", "stat": "攻击速度", "min": 2.0, "max": 10.0, "tiers": ["轻快", "迅捷", "急速", "狂风", "闪电"]},
    ]
    var suffix_pool := [
        {"name": "堡垒", "stat": "防御", "min": 10.0, "max": 50.0, "tiers": ["坚固", "堡垒", "要塞", "铁壁", "不灭"]},
        {"name": "巨人", "stat": "力量", "min": 2.0, "max": 10.0, "tiers": ["强壮", "巨人", "泰坦", "擎天", "创世"]},
        {"name": "生机", "stat": "生命", "min": 10.0, "max": 40.0, "tiers": ["健康", "生机", "活力", "不朽", "永生"]},
    ]

    return prefix_pool if affix_type == "prefix" else suffix_pool

func _roll_single_affix(affix: Dictionary, area_level: int, rarity: Dictionary) -> Dictionary:
    var scaling := 1.0 + area_level * 0.1
    var min_val := affix.min * scaling
    var max_val := affix.max * scaling

    var value: float
    if rarity.get("name", "") == "远古":
        value = max_val  # 远古保证最大骰值
    else:
        value = randf_range(min_val, max_val)

    # 确定品质层级
    var pct := (value - min_val) / (max_val - min_val) * 100.0 if max_val > min_val else 100.0
    var tiers: Array = affix.get("tiers", [])
    var quality_name := ""
    if tiers.size() == 5:
        if pct >= 81: quality_name = tiers[4]
        elif pct >= 61: quality_name = tiers[3]
        elif pct >= 41: quality_name = tiers[2]
        elif pct >= 21: quality_name = tiers[1]
        else: quality_name = tiers[0]

    return {
        "name": affix.name,
        "stat": affix.stat,
        "value": value,
        "quality_name": quality_name,
    }

# ============================================================
# 物品组装
# ============================================================
func _pick_base_item(_area_level: int) -> Dictionary:
    # TODO: 基于区域等级从 BaseItemData 池中选择
    var bases := [
        {"name": "短剑", "type": "weapon", "slot": "weapon_main", "min_damage": 3, "max_damage": 8},
        {"name": "斧", "type": "weapon", "slot": "weapon_main", "min_damage": 5, "max_damage": 12},
        {"name": "布甲", "type": "armor", "slot": "body", "defense": 5},
        {"name": "皮甲", "type": "armor", "slot": "body", "defense": 10},
        {"name": "戒指", "type": "jewelry", "slot": "ring_1", "defense": 0},
        {"name": "项链", "type": "jewelry", "slot": "amulet", "defense": 0},
    ]
    return bases[randi() % bases.size()]

func _build_item_data(base: Dictionary, rarity: Dictionary, affixes: Array[Dictionary], area_level: int) -> Dictionary:
    return {
        "base_name": base.name,
        "type": base.get("type", ""),
        "slot": base.get("slot", ""),
        "rarity": rarity.name,
        "rarity_color": rarity.color,
        "item_level": area_level,
        "base_stats": {
            "min_damage": base.get("min_damage", 0),
            "max_damage": base.get("max_damage", 0),
            "defense": base.get("defense", 0),
        },
        "affixes": affixes,
        "has_unique_power": rarity.get("has_unique", false),
        "unique_power": "",  # TODO: 传奇/远古时分配独特能力
    }

func _build_display_name(base: Dictionary, affixes: Array[Dictionary]) -> String:
    var parts: Array[String] = []

    # 前缀
    for a in affixes:
        if a.get("quality_name"):
            parts.append(a.quality_name)

    # 基础名称
    parts.append(base.name)

    # 后缀 (of ...)
    for a in affixes:
        if a.get("quality_name") and a.get("stat") in ["防御", "力量", "生命"]:
            parts.append("of %s" % a.quality_name)
            break

    return " ".join(parts)
