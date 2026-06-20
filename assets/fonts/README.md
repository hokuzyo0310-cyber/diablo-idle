# 字体资源

## 目录用途
存放游戏中所有字体文件。

## 文件规格要求
- **格式**: TTF 或 OTF（TrueType/OpenType 字体格式）
- **许可**: 必须是可免费商用或有适当授权的字体
- **编码**: 需支持 CJK（中日韩）字符集（游戏有中文内容）
- **字符集**: 至少覆盖基本拉丁字符 + 简体中文常用字

## 字体需求列表

| 资源名称 | 类型 | 用途 | 风格描述 | 字号范围 | 优先级 |
|----------|------|------|----------|----------|--------|
| `ui_font.ttf` | UI 文本 | 界面文字、物品名称、属性面板 | 哥特风格衬线体，可读性优先 | 12-24pt | P0 |
| `damage_font.ttf` | 战斗数字 | 浮动伤害数字、金币弹出数字 | 粗体无衬线，略做旧/破损纹理 | 16-32pt | P1 |
| `title_font.ttf` | 标题 | 界面标题、Boss 名称、章节标题 | 华丽哥特手稿风格，装饰性优先 | 24-48pt | P1 |
| `mono_font.ttf` | 等宽数字 | 数值列对齐（金币/经验/属性数字） | 等宽字体，数字列对齐 | 12-18pt | P2 |

## 免费字体推荐

以下为可免费商用的暗黑风格字体参考：

### 哥特/暗黑风格（ui_font / title_font）
| 字体名称 | 许可 | 风格 |
|----------|------|------|
| **Diplomata** | SIL Open Font License | 哥特衬线，正式厚重 |
| **UnifrakturMaguntia** | SIL Open Font License | 德文哥特手稿风（西文） |
| **MedievalSharp** | SIL Open Font License | 中世纪手稿风格 |
| **Almendra** | SIL Open Font License | 可读性好的哥特衬线 |
| **Cinzel** | SIL Open Font License | 古典罗马铭文风格 |
| **Morris Roman** | Freeware | 古典欧式风格 |

### 战斗数字（damage_font）
| 字体名称 | 许可 | 风格 |
|----------|------|------|
| **Metamorphous** | SIL Open Font License | 粗犷哥特，数字有力 |
| **Press Start 2P** | SIL Open Font License | 像素风（如果需要复古感） |
| **Averia Gruesa Libre** | SIL Open Font License | 略破损的粗体 |

### 等宽数字（mono_font）  
| 字体名称 | 许可 | 风格 |
|----------|------|------|
| **Fira Code** | SIL Open Font License | 现代等宽，清晰易读 |
| **JetBrains Mono** | SIL Open Font License | 优秀等宽，数字辨识度高 |
| **Cousine** | SIL Open Font License | 经典等宽，通用性好 |

### 中文字体
| 字体名称 | 许可 | 风格 |
|----------|------|------|
| **思源宋体** (Source Han Serif) | SIL Open Font License | 中文宋体，与哥特风格搭配 |
| **站酷庆科黄油体** | 免费商用 | 粗犷手写风（适合标题） |
| **站酷文艺体** | 免费商用 | 文艺风格（适合UI文本） |
| **霞鹜文楷** | SIL Open Font License | 楷体，可读性好 |

> **注意**: 中文字体文件通常较大（10-40MB），注意控制最终包体大小。建议使用字体子集化工具（如 `fonttools`）仅保留游戏中实际使用的字符。

## 引擎内使用
- 将 .ttf/.otf 文件拖入此目录
- Godot 会自动导入为 `FontFile` 资源
- 创建 `FontVariation` 可设置不同字号和间距
- 在 `Theme` 资源中设置默认字体，覆盖各控件的字体属性
- 字体文件需要在中文字体后正确设置 `fallback` 链：`主字体 → 中文字体 → 等宽字体`
