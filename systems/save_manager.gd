# SaveManager.gd - Autoload 存档管理器
# 处理存档/读档、离线进度计算
extends Node

const SAVE_PATH := "user://save.json"

# ============================================================
# 存档
# ============================================================
func save_game() -> void:
    var data := _collect_save_data()
    var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
    if not file:
        push_error("[SaveManager] 无法写入存档: %d" % FileAccess.get_open_error())
        return

    file.store_string(JSON.stringify(data, "\t"))
    file.close()
    EventBus.game_saved.emit()
    print("[SaveManager] 游戏已保存")

func _collect_save_data() -> Dictionary:
    return {
        "version": 1,
        "timestamp": Time.get_unix_time_from_system(),

        # 货币
        "gold": GameManager.gold,
        "souls": GameManager.souls,
        "blood_shards": GameManager.blood_shards,

        # 角色
        "character_class": GameManager.character_class,
        "level": GameManager.level,
        "experience": GameManager.experience,
        "experience_to_next": GameManager.experience_to_next,
        "strength": GameManager.strength,
        "dexterity": GameManager.dexterity,
        "vitality": GameManager.vitality,
        "energy": GameManager.energy,
        "unspent_points": GameManager.unspent_points,

        # 装备
        "equipped_items": GameManager.equipped_items,
        "inventory": GameManager.inventory,

        # 进度
        "current_stage": GameManager.current_stage,
        "difficulty": GameManager.difficulty,
        "prestige_count": GameManager.prestige_count,
        "total_kills": GameManager.total_kills,
        "total_gold_earned": GameManager.total_gold_earned,
    }

# ============================================================
# 读档
# ============================================================
func load_game() -> bool:
    if not FileAccess.file_exists(SAVE_PATH):
        print("[SaveManager] 未找到存档文件，开始新游戏")
        return false

    var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
    if not file:
        push_error("[SaveManager] 无法读取存档: %d" % FileAccess.get_open_error())
        return false

    var text := file.get_as_text()
    file.close()

    var json := JSON.new()
    var error := json.parse(text)
    if error != OK:
        push_error("[SaveManager] 存档解析失败: %s" % json.get_error_message())
        return false

    var data: Dictionary = json.get_data()
    _apply_save_data(data)
    EventBus.game_loaded.emit()
    print("[SaveManager] 游戏已加载")
    return true

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
# 离线进度计算
# ============================================================
func calculate_and_apply_offline_progress() -> void:
    if not FileAccess.file_exists(SAVE_PATH):
        return

    # 读取存档中的时间戳
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

    if elapsed > 30.0:  # 超过 30 秒才算离线
        GameManager.apply_offline_ticks(elapsed)

# ============================================================
# 存档管理
# ============================================================
func delete_save() -> void:
    if FileAccess.file_exists(SAVE_PATH):
        DirAccess.remove_absolute(SAVE_PATH)
        print("[SaveManager] 存档已删除")

func has_save() -> bool:
    return FileAccess.file_exists(SAVE_PATH)

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
