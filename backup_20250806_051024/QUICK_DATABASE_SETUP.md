# 🚀 快速数据库设置指南

## 📋 设置步骤

### 1. 登录 Supabase 控制台
1. 访问 [https://supabase.com](https://supabase.com)
2. 使用您的邮箱 `jimmyyekhocksing@gmail.com` 登录
3. 选择您的项目：`ibirsieaeozhsvleegri`

### 2. 执行数据库初始化
1. 在 Supabase 控制台中，点击左侧菜单的 **"SQL Editor"**
2. 点击 **"New query"** 创建新查询
3. 复制 `database-setup.sql` 文件的全部内容
4. 粘贴到 SQL 编辑器中
5. 点击 **"Run"** 执行脚本

### 3. 验证数据库设置
执行完成后，您应该看到以下表格被创建：
- ✅ `users` - 用户表
- ✅ `draw_records` - 抽奖记录表
- ✅ `settings` - 系统设置表
- ✅ `knowledge` - 知识库表
- ✅ `announcements` - 公告表
- ✅ `prizes` - 奖品配置表

### 4. 检查系统状态
1. 返回到本地系统：http://localhost:8000/system-ready-check.html
2. 等待所有检查完成
3. 确认所有状态显示为绿色 ✅

## 🎯 快速测试

### 测试前端功能
访问：http://localhost:8000/index.html
- 尝试用户注册
- 测试抽奖功能
- 检查数据同步

### 测试后端管理
访问：http://localhost:8000/admin.html
- 查看用户列表
- 检查系统设置
- 验证数据查询

## 🔧 故障排除

### 如果遇到连接错误
1. 检查 Supabase 项目是否正常运行
2. 验证 API 密钥是否正确配置
3. 确认数据库表是否已创建

### 如果数据库表未创建
1. 重新执行 `database-setup.sql` 脚本
2. 检查 SQL 执行日志中的错误信息
3. 确保您有足够的权限创建表

## 📞 需要帮助？

如果遇到任何问题，请：
1. 检查浏览器控制台的错误信息
2. 查看 Supabase 控制台的日志
3. 运行系统测试页面进行诊断

---

**完成这些步骤后，您的 1602 Lucky Draw 系统就完全就绪了！** 🎉