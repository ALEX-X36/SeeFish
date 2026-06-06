# SeeFish 鱼类识别APP — 架构设计

## Context

SeeFish 是面向终端用户的鱼类识别APP，采用前后端分离架构，支持手机端使用。

**技术选型**：
- 前端：Flutter（跨平台 iOS/Android）
- 后端：FastAPI（Python，与 YOLO 无缝集成）
- 功能范围：MVP版本（拍照识别 + 结果显示 + 历史记录）
- SeeFish **不集成** Trainer训练器（模型由Trainer产出后部署到SeeFish）

---

## 整体架构

```
┌──────────────────────────────────────────────────────┐
│                    Flutter APP                        │
│  ┌──────────┐  ┌──────────┐  ┌──────────────────┐   │
│  │ 相机拍摄   │  │ 相册选择   │  │  识别历史列表     │   │
│  └─────┬─────┘  └─────┬─────┘  └────────┬─────────┘   │
│        │              │                 │              │
│        └──────────────┼─────────────────┘              │
│                       │ POST /api/detect               │
│                       │ (multipart image)              │
│                       ▼                                │
│  ┌──────────────────────────────────────────────┐     │
│  │       识别结果页 (标注框 + 鱼种 + 置信度)       │     │
│  └──────────────────────────────────────────────┘     │
└──────────────────────────────────────────────────────┘
                        │
                        │ HTTP REST API
                        ▼
┌──────────────────────────────────────────────────────┐
│                  FastAPI Backend                       │
│  ┌──────────────┐ ┌────────────┐ ┌───────────────┐  │
│  │ /api/detect   │ │/api/history│ │  YOLO Service  │  │
│  │  图片识别      │ │  历史CRUD   │ │  模型推理引擎   │  │
│  └──────┬───────┘ └─────┬──────┘ └───────┬───────┘  │
│         │               │                │           │
│         └───────────────┼────────────────┘           │
│                         ▼                             │
│              ┌──────────────────┐                     │
│              │   SQLite / DB    │                     │
│              └──────────────────┘                     │
└──────────────────────────────────────────────────────┘
```

---

## 项目目录结构

```
d:\CHL\PODOT\YOLO\SeeFish\
├── ARCHITECTURE.md                 # 本文件
├── backend/                        # FastAPI 后端
│   ├── main.py                     # 应用入口 + FastAPI app
│   ├── config.py                   # 配置（路径、模型名、CORS等）
│   ├── database.py                 # SQLAlchemy/SQLite 数据库设置
│   ├── requirements.txt            # Python 依赖
│   ├── models/                     # 数据模型
│   │   ├── detection.py            # Pydantic schemas（请求/响应）
│   │   └── history.py              # SQLAlchemy ORM（识别历史表）
│   ├── routers/                    # API 路由
│   │   ├── detect.py               # POST /api/detect
│   │   └── history.py              # GET/DELETE /api/history
│   ├── services/                   # 业务逻辑
│   │   ├── yolo_service.py         # YOLO 模型加载 + 推理
│   │   └── image_service.py        # 图片预处理/后处理
│   ├── model_weights/              # 训练好的模型权重（从Trainer拷贝）
│   │   └── best.pt
│   └── uploads/                    # 上传的识别图片存储
│
├── frontend/                       # Flutter 前端
│   └── seefish_app/                # Flutter 项目根目录
│       ├── pubspec.yaml            # 依赖配置
│       ├── lib/
│       │   ├── main.dart           # 入口 + MaterialApp
│       │   ├── app.dart            # 路由配置
│       │   ├── config/
│       │   │   └── api_config.dart # Backend URL 配置
│       │   ├── models/
│       │   │   ├── detection_result.dart  # 检测结果数据模型
│       │   │   └── history_record.dart    # 历史记录数据模型
│       │   ├── services/
│       │   │   ├── api_service.dart       # HTTP 请求封装
│       │   │   └── storage_service.dart   # 本地 SQLite/Hive 存储
│       │   ├── screens/
│       │   │   ├── home_screen.dart       # 主页（拍照入口 + 最近记录）
│       │   │   ├── camera_screen.dart     # 相机拍摄页
│       │   │   ├── result_screen.dart     # 识别结果详情页
│       │   │   └── history_screen.dart    # 历史记录列表页
│       │   ├── widgets/
│       │   │   ├── detection_overlay.dart # 图片上绘制标注框
│       │   │   └── result_card.dart       # 结果信息卡片
│       │   └── utils/
│       │       └── image_utils.dart       # 图片压缩/裁剪工具
│       ├── assets/
│       │   └── images/                    # 图标/启动图
│       └── test/
│
└── docker-compose.yml              # 一键部署（可选）
```

---

## 后端 API 设计

### `POST /api/detect`
识别图片中的鱼类

**请求**：`multipart/form-data`
| 参数 | 类型 | 说明 |
|------|------|------|
| image | file | 图片文件 (jpg/png) |
| conf_threshold | float | 置信度阈值（默认0.5） |

**响应**：
```json
{
  "success": true,
  "data": {
    "id": "det_abc123",
    "image_url": "/static/uploads/img_xxx.jpg",
    "detections": [
      {
        "class_id": 0,
        "class_name": "金鱼",
        "confidence": 0.923,
        "bbox": { "x1": 100, "y1": 150, "x2": 300, "y2": 400 }
      }
    ],
    "count": 2,
    "inference_time_ms": 45,
    "created_at": "2026-06-06T10:30:00Z"
  }
}
```

