# 敌人模板预设数据
extends RefCounted

const ENEMIES = {
	"skeleton": {
		"enemy_id": "skeleton",
		"display_name": "骷髅战士",
		"is_boss": false,
		"base_health": 15,
		"base_damage": 3,
		"base_defense": 1,
		"xp_multiplier": 1.0,
		"gold_multiplier": 1.0,
	},
	"zombie": {
		"enemy_id": "zombie",
		"display_name": "腐尸",
		"is_boss": false,
		"base_health": 20,
		"base_damage": 2,
		"base_defense": 2,
		"xp_multiplier": 1.1,
		"gold_multiplier": 1.1,
	},
	"demon": {
		"enemy_id": "demon",
		"display_name": "恶魔",
		"is_boss": false,
		"base_health": 25,
		"base_damage": 4,
		"base_defense": 1,
		"xp_multiplier": 1.2,
		"gold_multiplier": 1.2,
	},
	"fallen": {
		"enemy_id": "fallen",
		"display_name": "堕落者",
		"is_boss": false,
		"base_health": 18,
		"base_damage": 3,
		"base_defense": 1,
		"xp_multiplier": 1.0,
		"gold_multiplier": 1.0,
	},
}

const BOSSES = {
	"andariel": {
		"enemy_id": "andariel",
		"display_name": "安达瑞尔",
		"is_boss": true,
		"base_health": 100,
		"base_damage": 8,
		"base_defense": 3,
		"xp_multiplier": 5.0,
		"gold_multiplier": 5.0,
	},
	"duriel": {
		"enemy_id": "duriel",
		"display_name": "杜瑞尔",
		"is_boss": true,
		"base_health": 150,
		"base_damage": 10,
		"base_defense": 4,
		"xp_multiplier": 6.0,
		"gold_multiplier": 6.0,
	},
}

static func find_enemy_template(enemy_id: String) -> Dictionary:
	if ENEMIES.has(enemy_id):
		return ENEMIES[enemy_id].duplicate()
	if BOSSES.has(enemy_id):
		return BOSSES[enemy_id].duplicate()
	return ENEMIES["skeleton"].duplicate()

static func get_all_normal_enemies() -> Array[String]:
	return ENEMIES.keys()

static func get_all_bosses() -> Array[String]:
	return BOSSES.keys()
