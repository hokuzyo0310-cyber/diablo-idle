# 基础装备预设数据

const WEAPONS = {
	"sword": {
		"item_id": "sword",
		"name": "剑",
		"type": "WEAPON",
		"slot": "weapon_main",
		"base_min_damage": 5,
		"base_max_damage": 12,
		"base_defense": 0,
		"required_level": 1,
		"sell_price": 50,
	},
	"axe": {
		"item_id": "axe",
		"name": "斧",
		"type": "WEAPON",
		"slot": "weapon_main",
		"base_min_damage": 8,
		"base_max_damage": 16,
		"base_defense": 0,
		"required_level": 1,
		"sell_price": 60,
	},
	"dagger": {
		"item_id": "dagger",
		"name": "匕首",
		"type": "WEAPON",
		"slot": "weapon_main",
		"base_min_damage": 3,
		"base_max_damage": 8,
		"base_defense": 0,
		"required_level": 1,
		"sell_price": 30,
	},
	"staff": {
		"item_id": "staff",
		"name": "法杖",
		"type": "WEAPON",
		"slot": "weapon_main",
		"base_min_damage": 4,
		"base_max_damage": 10,
		"base_defense": 2,
		"required_level": 1,
		"sell_price": 40,
	},
}

const ARMOR = {
	"helm": {
		"item_id": "helm",
		"name": "头盔",
		"type": "ARMOR",
		"slot": "head",
		"base_min_damage": 0,
		"base_max_damage": 0,
		"base_defense": 5,
		"required_level": 1,
		"sell_price": 40,
	},
	"body_armor": {
		"item_id": "body_armor",
		"name": "盔甲",
		"type": "ARMOR",
		"slot": "body",
		"base_min_damage": 0,
		"base_max_damage": 0,
		"base_defense": 10,
		"required_level": 1,
		"sell_price": 60,
	},
	"gloves": {
		"item_id": "gloves",
		"name": "手套",
		"type": "ARMOR",
		"slot": "hands",
		"base_min_damage": 0,
		"base_max_damage": 0,
		"base_defense": 3,
		"required_level": 1,
		"sell_price": 30,
	},
	"boots": {
		"item_id": "boots",
		"name": "靴子",
		"type": "ARMOR",
		"slot": "feet",
		"base_min_damage": 0,
		"base_max_damage": 0,
		"base_defense": 3,
		"required_level": 1,
		"sell_price": 30,
	},
	"robe": {
		"item_id": "robe",
		"name": "法袍",
		"type": "ARMOR",
		"slot": "body",
		"base_min_damage": 0,
		"base_max_damage": 0,
		"base_defense": 5,
		"required_level": 1,
		"sell_price": 50,
	},
}

const JEWELRY = {
	"ring": {
		"item_id": "ring",
		"name": "戒指",
		"type": "JEWELRY",
		"slot": "ring",
		"base_min_damage": 0,
		"base_max_damage": 0,
		"base_defense": 0,
		"required_level": 1,
		"sell_price": 20,
	},
	"amulet": {
		"item_id": "amulet",
		"name": "项链",
		"type": "JEWELRY",
		"slot": "neck",
		"base_min_damage": 0,
		"base_max_damage": 0,
		"base_defense": 0,
		"required_level": 1,
		"sell_price": 25,
	},
}

static func get_all_base_items() -> Array[Dictionary]:
	var items: Array[Dictionary] = []
	items.append_array(WEAPONS.values())
	items.append_array(ARMOR.values())
	items.append_array(JEWELRY.values())
	return items

static func get_base_item(item_id: String) -> Dictionary:
	if WEAPONS.has(item_id):
		return WEAPONS[item_id]
	if ARMOR.has(item_id):
		return ARMOR[item_id]
	if JEWELRY.has(item_id):
		return JEWELRY[item_id]
	return {}
