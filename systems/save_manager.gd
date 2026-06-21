# ============================================================
# SaveManager.gd — 存档/读档/离线进度管理器 (Autoload 单例)
# ============================================================
# 职责：
#   1. 存档: 收集 GameManager 状态 → 序列化为 JSON → 写入 user://save.json
#   2. 读档: 从 user://save.json 读取 → 反序列化 → 恢复到 GameManager
#   3. 离线进度: 对比存档时间戳与当前时间 → 计算离线收益
#   4. 存档管理: 删除存档、检查存档存在性
#
# 设计决策：
#   - JSON 格式: 明文、可读、易于调试和手动修改 (Phase 1 MVP 不加密)
#   - 存档路径: user://save.json (Godot 用户数据目录)
#   - 版本号: 存档中包含 version 字段，便于后续存档格式迁移
#   - 离线判定: 离线超过 30 秒才计算离线收益 (避免频繁切窗口误判)
#   - 窗口关闭: 通过 NOTIFICATION_WM_CLOSE_REQUEST 自动保存
#
# 存档 JSON 结构:
#   {
#     "version": 1,           // 存档格式版本号
#     "timestamp": 1750000000, // 存档时的 Unix 时间戳
#     "gold": 1234567.0,       // 金币
#     "souls": 450.0,          // 灵魂货币
#     "blood_shards": 3.0,     // 血石
#     "character_class": "barbarian",
#     "level": 42,
#     "experience": 5678.0,
#     "experience_to_next": 8912.0,
#     "strength": 82, "dexterity": 62, "vitality": 75, "energy": 42,
#     "unspent_points": 0,
#     "equipped_items": { ... },
#     "inventory": [ ... ],
#     "current_stage": 18,
#     "difficulty": "普通",
#     "prestige_count": 2,
#     "total_kills": 54321,
#     "total_gold_earned": 9876543.0
#   }
#
# 依赖:
#   - GameManager: 游戏状态数据源
#   - EventBus: 存档/读档/离线进度事件
# ============================================================
extends Node

# 存档路径: user:// 指向操作系统用户数据目录
#   Windows: %APPDATA%/Godot/app_userdata/DiabloIdle/
#   macOS:   ~/Library/Application Support/Godot/app_userdata/DiabloIdle/
#   Linux:   ~/.local/share/godot/app_userdata/DiabloIdle/
const SAVE_PATH := "user://save.json"

# ============================================================
# 存档 — 将当前游戏状态序列化并写入磁盘
# ============================================================
func save_game() -> void:
    # 步骤 1: 从 GameManager 收集所有需要保存的数据
    var data := _collect_save_data()

    # 步骤 2: 打开文件进行写入
    var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
    if not file:
        push_error("[SaveManager] 无法写入存档: 错误代码 %d" % FileAccess.get_open_error())
        return

    # 步骤 3: 序列化为 JSON (使用缩进格式，便于人工查看)
    file.store_string(JSON.stringify(data, "\t"))
    file.close()

    # 步骤 4: 广播保存完成事件
    EventBus.game_saved.emit()
    print("[SaveManager] 游戏已保存 (金币: %d, 等级: %d)" % [data.gold, data.level])

# 从 GameManager 收集所有需要持久化的数据
func _collect_save_data() -> Dictionary:
    return {
        # 存档元信息
        "version": 1,                                    # 当前存档格式版本
        "timestamp": Time.get_unix_time_from_system(),   # Unix 时间戳 (秒)

        # 货币
        "gold": GameManager.gold,
        "souls": GameManager.souls,
        "blood_shards": GameManager.blood_shards,

        # 角色核心数据
        "character_class": GameManager.character_class,
        "level": GameManager.level,
        "experience": GameManager.experience,
        "experience_to_next": GameManager.experience_to_next,
        "strength": GameManager.strength,
        "dexterity": GameManager.dexterity,
        "vitality": GameManager.vitality,
        "energy": GameManager.energy,
        "unspent_points": GameManager.unspent_points,

        # 装备数据
        "equipped_items": GameManager.equipped_items,
        "inventory": GameManager.inventory,

        # 进度数据
        "current_stage": GameManager.current_stage,
        "difficulty": GameManager.difficulty,
        "prestige_count": GameManager.prestige_count,
        "total_kills": GameManager.total_kills,
        "total_gold_earned": GameManager.total_gold_earned,
    }

