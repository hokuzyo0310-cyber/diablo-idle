# AttributeData.gd - 属性定义（用于 UI 显示）
class_name AttributeData
extends Resource

@export var attr_id: String = ""                 # 唯一标识
@export var attr_name: String = ""               # 显示名称
@export var attr_short_name: String = ""         # 缩写 (STR, DEX, VIT, ENE)
@export var attr_description: String = ""        # 描述文本
@export var icon_path: String = ""               # 图标路径 (assets/icons/attributes/)
@export var is_primary: bool = true              # 是否主属性（可手动分配）
@export var default_value: float = 0.0           # 默认值
@export var affects_stats: Array[String] = []    # 影响的派生属性列表
