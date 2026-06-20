# AffixData.gd - 单个词缀定义
class_name AffixData
extends Resource

enum AffixType {
    PREFIX,
    SUFFIX
}

enum AffixCategory {
    PHYSICAL_DAMAGE,    # 物理伤害
    ELEMENTAL_DAMAGE,   # 元素伤害
    ATTACK_SPEED,       # 攻击速度
    LIFE_LEECH,         # 生命偷取
    MANA_LEECH,         # 法力偷取
    CRITICAL_CHANCE,    # 暴击几率
    CRITICAL_DAMAGE,    # 暴击伤害
    MAGIC_FIND,         # 魔法发现
    DEFENSE,            # 防御
    ATTRIBUTE,          # 属性加成
    LIFE,               # 生命值
    MANA,               # 法力值
    RESISTANCE,         # 抗性
    GOLD_FIND,          # 金币获取
    ALL_SKILLS,         # 全技能等级
    UNIQUE              # 独特能力（传奇/远古专属）
}

@export var affix_id: String = ""                # 唯一标识
@export var affix_type: AffixType                # 前缀/后缀
@export var category: AffixCategory              # 词缀类别
@export var display_name: String = ""            # 显示名称
@export var stat_key: String = ""                # 影响属性的键名
@export var is_percentage: bool = true           # 百分比还是固定值
@export var min_value: float = 0.0               # 最小值（1级缩放基准）
@export var max_value: float = 0.0               # 最大值（1级缩放基准）
@export var value_scaling: float = 0.1           # 每区域等级的数值缩放比例
@export var selection_weight: float = 1.0        # 被选中权重
@export var allowed_slots: Array[String] = []    # 可出现的装备槽位（空=所有）
@export var tier_names: Array[String] = []       # 品质层级名称 (5个，从低到高)
@export var tier_thresholds: Array[float] = [0.2, 0.4, 0.6, 0.8, 1.0]  # 品质阈值
@export var min_area_level: int = 1              # 最低出现区域