# ============================================================
# 读档 — 从磁盘读取存档并恢复到 GameManager
# ============================================================
func load_game() -> bool:
    # 检查存档文件是否存在
    if not FileAccess.file_exists(SAVE_PATH):
        print("[SaveManager] 未找到存档文件，开始新游戏")
        return false

    # 打开文件进行读取
    var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
    if not file:
        push_error("[SaveManager] 无法读取存档: 错误代码 %d" % FileAccess.get_open_error())
        return false

    # 读取全部文本内容
    var text := file.get_as_text()
    file.close()

    # 解析 JSON → Dictionary
    var json := JSON.new()
    var error := json.parse(text)
    if error != OK:
        push_error("[SaveManager] 存档 JSON 解析失败: %s (行 %d)" % [
            json.get_error_message(),
            json.get_error_line()
        ])
        return false

    # 恢复游戏状态
    var data: Dictionary = json.get_data()
    _apply_save_data(data)

    EventBus.game_loaded.emit()
    print("[SaveManager] 游戏已加载 (金币: %d, 等级: %d)" % [data.gold, data.level])
    return true

# 将存档数据逐字段恢复到 GameManager
func _apply_save_data(data: Dictionary) -> void:
    # 货币
    GameManager.gold = data.get("gold", 0.0)
    GameManager.souls = data.get("souls", 0.0)
    GameManager.blood_shards = data.get("blood_shards", 0.0)

    # 角色
    GameManager.character_class = data.get("character_class", "")
    GameManager.level = data.get("level", 1)
    GameManager.experience = data.get("experience", 0.0)
    GameManager.experience_to_next = data.get("experience_to_next", 100.0)
    GameManager.strength = data.get("strength", 20)
    GameManager.dexterity = data.get("dexterity", 20)
    GameManager.vitality = data.get("vitality", 20)
    GameManager.energy = data.get("energy", 20)
    GameManager.unspent_points = data.get("unspent_points", 0)

    # 装备
    GameManager.equipped_items = data.get("equipped_items", {})
    GameManager.inventory = data.get("inventory", [])

    # 进度
    GameManager.current_stage = data.get("current_stage", 1)
    GameManager.difficulty = data.get("difficulty", "普通")
    GameManager.prestige_count = data.get("prestige_count", 0)
    GameManager.total_kills = data.get("total_kills", 0)
    GameManager.total_gold_earned = data.get("total_gold_earned", 0.0)

# ============================================================
# 离线进度计算 — 对比上次存档时间与当前时间
# ============================================================
# 流程:
#   1. 读取存档中的 timestamp
#   2. 计算 elapsed = 当前时间 - timestamp
#   3. 如果 elapsed > 30秒 → 委托 GameManager 应用离线进度
#   注意: 30 秒阈值用于过滤短暂的后台切换 (非真正离线)
func calculate_and_apply_offline_progress() -> void:
    if not FileAccess.file_exists(SAVE_PATH):
        return

    # 读取存档时间戳 (只读时间戳，不加载整个存档)
    var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
    if not file:
        return
    var text := file.get_as_text()
    file.close()

    var json := JSON.new()
    if json.parse(text) != OK:
        return

    var data: Dictionary = json.get_data()
    var last_time: float = data.get("timestamp", Time.get_unix_time_from_system())
    var elapsed := Time.get_unix_time_from_system() - last_time

    # 离线超过 30 秒才计算 (过滤后台切窗)
    if elapsed > 30.0:
        print("[SaveManager] 检测到离线 %d 秒，应用离线进度" % int(elapsed))
        GameManager.apply_offline_ticks(elapsed)
    else:
        print("[SaveManager] 离线时间过短 (%d 秒)，跳过离线进度" % int(elapsed))

# ============================================================
# 存档管理工具方法
# ============================================================
# 删除存档文件
func delete_save() -> void:
    if FileAccess.file_exists(SAVE_PATH):
        DirAccess.remove_absolute(SAVE_PATH)
        print("[SaveManager] 存档已删除")

# 检查存档是否存在
func has_save() -> bool:
    return FileAccess.file_exists(SAVE_PATH)

# 获取存档时间戳 (不加载完整存档)
func get_save_timestamp() -> float:
    if not FileAccess.file_exists(SAVE_PATH):
        return 0.0
    var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
    if not file:
        return 0.0
    var text := file.get_as_text()
    file.close()
    var json := JSON.new()
    if json.parse(text) != OK:
        return 0.0
    return json.get_data().get("timestamp", 0.0)
