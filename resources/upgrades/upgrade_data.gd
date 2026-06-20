# UpgradeData.gd - 升级/转生加成节点定义
class_name UpgradeData
extends Resource

enum UpgradeCategory {
    PRESTIGE,        # 转生加成
    ARTISAN,         # 工匠升级（铁匠/珠宝匠）
    TALENT           # 天赋树
}

enum UpgradeTarget {
    ALL_DAMAGE,           # 所有伤害
    PHYSICAL_DAMAGE,      # 物理伤害
    ELEMENTAL_DAMAGE,     # 元素伤害
    GOLD_FIND,            # 金币获取
    MAGIC_FIND,           # 魔法发现
    EXPERIENCE_GAIN,      # 经验获取
    ATTACK_SPEED,         # 攻击速度
    LIFE,                 # 最大生命
    MANA,                 # 最大法力
    RESISTANCE_ALL,       # 全抗性
    OFFLINE_EFFICIENCY,   # 离线效率
    AUTO_LOOT,            # 自动拾取范围
    INVENTORY_SIZE,       # 背包容量
}

@export var upgrade_id: String = ""              # 唯一标识
@export var upgrade_name: String = ""            # 显示名称
@export var category: UpgradeCategory            # 类别
@export var target: UpgradeTarget                # 加成目标
@export var bonus_per_level: float = 0.05        # 每级加成（5% = 0.05）
@export var is_percentage: bool = true           # 百分比还是固定值
@export var max_level: int = 10                  # 最大等级
@export var base_cost: float = 1.0               # 基础成本（灵魂/金币）
@export var cost_multiplier: float = 2.0         # 每级成本倍率
@export var required_prestige: int = 0           # 所需转生次数
@export var description: String = ""             # 描述
@export var icon_path: String = ""               # 图标路径
