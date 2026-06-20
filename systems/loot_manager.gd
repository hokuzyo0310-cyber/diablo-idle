# LootManager.gd - Autoload 掉落管理器
# 负责物品生成：稀有度骰子、词缀选择、数值骰子、物品命名
extends Node

# 导入数据预设
var CharacterPresets = preload("res://data/character_presets.gd")
var EquipmentPresets = preload("res://data/equipment_presets.gd")
var EnemyPresets = preload("res://data/enemy_presets.gd")
var AffixPresets = preload("res://data/affix_presets.gd")
var StagePresets = preload("res://data/stage_presets.gd")

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
    # 从 data/ 目录加载预设数据
    rarity_tiers = AffixPresets.get_all_rarity_tiers()
    base_items = EquipmentPresets.get_all_base_items()

    # 初始化词缀池
    affix_pools = {
        "prefix": AffixPresets.PREFIX_AFFIXES,
        "suffix": AffixPresets.SUFFIX_AFFIXES,
    }

    print("✓ 掉落系统数据加载完成")

func _init_placeholder_data() -> void:
    # 已移至 _load_data_resources
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
    var tiers = rarity_tiers if not rarity_tiers.is_empty() else AffixPresets.get_all_rarity_tiers()

    var total_weight := 0.0
    for tier in tiers:
        var weight_mod = 1.0 + area_level * 0.02
        var mf_mod = 1.0 + magic_find / 100.0
        total_weight += tier.drop_weight * weight_mod * mf_mod

    var roll := randf() * total_weight
    var cumulative := 0.0
    for tier in tiers:
        var weight_mod = 1.0 + area_level * 0.02
        var mf_mod = 1.0 + magic_find / 100.0
        cumulative += tier.drop_weight * weight_mod * mf_mod
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
    if affix_type == "prefix":
        return affix_pools.get("prefix", AffixPresets.PREFIX_AFFIXES).duplicate()
    else:
        return affix_pools.get("suffix", AffixPresets.SUFFIX_AFFIXES).duplicate()

func _roll_single_affix(affix: Dictionary, area_level: int, rarity: Dictionary) -> Dictionary:
    var scaling := 1.0 + area_level * 0.1
    var min_val := affix.get("min_value", 1.0) * scaling
    var max_val := affix.get("max_value", 10.0) * scaling

    var value: float
    if rarity.get("name", "") == "远古":
        value = max_val
    else:
        value = randf_range(min_val, max_val)

    var pct := (value - min_val) / (max_val - min_val) * 100.0 if max_val > min_val else 100.0

    return {
        "name": affix.get("name", "未知"),
        "stat": affix.get("stat", ""),
        "value": value,
        "weight": affix.get("weight", 50.0),
    }

# ============================================================
# 物品组装
# ============================================================
func _pick_base_item(_area_level: int) -> Dictionary:
    var items = base_items if not base_items.is_empty() else EquipmentPresets.get_all_base_items()
    if items.is_empty():
        return {}
    return items[randi() % items.size()].duplicate()

func _build_item_data(base: Dictionary, rarity: Dictionary, affixes: Array[Dictionary], area_level: int) -> Dictionary:
    return {
        "base_name": base.get("name", "物品"),
        "item_id": base.get("item_id", ""),
        "type": base.get("type", ""),
        "slot": base.get("slot", ""),
        "rarity": rarity.get("name", "普通"),
        "rarity_color": rarity.get("color", "#ffffff"),
        "item_level": area_level,
        "base_stats": {
            "min_damage": base.get("base_min_damage", 0),
            "max_damage": base.get("base_max_damage", 0),
            "defense": base.get("base_defense", 0),
        },
        "affixes": affixes,
        "has_unique_power": rarity.get("has_unique_power", false),
        "unique_power": "",
        "sell_price": base.get("sell_price", 10),
    }

func _build_display_name(base: Dictionary, affixes: Array[Dictionary]) -> String:
    var parts: Array[String] = []

    for a in affixes:
        if a.get("stat") and "damage" in a.stat.to_lower():
            parts.append(a.get("name", ""))

    parts.append(base.get("name", "物品"))

    return " ".join(parts)
