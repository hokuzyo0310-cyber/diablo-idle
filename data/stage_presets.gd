# 阶段预设数据（Act 1）
extends RefCounted

const STAGES = {
	# Act 1: 沼泽
	1: {
		"stage_id": 1,
		"stage_name": "沼泽",
		"area_level": 1,
		"act": 1,
		"is_boss": false,
		"enemy_templates": ["skeleton", "zombie", "fallen"],
		"enemy_count_min": 3,
		"enemy_count_max": 5,
		"base_gold_drop": 5,
		"base_xp_drop": 10,
	},
	2: {
		"stage_id": 2,
		"stage_name": "沼泽 2",
		"area_level": 2,
		"act": 1,
		"is_boss": false,
		"enemy_templates": ["skeleton", "zombie", "demon", "fallen"],
		"enemy_count_min": 3,
		"enemy_count_max": 5,
		"base_gold_drop": 6,
		"base_xp_drop": 12,
	},
	3: {
		"stage_id": 3,
		"stage_name": "朽败村落",
		"area_level": 3,
		"act": 1,
		"is_boss": false,
		"enemy_templates": ["zombie", "demon", "fallen"],
		"enemy_count_min": 3,
		"enemy_count_max": 5,
		"base_gold_drop": 7,
		"base_xp_drop": 14,
	},
	4: {
		"stage_id": 4,
		"stage_name": "朽败村落 2",
		"area_level": 4,
		"act": 1,
		"is_boss": false,
		"enemy_templates": ["zombie", "demon", "fallen"],
		"enemy_count_min": 4,
		"enemy_count_max": 6,
		"base_gold_drop": 8,
		"base_xp_drop": 16,
	},
	5: {
		"stage_id": 5,
		"stage_name": "扭曲树精的巢穴",
		"area_level": 5,
		"act": 1,
		"is_boss": true,
		"boss_template": "andariel",
		"enemy_templates": ["skeleton", "zombie"],
		"enemy_count_min": 2,
		"enemy_count_max": 3,
		"base_gold_drop": 20,
		"base_xp_drop": 50,
	},
	6: {
		"stage_id": 6,
		"stage_name": "深沼地",
		"area_level": 6,
		"act": 1,
		"is_boss": false,
		"enemy_templates": ["zombie", "demon", "fallen"],
		"enemy_count_min": 4,
		"enemy_count_max": 6,
		"base_gold_drop": 9,
		"base_xp_drop": 18,
	},
	7: {
		"stage_id": 7,
		"stage_name": "深沼地 2",
		"area_level": 7,
		"act": 1,
		"is_boss": false,
		"enemy_templates": ["demon", "fallen"],
		"enemy_count_min": 4,
		"enemy_count_max": 6,
		"base_gold_drop": 10,
		"base_xp_drop": 20,
	},
	8: {
		"stage_id": 8,
		"stage_name": "沼泽深处",
		"area_level": 8,
		"act": 1,
		"is_boss": false,
		"enemy_templates": ["demon", "fallen"],
		"enemy_count_min": 4,
		"enemy_count_max": 6,
		"base_gold_drop": 11,
		"base_xp_drop": 22,
	},
	9: {
		"stage_id": 9,
		"stage_name": "沼泽深处 2",
		"area_level": 9,
		"act": 1,
		"is_boss": false,
		"enemy_templates": ["demon", "fallen"],
		"enemy_count_min": 5,
		"enemy_count_max": 7,
		"base_gold_drop": 12,
		"base_xp_drop": 24,
	},
	10: {
		"stage_id": 10,
		"stage_name": "扭曲树精之王",
		"area_level": 10,
		"act": 1,
		"is_boss": true,
		"boss_template": "andariel",
		"enemy_templates": ["zombie", "demon"],
		"enemy_count_min": 2,
		"enemy_count_max": 3,
		"base_gold_drop": 30,
		"base_xp_drop": 100,
	},
}

static func find_stage(stage_id: int) -> Dictionary:
	if STAGES.has(stage_id):
		return STAGES[stage_id].duplicate()
	return STAGES[1].duplicate()

static func get_all_stages() -> Array[int]:
	return STAGES.keys()

static func is_boss_stage(stage_id: int) -> bool:
	var stage = find_stage(stage_id)
	return stage.get("is_boss", false)
