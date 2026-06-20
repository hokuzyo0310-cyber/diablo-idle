# StageData.gd - 阶段/关卡定义
class_name StageData
extends Resource

enum StageType {
    NORMAL,      # 普通阶段（小怪）
    BOSS         # Boss 阶段
}

enum Act {
    ACT_1,       # 鲜血荒地 → 地下墓穴
    ACT_2,       # 鲁高因 → 塔拉夏古墓
    ACT_3,       # 库拉斯特 → 憎恨囚牢
    ACT_4,       # 混沌避难所
    ACT_5        # 哈洛加斯 → 世界之石大殿
}

@export var stage_id: String = ""                # 唯一标识
@export var stage_name: String = ""              # 显示名称 ("鲜血荒地", "地下墓穴"...)
@export var stage_number: int = 1                # 阶段序号
@export var act: Act                             # 所属章节
@export var stage_type: StageType = StageType.NORMAL
@export var area_level: int = 1                  # 区域等级（影响掉落）
@export var enemy_count: int = 5                 # 怪物数量
@export var enemy_template_ids: Array[String] = [] # 可能出现的怪物模板
@export var boss_template_id: String = ""        # Boss 模板（仅 Boss 阶段）
@export var loot_table_bonus: float = 0.0        # 掉落加成
@export var experience_bonus: float = 0.0        # 经验加成
@export var background_path: String = ""         # 背景图路径
@export var ambience_sound: String = ""          # 环境音效
@export var unlocks_after_stage: int = -1        # 前置通关阶段 (-1 = 无前置)
