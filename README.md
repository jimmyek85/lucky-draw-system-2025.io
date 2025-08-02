# 🎯 1602幸运轮盘抽奖系统

一个功能完整的Web端幸运轮盘抽奖应用，集成Supabase云数据库和AI智能功能。

## ✨ 主要功能

### 🎮 前端功能
- **幸运轮盘抽奖**：流畅的动画效果和音效
- **用户注册系统**：姓名、电话号码注册
- **实时数据同步**：与云数据库实时同步
- **多语言支持**：中文/英文界面切换
- **响应式设计**：支持桌面和移动设备
- **离线功能**：网络断开时本地存储数据

### 🛠️ 后台管理
- **用户管理**：查看、搜索、添加用户
- **数据统计**：用户参与分析和奖品统计
- **AI数据分析**：智能生成活动报告
- **实时监控**：用户活动实时更新
- **批量操作**：导出用户数据、批量管理

### 🤖 AI集成功能
- **智能推荐**：基于用户行为的个性化推荐
- **数据分析**：AI驱动的活动效果分析
- **自动化报告**：智能生成活动总结报告

## 🚀 快速开始

### 环境要求
- 现代浏览器（Chrome、Firefox、Safari、Edge）
- Python 3.x（用于本地开发服务器）
- Supabase账户（用于云数据库）
- Gemini API密钥（用于AI功能）

### 安装步骤

1. **克隆项目**
```bash
git clone https://github.com/Global1602/luckydraw2025.git
cd luckydraw2025
```

2. **配置Supabase**
   - 创建Supabase项目
   - 执行 `supabase-complete-setup.sql` 脚本
   - 更新 `supabase-config.js` 中的配置

3. **启动本地服务器**
```bash
python -m http.server 8000
```

4. **访问应用**
   - 主应用：`http://localhost:8000/index.html`
   - 管理面板：`http://localhost:8000/admin.html`

## 📁 项目结构

```
luckydraw2025/
├── index.html                    # 主应用界面
├── admin.html                    # 后台管理面板
├── config.js                     # 基础配置
├── supabase-config.js           # Supabase配置
├── ai-features.js               # AI功能模块
├── supabase-complete-setup.sql  # 数据库设置脚本
├── favicon.ico                  # 网站图标
├── .gitignore                   # Git忽略文件
│
├── 📚 文档/
│   ├── README.md
│   ├── SUPABASE_SETUP.md
│   ├── GITHUB_DEPLOYMENT_GUIDE.md
│   └── API_SETUP.md
│
├── 🛠️ 工具/
│   ├── deploy-to-github.html
│   ├── fix-data-connection.html
│   ├── test-supabase-connection.html
│   └── reconnect-supabase.html
│
└── 🧪 测试/
    ├── test-user-registration.html
    └── simple-connection-test.html
```

## ⚙️ 配置说明

### Supabase配置

1. 在 `supabase-config.js` 中设置：
```javascript
const SUPABASE_URL = 'your-supabase-url';
const SUPABASE_ANON_KEY = 'your-supabase-anon-key';
```

2. 执行数据库设置脚本：
   - 在Supabase SQL编辑器中运行 `supabase-complete-setup.sql`

### AI功能配置

在 `ai-features.js` 中设置Gemini API密钥：
```javascript
const GEMINI_API_KEY = 'your-gemini-api-key';
```

## 🌐 部署选项

### GitHub Pages
```bash
# 推送到GitHub
git add .
git commit -m "Deploy to GitHub Pages"
git push origin main

# 在GitHub仓库设置中启用Pages
```

### Netlify
1. 连接GitHub仓库
2. 设置环境变量
3. 自动部署

### Vercel
1. 导入GitHub项目
2. 配置环境变量
3. 一键部署

## 🔧 开发工具

项目包含多个开发和调试工具：

- **deploy-to-github.html**：GitHub部署助手
- **fix-data-connection.html**：数据连接修复工具
- **test-supabase-connection.html**：Supabase连接测试
- **debug-connection.html**：连接调试工具

## 📊 数据库结构

### users表
```sql
- id: UUID (主键)
- name: TEXT (用户姓名)
- phone: TEXT (电话号码)
- email: TEXT (邮箱)
- drawChances: INTEGER (抽奖次数)
- joindate: TIMESTAMP (加入时间)
- prizeswon: JSONB (获奖记录)
```

### settings表
```sql
- id: UUID (主键)
- key: TEXT (设置键)
- value: JSONB (设置值)
- updated_at: TIMESTAMP (更新时间)
```

### knowledge表
```sql
- id: UUID (主键)
- content: TEXT (知识内容)
- category: TEXT (分类)
- created_at: TIMESTAMP (创建时间)
```

## 🔒 安全特性

- **RLS策略**：行级安全保护数据
- **API密钥保护**：敏感信息环境变量化
- **CORS配置**：跨域请求安全控制
- **数据验证**：前后端双重数据验证

## 🧪 测试

运行测试工具验证功能：

1. **连接测试**：`test-supabase-connection.html`
2. **用户注册测试**：`test-user-registration.html`
3. **数据同步测试**：`simple-connection-test.html`

## 📈 性能优化

- **CDN加速**：使用Tailwind CSS和字体CDN
- **懒加载**：按需加载AI功能模块
- **缓存策略**：本地存储优化
- **数据库索引**：优化查询性能

## 🤝 贡献指南

1. Fork项目
2. 创建功能分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 打开Pull Request

## 📄 许可证

本项目采用MIT许可证 - 查看 [LICENSE](LICENSE) 文件了解详情

## 📞 支持

如有问题或建议，请：

- 创建 [Issue](https://github.com/Global1602/luckydraw2025/issues)
- 发送邮件至项目维护者
- 查看 [文档](docs/) 获取更多信息

## 🎯 路线图

- [ ] 移动端原生应用
- [ ] 更多抽奖模式
- [ ] 高级数据分析
- [ ] 多租户支持
- [ ] API接口开放

---

**⭐ 如果这个项目对您有帮助，请给我们一个星标！**