### `GET /api/history`
获取识别历史

**参数**：`?page=1&page_size=20`

### `GET /api/history/{id}`
获取单条历史详情

### `DELETE /api/history/{id}`
删除单条历史

---

## 数据库设计

### SQLite 表：`detection_records`

| 字段 | 类型 | 说明 |
|------|------|------|
| id | TEXT (UUID) | 主键 |
| image_path | TEXT | 保存的图片路径 |
| detections_json | TEXT | JSON格式的检测结果 |
| detection_count | INTEGER | 检测到的鱼数量 |
| inference_time_ms | INTEGER | 推理耗时 |
| created_at | DATETIME | 创建时间 |

---

## Flutter 页面流程

```
App启动
  │
  ▼
┌──────────────────┐
│   HomeScreen      │
│  ┌──────────────┐ │
│  │ 📷 拍照识别   │ │──────► CameraScreen
│  └──────────────┘ │           │ 拍照
│  ┌──────────────┐ │           ▼
│  │ 🖼️ 相册选择   │ │      确认照片
│  └──────────────┘ │           │
│  ┌──────────────┐ │           ▼
│  │ 最近识别记录   │ │      POST /api/detect
│  │ - 记录1       │ │           │
│  │ - 记录2       │◄───────────┘
│  │ - 记录3       │      ┌──────────────┐
│  │ [查看全部 →]  │──────► ResultScreen │
│  └──────────────┘      │ 图片+标注框   │
└────────────────────────│ 鱼种+置信度    │
                         │ [保存] [返回]  │
                         └──────────────┘

HistoryScreen
┌──────────────────┐
│ 🔍 搜索          │
│ - 记录1 (6/6)    │──────► ResultScreen
│ - 记录2 (6/5)    │        (查看详情)
│ - 记录3 (6/4)    │
│ [加载更多]        │
└──────────────────┘
```

---

## 关键设计决策

| 决策 | 选择 | 原因 |
|------|------|------|
| 前端框架 | Flutter | 跨平台，一套代码覆盖 iOS/Android |
| 后端框架 | FastAPI | 异步、自动API文档、与PyTorch无缝集成 |
| 数据库 | SQLite | 轻量级，无需额外数据库服务 |
| 图片存储 | 本地文件系统 | 简单直接，小规模使用无瓶颈 |
| 标注框绘制 | Flutter CustomPainter | 原生绘制，性能好，无额外依赖 |
| 本地缓存 | Hive | Flutter原生轻量KV存储，用于缓存最近记录 |
| 模型部署 | 后端加载常驻内存 | YOLO模型加载慢，常驻内存实现即时推理 |

---

## 实施顺序

### Phase 1：Backend 核心 (Steps 1-3)
| 步骤 | 内容 | 验证 |
|------|------|------|
| 1 | `backend/` 目录结构 + `requirements.txt` + 虚拟环境 | pip install 通过 |
| 2 | `config.py` + `database.py` + ORM模型 | SQLite 创建成功 |
| 3 | `yolo_service.py`（模型加载+推理） + `image_service.py` | 单张图片推理返回正确结果 |

### Phase 2：Backend API (Steps 4-5)
| 步骤 | 内容 | 验证 |
|------|------|------|
| 4 | `routers/detect.py` — POST /api/detect | Swagger UI 测试通过 |
| 5 | `routers/history.py` — GET/DELETE /api/history | CRUD API 测试通过 |

### Phase 3：Flutter 基础 (Steps 6-8)
| 步骤 | 内容 | 验证 |
|------|------|------|
| 6 | `flutter create` + 目录结构 + 依赖配置 | `flutter run` 启动 |
| 7 | 数据模型 + API Service + 本地存储 Service | 单元测试 |
| 8 | 3个核心页面 UI（Home/Camera/Result）| 页面导航流程正常 |

### Phase 4：Flutter 集成 (Steps 9-10)
| 步骤 | 内容 | 验证 |
|------|------|------|
| 9 | 拍照/选图 → 调用 API → 显示结果 | 端到端识别流程 |
| 10 | 历史记录页面 + 本地缓存 | 历史列表正确 |

### Phase 5：联调与打磨 (Steps 11-12)
| 步骤 | 内容 | 验证 |
|------|------|------|
| 11 | 前端后端联调，整体流程测试 | 全流程通过 |
| 12 | Bounding Box 绘制 + 置信度显示美化 | 视觉效果正确 |

---

## 与 Trainer 的关系

```
Trainer (训练)                    SeeFish (识别)
┌──────────────┐                 ┌──────────────┐
│ 上传数据集     │                 │ Flutter APP  │
│ 训练YOLO模型  │                 │ 拍照/选图     │
│ 导出 best.pt │─── 复制模型 ───►│ FastAPI后端  │
└──────────────┘                 │ 加载best.pt  │
                                 │ 返回识别结果  │
                                 └──────────────┘
```

Trainer 训练完成后，将 `outputs/<run>/weights/best.pt` 复制到 `SeeFish/backend/model_weights/best.pt` 即可部署。

---

## 验证方案

1. **后端验证**：`uvicorn main:app` → Swagger UI (http://127.0.0.1:8000/docs) 可测试所有API
2. **前端验证**：`flutter run` → 手机/模拟器上拍照 → 返回识别结果
3. **端到端**：用Trainer训练的鱼类模型 → SeeFish拍照 → 正确显示鱼种名称和标注框
