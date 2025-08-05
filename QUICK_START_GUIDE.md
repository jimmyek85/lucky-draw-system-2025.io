# 🚀 1602 幸运轮盘 - 快速启动指南

## 📋 项目概述
这是一个基于 Web 的幸运轮盘抽奖系统，集成了 AI 功能和完整的用户管理系统。

## 🎯 核心文件说明

### 🌟 主要页面
| 文件 | 功能 | 访问地址 |
|------|------|----------|
| `index.html` | **用户抽奖界面** | `http://localhost:8000/` |
| `admin.html` | **管理员后台** | `http://localhost:8000/admin.html` |
| `system-test.html` | **系统测试页面** | `http://localhost:8000/system-test.html` |

### ⚙️ 配置文件
| 文件 | 功能 |
|------|------|
| `config.js` | API配置（Gemini AI密钥等） |
| `supabase-config.js` | 数据库连接配置 |
| `supabase-connection.js` | 数据库连接逻辑 |
| `ai-features.js` | AI功能模块 |

### 🗄️ 数据库文件
| 文件 | 功能 |
|------|------|
| `supabase-complete-setup.sql` | **完整数据库设置脚本** |

---

## 🚀 三步启动项目

### 步骤 1: 清理项目文件（可选）
```powershell
# 在项目目录中运行清理脚本
.\cleanup-project.ps1
```

### 步骤 2: 启动本地服务器
选择以下任一方式：

#### 方式 A: Python HTTP Server
```bash
cd c:\Users\user\Desktop\luckydraw-wheel
python -m http.server 8000
```

#### 方式 B: Node.js HTTP Server
```bash
cd c:\Users\user\Desktop\luckydraw-wheel
npx http-server -p 8000
```

#### 方式 C: VS Code Live Server
1. 用 VS Code 打开项目文件夹
2. 安装 "Live Server" 扩展
3. 右键 `index.html` → "Open with Live Server"

### 步骤 3: 访问应用
- **用户界面**: http://localhost:8000/
- **管理后台**: http://localhost:8000/admin.html
- **系统测试**: http://localhost:8000/system-test.html

---

## 🔧 配置检查

### 1. 数据库配置
确认 `supabase-config.js` 中的配置：
```javascript
SUPABASE_URL: 'https://ibirsieaeozhsvleegri.supabase.co'
SUPABASE_ANON_KEY: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...'
```

### 2. AI功能配置
确认 `config.js` 中的 API 密钥：
```javascript
GEMINI_API_KEY: 'AIzaSyDEpz7tsqqZ6-9YBXUovTczOfrm5ny7rbk'
```

### 3. 数据库初始化
1. 访问 [Supabase Dashboard](https://app.supabase.com/)
2. 进入 SQL Editor
3. 执行 `supabase-complete-setup.sql` 脚本

---

## ✅ 功能验证

访问 `system-test.html` 进行全面测试：

1. **数据库连接测试** ✅
2. **用户注册测试** ✅
3. **抽奖功能测试** ✅
4. **AI功能测试** ✅
5. **系统健康检查** ✅

---

## 🎮 使用流程

### 用户端操作
1. 打开 `index.html`
2. 注册/登录账户
3. 参与幸运轮盘抽奖
4. 查看抽奖历史

### 管理员操作
1. 打开 `admin.html`
2. 管理用户数据
3. 配置抽奖设置
4. 查看系统统计

---

## 🛠️ 故障排除

### 常见问题
1. **数据库连接失败**
   - 检查 `supabase-config.js` 配置
   - 确认网络连接正常

2. **AI功能不工作**
   - 检查 `config.js` 中的 API 密钥
   - 确认 API 配额未超限

3. **页面无法加载**
   - 确认本地服务器正在运行
   - 检查端口是否被占用

### 调试工具
- 使用 `system-test.html` 进行全面诊断
- 查看浏览器开发者工具的控制台

---

## 📁 项目结构（清理后）

```
luckydraw-wheel/
├── 📄 index.html              # 主应用页面
├── 📄 admin.html              # 管理员后台
├── 📄 system-test.html        # 系统测试页面
├── ⚙️ config.js               # 应用配置
├── ⚙️ supabase-config.js      # 数据库配置
├── ⚙️ supabase-connection.js  # 数据库连接
├── ⚙️ ai-features.js          # AI功能模块
├── 🗄️ supabase-complete-setup.sql  # 数据库设置
├── 📚 README.md               # 项目说明
├── 📚 SUPABASE_SETUP.md       # 数据库指南
├── 📚 API_SETUP.md            # API指南
├── 📚 DEPLOYMENT.md           # 部署指南
├── 📚 ADMIN_FEATURES_GUIDE.md # 管理员指南
├── 📚 AI_INTEGRATION.md       # AI集成说明
├── 📚 SECURITY.md             # 安全说明
├── ⚙️ jsconfig.json           # 项目配置
├── 🎨 favicon.ico             # 网站图标
└── ⚙️ .gitignore              # Git配置
```

---

## 🎉 完成！

项目现在已经整理完毕，可以正常运行。如有问题，请查看相关文档或使用系统测试页面进行诊断。

**祝您使用愉快！** 🍀