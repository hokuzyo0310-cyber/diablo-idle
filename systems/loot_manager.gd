# ============================================================
# LootManager.gd — 掉落物品生成系统 (Autoload 单例)
# ============================================================
# 职责：
#   1. 稀有度骰子 — 基于权重随机决定物品品质 (普通→远古, 6级)
#   2. 词缀选择 — 从前后缀池中按权重选择词缀
#   3. 数值骰子 — 词缀具体数值在 min~max 间随机
#   4. 物品组装 — 将以上组合成一个完整的物品 Dictionary
#   5. 物品命名 — 生成带品质标识的显示名称
#
# 稀有度权重与分布 (基础):
#   普通 100.0  → ~62% (100/161.1)
#   魔法  40.0  → ~25% (40/161.1)
#   稀有  15.0  → ~9%  (15/161.1)
#   史诗   5.0  → ~3%  (5/161.1)
#   传奇   1.0  → ~0.6% (1/161.1)
#   远古   0.1  → ~0.06% (0.1/161.1)
#
# 影响因素:
#   - 区域等级 (area_level): 每级 +2% 总权重 → 高区域略提升高稀有度
#   - 魔法发现 (Magic Find): 每点 MF = +1% 总权重 → 装备 MF 词缀提升掉落质量
#
# 依赖:
#   - EquipmentPresets: 基础装备模板 (data/equipment_presets.gd)
#   - AffixPresets: 稀有度层级 + 词缀模板 (data/affix_presets.gd)
#   - EventBus: 物品掉落事件
# ============================================================
extends Node

# ============================================================
# 数据缓存 — 在 _ready 中加载，避免每次生成都查询
# ============================================================
var rarity_tiers: Array = []         # Array[Dictionary] — 6级稀有度数据
var base_items: Array = []           # Array[Dictionary] — 所有基础物品模板
var affix_pools: Dictionary = {}     # "prefix" → Array[Dictionary], "suffix" → Array[Dictionary]

# ============================================================
# 初始化 — 从预设数据加载所有模板
# ============================================================
func _ready() -> void:
    _load_data_resources()

func _load_data_resources() -> void:
    # 加载稀有度层级 (普通/魔法/稀有/史诗/传奇/远古)
    rarity_tiers = AffixPresets.get_all_rarity_tiers()
    # 加载基础物品 (武器/防具/珠宝)
    base_items = EquipmentPresets.get_all_base_items()

    # 初始化词缀池 (前缀=进攻, 后缀=防御/属性)
    affix_pools = {
        "prefix": AffixPresets.PREFIX_AFFIXES,
        "suffix": AffixPresets.SUFFIX_AFFIXES,
    }

    print("✓ 掉落系统数据加载完成")

func _init_placeholder_data() -> void:
    # 已移至 _load_data_resources — 保留空方法避免引用错误
    pass

# ============================================================
# 物品生成主入口 — 完整的 6 步流程
# ============================================================
# 参数:
#   area_level: 区域等级 (影响数值缩放和稀有度权重)
#   magic_find: 魔法发现加成 (0.0 = 无加成, 100.0 = +100% MF)
# 返回:
#   完整的物品 Dictionary，失败返回空字典 {}
func generate_item(area_level: int, magic_find: float = 0.0) -> Dictionary:
    # Step 1: 选择基础物品类型 (随机从所有模板中选一个)
    var base: Dictionary = _pick_base_item(area_level)
    if base.is_empty():
        return {}

    # Step 2: 骰稀有度 — 加权随机决定物品品质
    var rarity: Dictionary = _roll_rarity(area_level, magic_find)

    # Step 3: 确定词缀数量 — 稀有度决定最少/最多词缀数
    #   例: 魔法 1-2词缀, 稀有 3-4词缀, 传奇 6词缀
    var num_affixes: int = randi_range(rarity.get("min_affixes", 0), rarity.get("max_affixes", 0))
    # 前缀和后缀各约一半 (奇数时前缀多1)
    var num_prefixes := ceili(num_affixes / 2.0)
    var num_suffixes := num_affixes - num_prefixes

    # Step 4: 选择并骰词缀 — 从前缀/后缀池中按权重抽取
    var selected_affixes: Array[Dictionary] = []
    selected_affixes.append_array(_roll_affixes("prefix", num_prefixes, area_level, rarity, base))
    selected_affixes.append_array(_roll_affixes("suffix", num_suffixes, area_level, rarity, base))

    # Step 5: 组装物品数据 — 将 base + rarity + affixes 合并
    var item := _build_item_data(base, rarity, selected_affixes, area_level)

    # Step 6: 生成显示名称 — "残忍的 剑 of 坚韧的"
    item["display_name"] = _build_display_name(base, selected_affixes)

    # 广播掉落事件 (UI 监听 → 战斗日志显示)
    EventBus.item_dropped.emit(item)
    return item

