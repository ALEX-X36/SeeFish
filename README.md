# 🐟 SeeFish — 鱼类识别APP

基于深度学习的实时鱼类识别移动应用。拍照或选择图片，即可识别鱼种并显示标注框。采用 Flutter 前端 + FastAPI 后端架构，YOLO 模型由 [Trainer](https://github.com/ALEX-X36/YOLO-Trainer) 项目训练产出。

---

## ✨ 功能特性

| 模块 | 功能 |
|------|------|
| 📷 **拍照识别** | 调用手机相机拍摄鱼类照片，实时上传并返回识别结果 |
| 🖼️ **相册选择** | 从手机相册选择已有照片进行识别 |
| 🎯 **目标检测** | YOLOv8/YOLOv11 模型推理，精准定位图中每一条鱼，绘制标注框 |
| 📊 **结果展示** | 标注框叠加显示 + 鱼种名称 + 置信度百分比 + 坐标信息 |
| 📝 **历史记录** | 分页浏览历史识别记录，支持滑动删除、下拉刷新、无限滚动 |
| 🔄 **双模式** | 训练模型模式（生产）+ 模拟数据模式（开发调试），无缝切换 |
| 🌓 **深色模式** | 跟随系统自动切换 Material 3 亮色/暗色主题 |

---

## 🏗️ 系统架构

```
┌─────────────────────────────────────────────────────────────┐
│                     Flutter APP (前端)                       │
│                                                              │
│  ┌───────────┐  ┌───────────┐  ┌────────────────────────┐  │
│  │ 📷 相机    │  │ 🖼️ 相册   │  │  📝 历史记录            │  │
│  │ CameraScreen│  │ CameraScreen│  │  HistoryScreen        │  │
│  └─────┬─────┘  └─────┬─────┘  └──────────┬─────────────┘  │
│        │              │                   │                  │
│        └──────────────┼───────────────────┘                  │
│                       │ POST /api/detect                     │
│                       │ (multipart/form-data)                 │
│                       ▼                                       │
│  ┌─────────────────────────────────────────────────────┐    │
│  │              ResultScreen 识别结果页                   │    │
│  │   图片 + 标注框 (DetectionOverlay / CustomPainter)     │    │
│  │   鱼种名称 + 置信度百分比 (ResultCard)                  │    │
│  └─────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────┘
                         │
                         │ HTTP REST (JSON)
                         ▼
┌─────────────────────────────────────────────────────────────┐
│                    FastAPI Backend (后端)                     │
│                                                              │
│  ┌─────────────────┐  ┌────────────────┐  ┌──────────────┐ │
│  │ POST /api/detect │  │ GET|DELETE     │  │ GET /api/    │ │
│  │ 图片识别          │  │ /api/history   │  │ health       │ │
│  └────────┬────────┘  └───────┬────────┘  └──────────────┘ │
│           │                   │                              │
│           ▼                   ▼                              │
│  ┌────────────────┐  ┌──────────────────────┐               │
│  │  YOLO Service   │  │  SQLite (异步 ORM)   │               │
│  │  模型加载+推理   │  │  detection_records   │               │
│  └───────┬────────┘  └──────────────────────┘               │
│          │                                                   │
│          ▼                                                   │
│  ┌────────────────┐                                          │
│  │  model_weights/ │  ← 从 Trainer 项目复制训练好的模型       │
│  │  best.pt       │                                          │
│  └────────────────┘                                          │
└─────────────────────────────────────────────────────────────┘
```

**关键设计决策：**

| 决策 | 选择 | 原因 |
|------|------|------|
| 前端框架 | Flutter | 一套代码覆盖 iOS + Android |
| 后端框架 | FastAPI | 异步高性能、自动 Swagger 文档、与 PyTorch/Ultralytics 无缝集成 |
| 数据库 | SQLite (aiosqlite) | 轻量零配置，小规模部署无需独立数据库服务 |
| 图片存储 | 本地文件系统 + StaticFiles 挂载 | 简单直接，无外部依赖 |
| ORM | SQLAlchemy 2.0 async | 类型安全、异步原生支持 |
| 标注框绘制 | Flutter CustomPainter | 原生渲染性能，60fps 流畅缩放 |
| 本地缓存 | 内存缓存 (可扩展为 Hive) | 快速访问最近记录 |
| 模型加载 | 启动时加载，常驻内存 | 避免每次请求重新加载模型（加载耗时长） |
| 开发模式 | Mock 模式自动切換 | 模型文件不存在时自动使用模拟数据，方便前端独立开发 |

---

## 📁 项目结构

```
SeeFish/
├── README.md                          # 本文件
├── ARCHITECTURE.md                    # 详细架构设计文档
│
├── backend/                           # FastAPI 后端 (Python)
│   ├── main.py                        # 应用入口 — FastAPI app + lifespan + 路由挂载
│   ├── config.py                      # 全局配置 — 路径、模型、CORS、限制
│   ├── database.py                    # SQLAlchemy async 引擎 + session + get_db 依赖
│   ├── models/                        # 数据模型
│   │   ├── __init__.py
│   │   ├── detection.py               # Pydantic v2 请求/响应 Schema
│   │   └── history.py                 # SQLAlchemy ORM — detection_records 表
│   ├── routers/                       # API 路由
│   │   ├── __init__.py
│   │   ├── detect.py                  # POST /api/detect — 图片识别
│   │   └── history.py                 # GET/DELETE /api/history — 历史记录 CRUD
│   ├── services/                      # 业务逻辑
│   │   ├── __init__.py
│   │   ├── yolo_service.py            # YOLO 模型加载 (单例) + 推理 + Mock 模式
│   │   └── image_service.py           # 图片验证、保存、删除、尺寸读取
│   ├── model_weights/                 # 训练好的模型权重目录
│   │   └── best.pt                    # ← 从 Trainer 项目复制至此
│   └── uploads/                       # 用户上传的识别图片 (UUID 命名)
│
└── frontend/                          # Flutter 前端 (Dart)
    └── seefish_app/
        ├── pubspec.yaml               # 依赖配置 (camera, dio, hive, image_picker...)
        ├── analysis_options.yaml      # Lint 规则
        ├── lib/
        │   ├── main.dart              # App 入口 — runApp
        │   ├── app.dart               # MaterialApp — Material 3 主题 + 路由
        │   ├── config/
        │   │   └── api_config.dart    # 后端 URL + 超时 + 置信度默认值
        │   ├── models/
        │   │   ├── detection_result.dart  # Detection / BBox / DetectionResult 数据类
        │   │   └── history_record.dart    # HistoryRecord / HistoryListData 数据类
        │   ├── services/
        │   │   ├── api_service.dart       # Dio HTTP 客户端 (单例) — 所有 API 调用
        │   │   └── storage_service.dart   # 内存缓存 (最多 50 条) — 可扩展为 Hive
        │   ├── screens/
        │   │   ├── home_screen.dart       # 主页 — 拍照/相册入口 + 后端状态 + 最近记录
        │   │   ├── camera_screen.dart     # 拍照/选图 — 预览 + 确认 → 调用 API
        │   │   ├── result_screen.dart     # 结果页 — InteractiveViewer + 标注框 + 检测列表
        │   │   └── history_screen.dart    # 历史页 — 分页滚动 + 下拉刷新 + 滑动删除
        │   ├── widgets/
        │   │   ├── detection_overlay.dart # CustomPainter — 按 class_id 着色绘制 bbox
        │   │   └── result_card.dart       # 结果卡片 — 排名徽章 + 鱼名 + 置信度
        │   └── utils/
        │       └── image_utils.dart       # 图片压缩 (max 1024px) + 尺寸解码
        ├── assets/images/                 # 静态资源 (图标、启动图)
        └── test/                          # 单元测试
```

---

## 🚀 快速开始

### 环境要求

| 组件 | 要求 |
|------|------|
| **Python** | >= 3.10 |
| **Flutter** | SDK >= 3.2.0 |
| **CUDA (推荐)** | >= 11.8 (GPU 推理加速) |
| **操作系统** | Windows / macOS / Linux (后端)；iOS / Android (前端) |

### 1. 后端安装与启动

```bash
# 进入后端目录
cd SeeFish/backend

# 创建虚拟环境
python -m venv venv

# 激活虚拟环境
# Windows:
venv\Scripts\activate
# macOS / Linux:
source venv/bin/activate

# 安装依赖
pip install fastapi uvicorn ultralytics sqlalchemy aiosqlite pydantic pillow python-multipart

# 部署模型（从 Trainer 项目复制训练好的权重）
# 将 Trainer/outputs/<run_name>/weights/best.pt 复制到 model_weights/best.pt
# 如果跳过此步骤，后端将自动进入 Mock 模式（返回模拟识别结果）

# 启动后端
python main.py
# 或:
uvicorn main:app --host 0.0.0.0 --port 8000 --reload
```

启动后可访问：
- **API 文档 (Swagger)**：`http://127.0.0.1:8000/docs`
- **健康检查**：`http://127.0.0.1:8000/api/health`

### 2. 前端安装与启动

```bash
# 进入 Flutter 项目目录
cd SeeFish/frontend/seefish_app

# 安装依赖
flutter pub get

# 配置后端地址
# 编辑 lib/config/api_config.dart，修改 baseUrl：
#   - Android 模拟器: http://10.0.2.2:8000 (默认)
#   - iOS 模拟器:     http://127.0.0.1:8000
#   - 真机:           http://<电脑IP>:8000

# 启动 App
flutter run
```

### 3. 验证安装

```bash
# 后端 API 测试 (使用 curl)
curl -X POST http://127.0.0.1:8000/api/detect \
  -F "image=@test_fish.jpg" \
  -F "conf_threshold=0.5"

# 查看历史记录
curl http://127.0.0.1:8000/api/history?page=1&page_size=10
```

---

## 📖 使用指南

### 工作流程

```
┌───────────┐    ┌───────────┐    ┌───────────┐    ┌───────────┐
│  打开App   │ → │ 拍照/选图  │ → │ 上传识别   │ → │ 查看结果   │
│  HomeScreen│   │CameraScreen│   │  POST API  │   │ResultScreen│
└───────────┘    └───────────┘    └───────────┘    └───────────┘
                                                         │
                                                    ┌────▼────┐
                                                    │ 保存历史  │
                                                    │ 本地缓存  │
                                                    └─────────┘
```

### 页面说明

#### 🏠 主页 (HomeScreen)

- **渐变标题**：App 名称 "SeeFish — 鱼类识别"
- **两个操作入口**：
  - 📷 **拍照识别** → 打开相机拍摄
  - 🖼️ **相册选择** → 从相册选取图片
- **后端状态指示器**：显示后端连接状态（🟢 在线 / 🔴 离线），自动检测
- **最近识别记录**：显示最近 5 条历史记录的缩略信息，点击跳转到详情
- **"查看全部 →"** 链接：进入完整历史记录列表

#### 📸 拍照/选图 (CameraScreen)

- 根据入口自动切换**相机模式**或**相册模式**
- 拍摄/选择后进入**预览界面**，可重新拍摄/选择
- 图片自动压缩（最大 1024px，JPEG 质量 85%）以减少上传流量
- 点击 **"开始识别"** 按钮，调用 `POST /api/detect` 上传图片
- 加载状态显示，网络错误时提示重试

#### 🎯 识别结果 (ResultScreen)

- **大图展示**：支持双指缩放 (`InteractiveViewer`)
- **标注框叠加** (`DetectionOverlay`)：
  - 按鱼种类别分配不同颜色（8 色调色板循环）
  - 框内标签显示：鱼种名称 + 置信度百分比
- **检测列表** (`ResultCard`)：
  - 排名徽章（数字圆圈）
  - 鱼种名称
  - 边界框坐标 (x1, y1, x2, y2)
  - 置信度颜色标记：🟢 ≥90% / 🟠 ≥70% / 🔴 <70%
- 返回按钮 → 退回主页

#### 📝 历史记录 (HistoryScreen)

- **分页列表**：每页 20 条，自动检测滚动到底部加载更多（无限滚动）
- **下拉刷新**：重新加载第一页
- **滑动删除**：左滑 → 确认弹窗 → `DELETE /api/history/{id}`（同时删除图片文件）
- **点击记录**：跳转到 ResultScreen 查看完整结果
- **离线缓存**：服务器不可达时自动回退到内存缓存数据
- **相对时间格式**：显示 "5 分钟前"、"2 小时前"、"3 天前" 等

---

## 🔧 后端配置详解

所有配置项在 [backend/config.py](backend/config.py) 中集中管理：

| 配置项 | 默认值 | 说明 |
|--------|--------|------|
| `DEFAULT_MODEL_PATH` | `model_weights/best.pt` | YOLO 模型权重路径 |
| `DEFAULT_CONF_THRESHOLD` | `0.5` | 默认置信度阈值 |
| `DEFAULT_IOU_THRESHOLD` | `0.45` | NMS IoU 阈值 |
| `HOST` | `0.0.0.0` | 后端监听地址 |
| `PORT` | `8000` | 后端监听端口 |
| `CORS_ORIGINS` | `["*"]` | 允许的跨域来源 |
| `MAX_IMAGE_SIZE_MB` | `10` | 上传图片最大体积 |
| `ALLOWED_IMAGE_TYPES` | JPEG/PNG/WebP | 支持的图片格式 |
| `HISTORY_PAGE_SIZE` | `20` | 历史记录每页条数 |
| `MAX_HISTORY_RECORDS` | `1000` | 历史记录最大保留数（软限制） |
| `DATABASE_URL` | `sqlite+aiosqlite:///seefish.db` | 数据库连接 |

---

## 🎭 Mock 模式 — 无模型开发

当 `model_weights/best.pt` 不存在或加载失败时，后端**自动进入 Mock 模式**：

- **行为**：返回随机生成的模拟识别结果
- **鱼类名称**：从 8 种常见观赏鱼中随机选取（锦鲤、金鱼、龙鱼、热带鱼、鲷鱼、鲈鱼、石斑鱼、蝴蝶鱼）
- **检测数量**：随机 0~3 条
- **置信度**：随机 65%~98%
- **推理时间**：随机 20~80ms

**适用场景：**
- ✅ 前端独立开发，无需模型文件
- ✅ API 联调测试
- ✅ Demo 演示

**切换到生产模式：** 将训练好的 `best.pt` 放入 `model_weights/` 目录，重启后端即可。

```bash
# 从 Trainer 复制模型
cp ../Trainer/outputs/<run_name>/weights/best.pt backend/model_weights/best.pt

# 重启后端
python main.py
```

模型信息可通过 `/api/health` 查看，`model.mode` 字段值为 `"live"`（生产）或 `"mock"`（模拟）。

---

## 📡 API 参考

| 方法 | 路径 | 说明 |
|------|------|------|
| `POST` | `/api/detect` | 上传图片进行鱼类检测 |
| `GET` | `/api/history` | 分页获取识别历史列表 |
| `GET` | `/api/history/{id}` | 获取单条历史详情 |
| `DELETE` | `/api/history/{id}` | 删除历史记录及图片 |
| `GET` | `/api/health` | 健康检查 + 模型状态 |

### POST /api/detect

**请求** — `multipart/form-data`

| 字段 | 类型 | 必填 | 默认值 | 说明 |
|------|------|------|--------|------|
| `image` | file | ✅ | — | 图片文件 (JPEG/PNG/WebP, ≤10MB) |
| `conf_threshold` | float | ❌ | `0.5` | 置信度阈值 (0.0–1.0) |

**响应** — `application/json`

```json
{
  "success": true,
  "data": {
    "id": "b8a24c4e7eba4e1895b0a240f768c391",
    "image_url": "/static/uploads/b8a24c4e7eba4e1895b0a240f768c391.jpg",
    "detections": [
      {
        "class_id": 0,
        "class_name": "锦鲤",
        "confidence": 0.923,
        "bbox": {"x1": 120, "y1": 85, "x2": 340, "y2": 410}
      }
    ],
    "count": 1,
    "inference_time_ms": 45,
    "created_at": "2026-06-06T10:30:00Z"
  }
}
```

### GET /api/history

**查询参数**

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `page` | int | `1` | 页码（从 1 开始） |
| `page_size` | int | `20` | 每页条数（1–100） |

**响应**

```json
{
  "success": true,
  "data": {
    "items": [
      {
        "id": "b8a24c4e...",
        "image_url": "/static/uploads/b8a24c4e....jpg",
        "detections": [...],
        "detection_count": 1,
        "inference_time_ms": 45,
        "created_at": "2026-06-06T10:30:00Z"
      }
    ],
    "total": 42,
    "page": 1,
    "page_size": 20,
    "total_pages": 3
  }
}
```

---

## 🔗 与 Trainer 项目的关系

```
┌──────────────────────────┐       ┌──────────────────────────┐
│     Trainer (训练系统)     │       │     SeeFish (识别系统)     │
│                          │       │                          │
│  1. 上传鱼类数据集         │       │  Flutter App              │
│  2. 配置超参数            │       │  ├─ 拍照 / 相册选择        │
│  3. 选择 YOLO 模型        │       │  ├─ 上传图片到后端          │
│  4. 训练模型              │       │  └─ 显示识别结果            │
│  5. 导出 best.pt ────────┼───→  │                          │
│                          │  复制  │  FastAPI Backend          │
│                          │  模型  │  ├─ 加载 best.pt           │
│                          │       │  ├─ POST /api/detect       │
│                          │       │  └─ 返回检测结果            │
└──────────────────────────┘       └──────────────────────────┘
```

**部署流程：**

```bash
# 1. 在 Trainer 中训练模型
cd Trainer
python app.py
# → 训练完成后得到 outputs/<run_name>/weights/best.pt

# 2. 复制模型到 SeeFish
cp Trainer/outputs/<run_name>/weights/best.pt SeeFish/backend/model_weights/best.pt

# 3. 启动 SeeFish 后端
cd SeeFish/backend
python main.py
# → /api/health 显示 "mode": "live" 即部署成功
```

---

## 🗄️ 数据库设计

单表 `detection_records`（SQLite）：

```sql
CREATE TABLE detection_records (
    id                TEXT PRIMARY KEY,        -- UUID
    image_path        TEXT NOT NULL,           -- 图片文件路径
    detections_json   TEXT NOT NULL DEFAULT '[]', -- JSON 格式检测结果
    detection_count   INTEGER DEFAULT 0,       -- 检测到的目标数
    inference_time_ms INTEGER DEFAULT 0,       -- 推理耗时 (毫秒)
    created_at        DATETIME                 -- 创建时间 (UTC)
);
```

`detections_json` 字段存储格式：

```json
[
  {
    "class_id": 0,
    "class_name": "锦鲤",
    "confidence": 0.923,
    "bbox": {"x1": 120, "y1": 85, "x2": 340, "y2": 410}
  }
]
```

> 选择 JSON 文本而非规范化表，原因是 MVP 阶段检测结果结构简单、查询需求少（仅按时间排序），JSON 字段避免了额外的表关联开销。

---

## 🏗️ 后端架构细节

### 应用生命周期 (Lifespan)

```python
# Startup:
1. await init_db()          # 创建 SQLite 表 (如不存在)
2. load_model()             # 加载 YOLO 模型到内存 → 全局单例
   ├─ best.pt 存在 → "live" 模式
   └─ best.pt 不存在 → "mock" 模式 (开发用)
3. 挂载 StaticFiles         # uploads/ 目录可通过 /static/uploads/ 访问

# Shutdown:
1. 日志记录，无特殊清理（SQLAlchemy 连接池自动释放）
```

### 依赖注入链

```
HTTP Request
  │
  ▼
FastAPI Router (detect.py / history.py)
  │
  ├─→ Depends(get_db)        → AsyncSession (自动事务管理)
  └─→ validate_image()       → image_service (文件类型/大小校验)
  └─→ save_upload()           → image_service (UUID 命名存储)
  └─→ yolo_detect()           → yolo_service (YOLO 推理)
  └─→ DetectionRecord(...)    → history ORM (写入 SQLite)
```

### 模型服务 (YOLO Service)

- **单例模式**：模块级 `_model` 全局变量，启动时加载一次
- **线程安全**：FastAPI async 事件循环 + Ultralytics CPU/GPU 推理（单线程串行请求）
- **模型信息提取**：自动从模型 `names` 属性读取类别名称，通过 `/api/health` 暴露
- **错误隔离**：推理异常不导致请求崩溃，返回空检测结果并记录日志

---

## 📱 前端架构细节

### 路由表

| 路由 | 页面 | 参数 | 说明 |
|------|------|------|------|
| `/` | `HomeScreen` | — | 主页，拍照/相册入口 |
| `/camera` | `CameraScreen` | `CameraMode` (camera/gallery) | 拍照或选图 |
| `/result` | `ResultScreen` | — | 识别结果（通过状态管理传递数据） |
| `/history` | `HistoryScreen` | — | 历史记录列表 |

### 服务层

**ApiService (Dio 单例)：**
- `healthCheck()` → `GET /api/health`
- `detectFish(imagePath, confThreshold)` → `POST /api/detect` (multipart)
- `getHistory(page, pageSize)` → `GET /api/history`
- `getHistoryDetail(id)` → `GET /api/history/{id}`
- `deleteHistory(id)` → `DELETE /api/history/{id}`
- `updateBaseUrl(url)` → 动态切换后端地址

**StorageService (内存缓存，可扩展为 Hive)：**
- 最多缓存 50 条最近记录
- `cacheRecords()` / `getCachedRecords()` / `addRecord()` / `removeRecord()` / `clearCache()`

### 标注框绘制算法

`DetectionOverlay` (CustomPainter) 的关键逻辑：

1. 获取图片实际尺寸 (imageWidth × imageHeight) 和显示区域尺寸 (displayWidth × displayHeight)
2. 计算缩放比例：`scale = min(displayWidth/imageWidth, displayHeight/imageHeight)`
3. 计算图片在显示区域中的偏移 (letterbox/pillarbox)
4. 将每个 bbox 的像素坐标映射到屏幕坐标：
   ```
   screenX = offsetX + bbox.x1 * scale
   screenY = offsetY + bbox.y1 * scale
   screenW = (bbox.x2 - bbox.x1) * scale
   screenH = (bbox.y2 - bbox.y1) * scale
   ```
5. 按 class_id 循环使用 8 色调色板着色矩形框和文字背景

---

## 🔒 安全注意事项

> ⚠️ 当前版本为 MVP，以下安全措施在生产环境部署前建议实施：

| 风险 | 当前状态 | 建议改进 |
|------|----------|----------|
| CORS | 允许所有来源 (`*`) | 限制为特定的前端域名/IP |
| 文件上传 | 仅校验 Content-Type 和大小 | 增加文件内容魔法字节校验 |
| 认证 | 无认证机制 | 添加 API Key 或 JWT 认证 |
| 请求限流 | 无限流 | 添加 `slowapi` 或 nginx rate limit |
| 历史记录 | 无上限硬性约束 | 实现定期清理旧记录的后台任务 |

---

## ❓ 常见问题

### Q: 后端启动后 `/api/health` 显示 `"mode": "mock"`

**原因**：`model_weights/best.pt` 文件不存在或加载失败。

**解决**：
```bash
# 检查模型文件
ls backend/model_weights/

# 从 Trainer 项目复制训练好的模型
cp ../Trainer/outputs/<run_name>/weights/best.pt backend/model_weights/best.pt

# 重启后端
python main.py
```

### Q: Flutter App 无法连接后端

**排查步骤：**
1. 确认后端已启动：访问 `http://<后端IP>:8000/api/health`
2. 检查 `lib/config/api_config.dart` 中的 `baseUrl`
   - Android 模拟器用 `http://10.0.2.2:8000`
   - iOS 模拟器用 `http://127.0.0.1:8000`
   - 真机用电脑局域网 IP（如 `http://192.168.1.100:8000`）
3. 确认手机和电脑在同一网络（真机场景）
4. 确认防火墙未阻止 8000 端口

### Q: 识别速度慢

**优化建议：**
- 使用 GPU：确保后端安装了 `torch` CUDA 版本
- 选择更小的模型变体：如 YOLOv8n (6MB) 替代 YOLOv8x (130MB)
- 在 `config.py` 调低 `DEFAULT_IOU_THRESHOLD`
- 前端已内置图片压缩（1024px max），减少上传和推理时间

### Q: 如何添加新的鱼种类别？

1. 在 Trainer 中准备包含新类别的数据集（更新 `data.yaml` 的 `names` 和 `nc`）
2. 重新训练模型得到新的 `best.pt`
3. 复制到 SeeFish `model_weights/best.pt`
4. 重启后端 → 模型自动读取新的类别名称

### Q: 如何重置历史记录？

```bash
# 删除数据库文件（重启后端会自动重建空表）
rm backend/seefish.db

# 同时清空上传的图片
rm backend/uploads/*
```

### Q: iOS 真机运行时相机权限问题

在 `ios/Runner/Info.plist` 中添加：
```xml
<key>NSCameraUsageDescription</key>
<string>SeeFish 需要使用相机来拍摄鱼类照片进行识别</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>SeeFish 需要访问相册来选择鱼类照片</string>
```

---

## 🔗 相关链接

- [Trainer 项目](../Trainer/) — 训练 YOLO 模型
- [Ultralytics YOLO 文档](https://docs.ultralytics.com/)
- [FastAPI 文档](https://fastapi.tiangolo.com/)
- [Flutter 文档](https://flutter.dev/docs)
- [Gradio 文档](https://www.gradio.app/docs)

---

## 📄 许可

本项目基于 [Ultralytics AGPL-3.0 License](https://github.com/ultralytics/ultralytics/blob/main/LICENSE) 开发。
