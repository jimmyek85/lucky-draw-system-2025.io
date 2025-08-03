# 🚀 部署指南

## GitHub Pages 自动部署

本项目已配置自动部署到 GitHub Pages。每次推送到 `main` 分支时，GitHub Actions 会自动构建和部署项目。

### 部署地址
- **主应用**: https://jimmyek85.github.io/lucky-draw-system-2025.io/
- **管理面板**: https://jimmyek85.github.io/lucky-draw-system-2025.io/admin.html
- **连接验证器**: https://jimmyek85.github.io/lucky-draw-system-2025.io/supabase-connection-validator.html

### 启用 GitHub Pages

1. 进入 GitHub 仓库设置
2. 找到 "Pages" 选项
3. 选择 "GitHub Actions" 作为源
4. 保存设置

### 部署状态

可以在仓库的 "Actions" 标签页查看部署状态和日志。

## 本地开发

```bash
# 启动本地服务器
python -m http.server 8080

# 访问地址
http://localhost:8080/index.html
```

## Supabase 配置

确保在 `supabase-config.js` 中正确配置了：
- SUPABASE_URL
- SUPABASE_ANON_KEY

## 功能验证

部署后请访问以下页面验证功能：

1. **主应用** - 测试用户注册和抽奖功能
2. **管理面板** - 验证数据管理功能
3. **连接验证器** - 检查 Supabase 连接状态

## 故障排除

如果遇到部署问题：

1. 检查 GitHub Actions 日志
2. 验证 Supabase 配置
3. 使用连接验证器测试数据库连接
4. 查看浏览器控制台错误信息

## 更新部署

要更新部署的应用：

```bash
git add .
git commit -m "更新描述"
git push origin main
```

GitHub Actions 会自动重新部署应用。