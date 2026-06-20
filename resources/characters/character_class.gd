# CharacterClass.gd - 职业定义
class_name CharacterClass
extends Resource

@export var class_id: String = ""                # 唯一标识 (barbarian, sorceress, necromancer)
@export var class_name: String = ""              # 显示名称 (野蛮人, 法师, 死灵法师)
@export var class_description: String = ""       # 职业描述
@export var base_strength: int = 20
@export var base_dexterity: int = 20
@export var base_vitality: int = 20
@export var base_energy: int = 20
@export var strength_per_level: float = 1.0
@export var dexterity_per_level: float = 1.0
@export var vitality_per_level: float = 1.0
@export var energy_per_level: float = 1.0
@export var life_per_vitality: float = 4.0       # 每点体力提供的生命
@export var mana_per_energy: float = 2.0         # 每点能量提供的法力
@export var damage_per_strength: float = 0.01    # 每点力量增加 %物理伤害
@export var damage_per_dexterity: float = 0.01   # 每点敏捷增加 %远程伤害
@export var damage_per_energy: float = 0.01      # 每点能量增加 %元素伤害
@export var skill_tree_ids: Array[String] = []   # 技能树 ID 列表
@export var starting_weapon: String = ""         # 初始武器 ID
@export var starting_armor: String = ""          # 初始防具 ID
@export var character_sprite: String = ""        # 角色贴图路径
@export var portrait_sprite: String = ""         # 头像贴图路径
