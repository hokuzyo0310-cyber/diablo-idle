# 词缀预设数据（前缀和后缀）
extends RefCounted

const RARITY_TIERS = [
	{
		"tier_id": 0,
		"name": "普通",
		"color": "#ffffff",
		"min_affixes": 0,
		"max_affixes": 0,
		"drop_weight": 100.0,
		"has_unique_power": false,
	},
	{
		"tier_id": 1,
		"name": "魔法",
		"color": "#4169e1",
		"min_affixes": 1,
		"max_affixes": 2,
		"drop_weight": 40.0,
		"has_unique_power": false,
	},
	{
		"tier_id": 2,
		"name": "稀有",
		"color": "#ffd700",
		"min_affixes": 3,
		"max_affixes": 4,
		"drop_weight": 15.0,
		"has_unique_power": false,
	},
	{
		"tier_id": 3,
		"name": "史诗",
		"color": "#daa520",
		"min_affixes": 5,
		"max_affixes": 6,
		"drop_weight": 5.0,
		"has_unique_power": false,
	},
	{
		"tier_id": 4,
		"name": "传奇",
		"color": "#ff8c00",
		"min_affixes": 6,
		"max_affixes": 6,
		"drop_weight": 1.0,
		"has_unique_power": true,
	},
	{
		"tier_id": 5,
		"name": "远古",
		"color": "#ff4444",
		"min_affixes": 6,
		"max_affixes": 6,
		"drop_weight": 0.1,
		"has_unique_power": true,
	},
]

# 前缀词缀（进攻向）
const PREFIX_AFFIXES = [
	{"name": "锋利的", "stat": "increased_physical_damage", "min_value": 5, "max_value": 15, "weight": 100.0},
	{"name": "炎热的", "stat": "fire_damage", "min_value": 3, "max_value": 10, "weight": 80.0},
	{"name": "冰冷的", "stat": "cold_damage", "min_value": 3, "max_value": 10, "weight": 80.0},
	{"name": "闪电的", "stat": "lightning_damage", "min_value": 3, "max_value": 10, "weight": 80.0},
	{"name": "剧毒的", "stat": "poison_damage", "min_value": 3, "max_value": 10, "weight": 60.0},
	{"name": "吸血的", "stat": "life_steal", "min_value": 2, "max_value": 8, "weight": 40.0},
	{"name": "致命的", "stat": "critical_chance", "min_value": 2, "max_value": 8, "weight": 50.0},
	{"name": "快速的", "stat": "attack_speed", "min_value": 5, "max_value": 15, "weight": 60.0},
]

# 后缀词缀（防御/属性向）
const SUFFIX_AFFIXES = [
	{"name": "防御的", "stat": "increased_defense", "min_value": 5, "max_value": 15, "weight": 100.0},
	{"name": "生命的", "stat": "increased_health", "min_value": 10, "max_value": 40, "weight": 90.0},
	{"name": "坚韧的", "stat": "increased_vitality", "min_value": 2, "max_value": 8, "weight": 70.0},
	{"name": "力量的", "stat": "increased_strength", "min_value": 2, "max_value": 8, "weight": 70.0},
	{"name": "敏捷的", "stat": "increased_dexterity", "min_value": 2, "max_value": 8, "weight": 70.0},
	{"name": "知识的", "stat": "increased_energy", "min_value": 2, "max_value": 8, "weight": 70.0},
	{"name": "掘金者的", "stat": "increased_gold_find", "min_value": 10, "max_value": 30, "weight": 50.0},
	{"name": "幸运的", "stat": "increased_magic_find", "min_value": 10, "max_value": 30, "weight": 50.0},
]

static func get_rarity_tier(tier_id: int) -> Dictionary:
	if tier_id >= 0 and tier_id < RARITY_TIERS.size():
		return RARITY_TIERS[tier_id].duplicate()
	return RARITY_TIERS[0].duplicate()

static func get_all_rarity_tiers() -> Array[Dictionary]:
	return RARITY_TIERS.duplicate()

static func get_random_prefix() -> Dictionary:
	return PREFIX_AFFIXES[randi() % PREFIX_AFFIXES.size()].duplicate()

static func get_random_suffix() -> Dictionary:
	return SUFFIX_AFFIXES[randi() % SUFFIX_AFFIXES.size()].duplicate()

static func get_random_affixes(count: int, rarity: int = 1) -> Array[Dictionary]:
	var affixes: Array[Dictionary] = []
	var tier = get_rarity_tier(rarity)
	var actual_count = mini(count, tier.max_affixes)

	for i in range(actual_count):
		if randf() > 0.5:
			affixes.append(get_random_prefix())
		else:
			affixes.append(get_random_suffix())

	return affixes
