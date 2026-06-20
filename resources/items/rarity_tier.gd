# RarityTier.gd - 稀有度层级定义
class_name RarityTier
extends Resource

@export var tier_id: int = 0                     # 稀有度等级 (0=普通, 5=远古)
@export var tier_name: String = ""               # 显示名称 ("普通"、"魔法"...)
@export var name_color: Color = Color.WHITE      # 名称颜色
@export var min_affixes: int = 0                 # 最少词缀数
@export var max_affixes: int = 0                 # 最多词缀数
@export var drop_weight: float = 1.0             # 基础掉落权重
@export var beam_color: Color = Color.WHITE      # 掉落光束颜色
@export var has_unique_power: bool = false       # 是否生成独特能力
@export var max_roll_guaranteed: bool = false    # 是否保证最大骰值（远古专属）
@export var display_prefix: String = ""          # 名称前缀修饰
@export var display_suffix: String = ""          # 名称后缀修饰
