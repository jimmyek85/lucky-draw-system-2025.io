# Gemini API 配置说明

## 问题解决

您遇到的 `Gemini API Error: 403` 错误是因为 API 密钥未配置。现在已经修复了这个问题！

## 如何获取和配置 Gemini API 密钥

### 1. 获取免费 API 密钥

1. 访问 [Google AI Studio](https://aistudio.google.com/app/apikey)
2. 使用您的 Google 账户登录
3. 点击 "Create API Key" 创建新的 API 密钥
4. 复制生成的 API 密钥

### 2. 配置 API 密钥

1. 打开项目根目录下的 `config.js` 文件
2. 找到这一行：
   ```javascript
   GEMINI_API_KEY: 'AIzaSyDEpz7tsqqZ6-9YBXUovTczOfrm5ny7rbk',
   ```
3. 将 `AIzaSyDEpz7tsqqZ6-9YBXUovTczOfrm5ny7rbk` 替换为您刚才获取的实际 API 密钥
4. 保存文件

### 3. 示例配置

```javascript
const API_CONFIG = {
    // 将下面的密钥替换为您的实际密钥
    GEMINI_API_KEY: 'AIzaSyDEpz7tsqqZ6-9YBXUovTczOfrm5ny7rbk',
    
    GEMINI_API_URL: 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent',
    
    ENABLE_AI_FEATURES: true
};
```

### 4. 验证配置

配置完成后：
1. 重新启动服务器
2. 访问网站并尝试使用 AI 功能
3. 如果配置正确，AI 功能将正常工作

## 功能说明

### 现在支持的功能：

✅ **智能错误处理** - 提供详细的错误信息和解决建议
✅ **离线模式支持** - 当 API 不可用时，应用仍可正常使用基本功能
✅ **多语言错误提示** - 中英文错误信息
✅ **API 密钥验证** - 自动检查密钥是否正确配置
✅ **优雅降级** - AI 功能不可用时不影响其他功能

### AI 功能包括：

- 🍺 AI 啤酒推荐师
- 📊 用户数据智能分析（管理面板）
- 🎉 个性化中奖消息

## 注意事项

- API 密钥是免费的，但有使用限制
- 请不要将 API 密钥分享给他人
- 如果遇到 429 错误，说明达到了使用限制，请稍后再试

## 故障排除

如果仍然遇到问题：

1. **403 错误** - 检查 API 密钥是否正确
2. **429 错误** - API 调用次数达到限制，请稍后再试
3. **网络错误** - 检查网络连接

配置完成后，您的幸运抽奖轮盘将拥有完整的 AI 功能！🎉