# ============================================================
# 稀有度骰子 — 加权随机选择品质
# ============================================================
# 算法: 累计权重法 (Cumulative Weighted Random)
#   1. 计算每个稀有度的实际权重 = 基础权重 × (1 + area_level×0.02) × (1 + MF/100)
#   2. 随机值在 [0, 总权重] 区间
#   3. 从低到高累计权重，首次超过随机值时选中
#
# 区域等级影响: area_level=1 无加成, area_level=10 有+20% 权重
# MF 影响: MF=100 总权重翻倍 → 高稀有度概率提升
func _roll_rarity(area_level: int, magic_find: float) -> Dictionary:
    # 使用缓存或从 AffixPresets 获取
    var tiers = rarity_tiers if not rarity_tiers.is_empty() else AffixPresets.get_all_rarity_tiers()

    # 计算总权重
    var total_weight := 0.0
    for tier in tiers:
        # 区域等级加成: 每级 +2%
        var weight_mod = 1.0 + area_level * 0.02
        # 魔法发现加成: 每点 MF +1%
        var mf_mod = 1.0 + magic_find / 100.0
        total_weight += tier.drop_weight * weight_mod * mf_mod

    # 加权随机选择
    var roll := randf() * total_weight
    var cumulative := 0.0
    for tier in tiers:
        var weight_mod = 1.0 + area_level * 0.02
        var mf_mod = 1.0 + magic_find / 100.0
        cumulative += tier.drop_weight * weight_mod * mf_mod
        if roll <= cumulative:
            return tier  # 返回的是 Dictionary (复制自 AffixPresets)

    # 保底: 返回普通品质 (理论上不会到这里)
    return tiers[0]

# ============================================================
# 词缀生成 — 从池中随机抽取词缀并骰数值
# ============================================================
# 参数:
#   affix_type: "prefix" (进攻向) 或 "suffix" (防御/属性向)
#   count: 需要生成的词缀数量
#   area_level: 区域等级 (影响数值缩放)
#   rarity: 稀有度信息 (远古保证最大骰值)
#   base: 基础物品信息 (影响可出词缀池)
func _roll_affixes(affix_type: String, count: int, area_level: int, rarity: Dictionary, base: Dictionary) -> Array[Dictionary]:
    var results: Array[Dictionary] = []
    # 获取可用词缀池的副本 (每次独立，避免修改全局池)
    var available := _get_available_affixes(affix_type, base)

    for _i in range(count):
        if available.is_empty():
            break  # 池子空了 → 停止生成

        # 随机选择一个词缀
        var idx := randi() % available.size()
        var affix := available[idx]
        # 骰具体数值 (受区域等级和稀有度影响)
        var rolled := _roll_single_affix(affix, area_level, rarity)
        results.append(rolled)
        # 从可用池移除 → 避免同一个词缀出现两次
        available.remove_at(idx)

    return results

# 获取可用词缀池 — 当前实现不分物品类型，所有物品共享同一词缀池
# 后续可扩展: 根据 base.slot 或 base.type 限制可用词缀
func _get_available_affixes(affix_type: String, base: Dictionary) -> Array[Dictionary]:
    if affix_type == "prefix":
        return affix_pools.get("prefix", AffixPresets.PREFIX_AFFIXES).duplicate()
    else:
        return affix_pools.get("suffix", AffixPresets.SUFFIX_AFFIXES).duplicate()

