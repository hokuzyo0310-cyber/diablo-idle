# SkillData.gd - 技能定义
class_name SkillData
extends Resource

enum SkillType {
	ACTIVE,      # 主动技能（有冷却）
	PASSIVE,     # 被动技能（始终生效）
	AURA         # 光环（影响自身和附近目标）
}

enum DamageElement {
	PHYSICAL, FIRE, COLD, LIGHTNING, POISON, ARCANE, HOLY, SHADOW
}

@export var skill_id: String = ""                # 唯一标识
@export var skill_name: String = ""              # 显示名称
@export var skill_description: String = ""       # 描述
@export var skill_type: SkillType                # 主动/被动/光环
@export var damage_element: DamageElement        # 伤害元素
@export var icon_path: String = ""               # 图标路径 (assets/icons/skills/)
@export var max_level: int = 20                  # 最大技能等级
@export var base_cooldown: float = 0.0           # 基础冷却时间（0=无冷却）
@export var base_mana_cost: float = 0.0          # 基础法力消耗
@export var base_damage_multiplier: float = 1.0  # 基础伤害倍率
@export var damage_per_level: float = 0.1        # 每级伤害增长
@export var prerequisites: Array[String] = []    # 前置技能 ID 列表
@export var required_level: int = 1              # 解锁所需等级
@export var tree_position: Vector2 = Vector2.ZERO # 技能树中位置
