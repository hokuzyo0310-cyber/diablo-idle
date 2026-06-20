# AffixPool.gd - 词缀池
# 将同类词缀分组，便于按权重随机选择
class_name AffixPool
extends Resource

enum AffixType {
    PREFIX,    # 前缀（进攻/功能向）
    SUFFIX     # 后缀（防御/属性向）
}

@export var pool_id: String = ""                 # 唯一标识 (e.g., "prefix_offensive")
@export var pool_name: String = ""               # 显示名称 (e.g., "进攻前缀池")
@export var affix_type: AffixType = AffixType.PREFIX
@export var affixes: Array[AffixData] = []       # 此池包含的词缀
@export var default_weight: float = 1.0          # 池的整体权重倍率