# 骰单个词缀的实际数值
# 数值公式: min/max × (1 + area_level × 0.1) → 随机取值
#   例: 炎热的 (火焰伤害 3~10), area_level=10 → 6~20
# 特别规则: 远古物品保证取最大值 (max_roll_guaranteed)
func _roll_single_affix(affix: Dictionary, area_level: int, rarity: Dictionary) -> Dictionary:
    # 区域等级缩放: 每级 +10%
    var scaling := 1.0 + area_level * 0.1
    var min_val: float = affix.get("min_value", 1.0) * scaling
    var max_val: float = affix.get("max_value", 10.0) * scaling

    var value: float
    # 远古物品 → 词缀值取最大值 (保证完美骰值)
    if rarity.get("name", "") == "远古":
        value = max_val
    else:
        # 普通~传奇 → 在范围内随机
        value = randf_range(min_val, max_val)

    # 计算品质百分比 (用于后续品质命名)
    var pct: float = (value - min_val) / (max_val - min_val) * 100.0 if max_val > min_val else 100.0

    return {
        "name": affix.get("name", "未知"),       # 词缀名 (如 "炎热的")
        "stat": affix.get("stat", ""),           # 影响的属性 (如 "fire_damage")
        "value": value,                          # 骰得的实际数值
        "weight": affix.get("weight", 50.0),     # 词缀权重 (保留参考)
        "quality_pct": pct,                      # 品质百分比 (0~100)
    }

# ============================================================
# 物品组装 — 将所有信息合并为完整物品
# ============================================================

# 随机选择一个基础物品模板
func _pick_base_item(_area_level: int) -> Dictionary:
    var items = base_items if not base_items.is_empty() else EquipmentPresets.get_all_base_items()
    if items.is_empty():
        return {}
    # 等概率随机 — 所有物品类型权重相同 (后续可加权)
    return items[randi() % items.size()].duplicate()

# 组装物品数据
func _build_item_data(base: Dictionary, rarity: Dictionary, affixes: Array[Dictionary], area_level: int) -> Dictionary:
    return {
        # 基础信息
        "base_name": base.get("name", "物品"),           # 基础名 (如 "剑")
        "item_id": base.get("item_id", ""),             # 模板ID
        "type": base.get("type", ""),                   # WEAPON / ARMOR / JEWELRY
        "slot": base.get("slot", ""),                   # 装备槽位
        # 稀有度
        "rarity": rarity.get("name", "普通"),            # 品质名
        "rarity_color": rarity.get("color", "#ffffff"),  # 品质色码
        "item_level": area_level,                        # 物品等级
        # 基础战斗属性
        "base_stats": {
            "min_damage": base.get("base_min_damage", 0),
            "max_damage": base.get("base_max_damage", 0),
            "defense": base.get("base_defense", 0),
        },
        # 词缀列表
        "affixes": affixes,
        # 传奇/远古独有能力 (Phase 2 实现)
        "has_unique_power": rarity.get("has_unique_power", false),
        "unique_power": "",
        # 经济
        "sell_price": base.get("sell_price", 10),
    }

# 生成物品显示名称 — 格式: "[品质前缀] 基础名 [of 品质后缀]"
# 例: "残忍的 剑 of 坚韧的"
# 简化实现: 只取第一个前缀和第一个后缀的名字
func _build_display_name(base: Dictionary, affixes: Array[Dictionary]) -> String:
    var parts: Array[String] = []

    # 添加前缀名 (进攻向词缀) — 取第一个 damage 相关词缀
    for a in affixes:
        if a.get("stat") and "damage" in a.stat.to_lower():
            parts.append(a.get("name", ""))
            break  # 只取第一个

    # 基础物品名
    parts.append(base.get("name", "物品"))

    # 添加后缀名 (防御/属性向词缀)
    # 当前简化: 只在名称中体现前缀，后缀在详情中查看
    # 完整实现见 StringHelper.build_item_name()

    return " ".join(parts)
