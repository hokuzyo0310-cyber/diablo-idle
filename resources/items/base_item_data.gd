# BaseItemData.gd - 基础物品定义
# 所有可掉落装备的基础模板
class_name BaseItemData
extends Resource

enum ItemType {
    WEAPON,
    ARMOR,
    OFFHAND,
    JEWELRY,
    CONSUMABLE
}

enum WeaponSubType {
    SWORD, AXE, MACE, DAGGER,
    WAND, STAFF, SCYTHE,
    BOW, CROSSBOW
}

enum ArmorSubType {
    HELM, BODY_ARMOR, GLOVES, BOOTS, BELT
}

@export var item_id: String = ""                 # 唯一标识符
@export var base_name: String = ""               # 基础名称（"短剑"、"布甲"）
@export var item_type: ItemType                  # 物品大类
@export var weapon_sub_type: WeaponSubType       # 武器子类型
@export var armor_sub_type: ArmorSubType         # 防具子类型
@export var equipment_slot: String = ""           # 装备槽位 (weapon_main, body, ring_1...)
@export var required_level: int = 1              # 装备需求等级
@export var required_strength: int = 0           # 需求力量
@export var required_dexterity: int = 0          # 需求敏捷
@export var inventory_size: Vector2 = Vector2(1, 1)  # 占用的背包格子
@export var base_min_damage: float = 0.0         # 基础最小伤害（武器）
@export var base_max_damage: float = 0.0         # 基础最大伤害（武器）
@export var base_defense: float = 0.0            # 基础防御（防具）
@export var attack_speed: float = 1.0            # 基础攻速（每秒攻击次数）
@export var allowed_affix_pools: Array[String] = []  # 可出现的词缀池 ID
@export var drop_weight: float = 1.0             # 掉落权重
@export var min_area_level: int = 1              # 最低出现区域等级
