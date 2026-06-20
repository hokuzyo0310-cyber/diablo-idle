# 角色职业预设数据
# 在 _ready() 时由 LootManager 加载

const BARBARIAN = {
	"class_id": "barbarian",
	"class_name": "野蛮人",
	"description": "近战坦克，高血量和物理伤害",
	"base_strength": 30,
	"base_dexterity": 20,
	"base_vitality": 25,
	"base_energy": 10,
	"starting_weapon_id": "sword",
	"starting_armor_id": "helm",
}

const SORCERESS = {
	"class_id": "sorceress",
	"class_name": "法师",
	"description": "元素炮台，低血量高魔法伤害",
	"base_strength": 10,
	"base_dexterity": 25,
	"base_vitality": 15,
	"base_energy": 35,
	"starting_weapon_id": "dagger",
	"starting_armor_id": "robe",
}

const NECROMANCER = {
	"class_id": "necromancer",
	"class_name": "死灵法师",
	"description": "召唤指挥官，中等血量和平衡伤害",
	"base_strength": 15,
	"base_dexterity": 25,
	"base_vitality": 20,
	"base_energy": 25,
	"starting_weapon_id": "staff",
	"starting_armor_id": "robe",
}

static func get_all_classes() -> Array[Dictionary]:
	return [BARBARIAN, SORCERESS, NECROMANCER]

static func get_class(class_id: String) -> Dictionary:
	match class_id:
		"barbarian": return BARBARIAN
		"sorceress": return SORCERESS
		"necromancer": return NECROMANCER
		_: return BARBARIAN
