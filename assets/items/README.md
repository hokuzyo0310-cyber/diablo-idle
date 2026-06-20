# 物品图标资源

## 目录用途
存放所有可掉落装备、武器、防具、饰品、消耗品的图标。

## 图片规格要求
- **格式**: PNG（支持透明通道）
- **尺寸**: 32×32（小图标，背包显示）或 64×64（高清变体）
- **风格**: 暗黑风格物品剪影 — 深色基底 + 金属/魔法质感
- **配色**: 基础物品保持暗色调（铁灰、暗棕），允许根据物品类型有材质区分
- **重要**: 图标不包含稀有度颜色（稀有度颜色由 UI 边框/字体控制）

## 武器 — 剑类

| 资源名称 | 描述 | 优先级 |
|----------|------|--------|
| `sword_short.png` | 短剑 — 基础单手剑 | P0 |
| `sword_long.png` | 长剑 — 中型单手剑 | P0 |
| `sword_great.png` | 巨剑 — 大型双手剑 | P1 |
| `sword_flamberge.png` | 火焰剑 — 波浪刃+火焰纹 | P2 |

## 武器 — 斧类

| 资源名称 | 描述 | 优先级 |
|----------|------|--------|
| `axe_hand.png` | 手斧 — 小型单手斧 | P0 |
| `axe_battle.png` | 战斧 — 中型双刃斧 | P1 |
| `axe_great.png` | 巨斧 — 大型双手斧 | P2 |

## 武器 — 其他

| 资源名称 | 描述 | 优先级 |
|----------|------|--------|
| `mace.png` | 钉头锤 — 单手钝器 | P1 |
| `dagger.png` | 匕首 — 小型短刃 | P1 |
| `wand.png` | 法杖 — 法师单手杖 | P1 |
| `staff.png` | 长杖 — 双手法师杖 | P1 |
| `scythe.png` | 镰刀 — 死灵双手武器 | P1 |
| `bow.png` | 弓 — 远程武器 | P2 |
| `crossbow.png` | 弩 — 远程武器 | P2 |

## 防具

| 资源名称 | 描述 | 优先级 |
|----------|------|--------|
| `helm_cloth.png` | 布帽 — 基础头部 | P0 |
| `helm_leather.png` | 皮盔 — 中型头部 | P1 |
| `helm_plate.png` | 板甲头盔 — 重型头部 | P1 |
| `armor_cloth.png` | 布甲 — 基础身体 | P0 |
| `armor_leather.png` | 皮甲 — 中型身体 | P0 |
| `armor_chain.png` | 锁子甲 — 重型身体 | P1 |
| `armor_plate.png` | 板甲 — 最重身体 | P1 |
| `gloves_leather.png` | 皮手套 | P1 |
| `gloves_plate.png` | 铁手套 | P2 |
| `boots_leather.png` | 皮靴 | P1 |
| `boots_plate.png` | 铁靴 | P2 |
| `belt_sash.png` | 腰带 — 布质 | P1 |
| `belt_plate.png` | 重腰带 — 金属 | P2 |

## 副手

| 资源名称 | 描述 | 优先级 |
|----------|------|--------|
| `shield_wood.png` | 木盾 — 基础盾牌 | P1 |
| `shield_tower.png` | 塔盾 — 重型盾牌 | P2 |
| `tome.png` | 法术书 — 法师副手 | P2 |
| `shrunken_head.png` | 萎缩头颅 — 死灵副手 | P2 |

## 饰品

| 资源名称 | 描述 | 优先级 |
|----------|------|--------|
| `ring_iron.png` | 铁戒指 | P0 |
| `ring_gold.png` | 金戒指 | P1 |
| `ring_skull.png` | 骷髅戒指 | P2 |
| `amulet_bronze.png` | 铜项链 | P0 |
| `amulet_gold.png` | 金项链 | P1 |
| `amulet_eye.png` | 邪眼项链 | P2 |

## 消耗品

| 资源名称 | 描述 | 优先级 |
|----------|------|--------|
| `potion_health.png` | 生命药水 — 红色瓶 | P0 |
| `potion_mana.png` | 法力药水 — 蓝色瓶 | P0 |
| `potion_rejuvenation.png` | 全面恢复药水 — 紫色瓶 | P1 |
| `scroll_identify.png` | 鉴定卷轴 | P2 |
| `scroll_town_portal.png` | 城镇传送卷轴 | P2 |

## 引擎内使用
- 在背包 UI 中用 `TextureRect` 显示物品图标
- 装备槽中显示当前装备的物品图标
- 工具提示（Tooltip）中放大显示 64×64 版本
