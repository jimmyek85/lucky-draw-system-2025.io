# 🎯 1602 幸运轮盘项目 - 必需文件列表

## 📋 核心运行文件 (必须保留)

### 🌐 前端页面文件
- `index.html` - 主要抽奖页面 (用户界面)
- `admin.html` - 管理员后台页面
- `system-test.html` - 系统测试页面 (可选，用于调试)

### ⚙️ 配置文件
- `supabase-config.js` - Supabase 数据库连接配置 (核心配置)

### 🗄️ 数据库设置文件
- `supabase-complete-setup.sql` - 完整数据库设置脚本 (一次性执行)

### 📚 文档文件
- `QUICK_FIX_DATABASE.md` - 数据库快速修复指南
- `PROJECT_FILES_LIST.md` - 本文件 (项目文件列表)

## 🔧 辅助工具文件 (可选保留)

### 🛠️ 连接测试工具
- `test-supabase-connection.html` - Supabase 连接测试
- `supabase-connection-validator.html` - 连接验证工具
- `reconnect-supabase.html` - 重连工具

### 📊 系统管理工具
- `full-system-test.html` - 完整系统测试
- `deploy-production.html` - 生产部署工具

### 🔍 调试和修复工具
- `fix-two-errors.html` - 错误修复工具
- `fix-connection.js` - 连接修复脚本
- `supabase-connection-fix.js` - 连接修复脚本

## 📖 文档文件 (可选保留)

### 📋 设置指南
- `SUPABASE_SQL_SETUP_GUIDE.md` - SQL 设置指南
- `PRODUCTION_DEPLOYMENT_GUIDE.md` - 生产部署指南
- `SUPABASE_CONNECTION_STATUS.md` - 连接状态文档

### 🔧 技术文档
- `AI_INTEGRATION.md` - AI 集成文档
- `enhanced-supabase-connection.js` - 增强连接脚本

### 📝 更新日志
- `LOTTERY_CONFIG_FIX_SUMMARY.md` - 配置修复总结
- `update-lottery-config.sql` - 配置更新脚本

## 🗑️ 可以删除的文件

### 🧪 实验性文件
- `enhanced-database-setup.sql` - 旧版数据库脚本 (已被 supabase-complete-setup.sql 替代)
- 任何以 `test-` 开头的临时测试文件
- 任何以 `backup-` 开头的备份文件

### 📁 Git 相关文件
- `.git/` 文件夹 (如果不需要版本控制)
- `.gitignore` (如果不使用 Git)

### 🔄 临时文件
- 任何 `.tmp` 或 `.temp` 文件
- 任何 `~` 开头的临时文件

## 🚀 最小运行配置

如果您只想保留最基本的运行文件，以下是最小配置：

```
luckydraw-wheel/
├── index.html                    # 主页面
├── admin.html                    # 管理页面
├── supabase-config.js           # 数据库配置
├── supabase-complete-setup.sql  # 数据库脚本
└── QUICK_FIX_DATABASE.md        # 设置指南
```

## 📦 推荐保留配置

为了便于维护和调试，推荐保留以下文件：

```
luckydraw-wheel/
├── index.html                           # 主页面
├── admin.html                           # 管理页面
├── system-test.html                     # 系统测试
├── supabase-config.js                   # 数据库配置
├── supabase-complete-setup.sql          # 数据库脚本
├── test-supabase-connection.html        # 连接测试
├── QUICK_FIX_DATABASE.md                # 设置指南
├── PROJECT_FILES_LIST.md                # 本文件
└── SUPABASE_SQL_SETUP_GUIDE.md          # SQL 指南
```

## 🔍 文件用途说明

### 核心功能文件
- **index.html**: 用户抽奖界面，包含轮盘动画和用户注册
- **admin.html**: 管理员界面，用于查看统计、管理用户、配置系统
- **supabase-config.js**: 包含 Supabase 项目的 URL 和 API 密钥

### 数据库文件
- **supabase-complete-setup.sql**: 一次性执行即可创建所有必需的数据库表、索引、函数和初始数据

### 测试工具
- **system-test.html**: 全面测试所有系统功能
- **test-supabase-connection.html**: 专门测试数据库连接

## ⚠️ 重要提醒

1. **不要删除 `supabase-config.js`** - 这是连接数据库的核心配置文件
2. **保留 `supabase-complete-setup.sql`** - 如果需要重新设置数据库时会用到
3. **建议保留测试文件** - 便于排查问题和验证功能
4. **备份重要配置** - 删除文件前请确保已备份重要配置信息

## 🎯 项目启动步骤

1. 确保 Supabase 项目已配置并运行了 `supabase-complete-setup.sql`
2. 检查 `supabase-config.js` 中的配置是否正确
3. 启动本地服务器: `python -m http.server 8000`
4. 访问 `http://localhost:8000/index.html` 开始使用
5. 访问 `http://localhost:8000/admin.html` 进行管理
6. 使用 `http://localhost:8000/system-test.html` 验证功能

---

📅 **最后更新**: 2024年12月30日  
🔧 **版本**: 1.0.0  
👨‍💻 **维护**: 1602 开发团队