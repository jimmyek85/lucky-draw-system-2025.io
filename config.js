// API Configuration
// 请在这里设置您的 Gemini API 密钥
// 您可以从 Google AI Studio 获取免费的 API 密钥: https://aistudio.google.com/app/apikey

const API_CONFIG = {
    // 请将下面的密钥替换为您的实际 API 密钥
    // 示例: 'AIzaSyBxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx'
    GEMINI_API_KEY: 'AIzaSyDEpz7tsqqZ6-9YBXUovTczOfrm5ny7rbk',
    
    // Gemini API 端点 - 使用最新的 Gemini 2.0 Flash 模型
    GEMINI_API_URL: 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent',
    
    // 备用 API 端点（如果主端点不可用）
    GEMINI_API_URL_FALLBACK: 'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent',
    
    // 是否启用 AI 功能（如果没有 API 密钥，可以设置为 false）
    ENABLE_AI_FEATURES: true,
    
    // AI 功能配置
    AI_FEATURES: {
        // 啤酒推荐功能
        BEER_RECOMMENDATION: true,
        // 个性化中奖消息
        PERSONALIZED_MESSAGES: true,
        // 用户数据分析（管理面板）
        USER_ANALYTICS: true,
        // 创意建议
        CREATIVE_IDEAS: true
    },
    
    // API 请求配置
    REQUEST_CONFIG: {
        // 请求超时时间（毫秒）
        TIMEOUT: 10000,
        // 最大重试次数
        MAX_RETRIES: 2,
        // 重试延迟（毫秒）
        RETRY_DELAY: 1000
    }
};

// 抽奖系统配置
const LOTTERY_CONFIG = {
    // 新用户注册时的初始抽奖机会数量
    INITIAL_CHANCES: 1,
    
    // 每日免费抽奖机会（如果启用）
    DAILY_FREE_CHANCES: 0,
    
    // 是否启用每日免费机会
    ENABLE_DAILY_FREE: false,
    
    // "再来一次"奖品给予的额外机会数
    SPIN_AGAIN_BONUS: 1,
    
    // 最大累积抽奖机会数（防止无限累积）
    MAX_ACCUMULATED_CHANCES: 3,
    
    // 是否允许管理员手动添加机会
    ALLOW_ADMIN_ADD_CHANCES: true
};

// 检查 API 密钥是否已设置
function isApiKeyConfigured() {
    return API_CONFIG.GEMINI_API_KEY && 
           API_CONFIG.GEMINI_API_KEY !== 'AIzaSyDEpz7tsqqZ6-9YBXUovTczOfrm5ny7rbk' && 
           API_CONFIG.GEMINI_API_KEY.trim() !== '' &&
           API_CONFIG.GEMINI_API_KEY.startsWith('AIzaSy');
}

// 验证 API 密钥格式
function validateApiKey(apiKey) {
    if (!apiKey || typeof apiKey !== 'string') {
        return false;
    }
    
    // Google API 密钥通常以 'AIzaSy' 开头，长度约为 39 个字符
    return apiKey.startsWith('AIzaSy') && apiKey.length >= 35;
}

// 获取当前配置状态
function getConfigStatus() {
    return {
        apiKeyConfigured: isApiKeyConfigured(),
        apiKeyValid: validateApiKey(API_CONFIG.GEMINI_API_KEY),
        aiEnabled: API_CONFIG.ENABLE_AI_FEATURES,
        features: API_CONFIG.AI_FEATURES
    };
}

// 导出配置（用于模块化）
if (typeof module !== 'undefined' && module.exports) {
    module.exports = { 
        API_CONFIG,
        LOTTERY_CONFIG,
        isApiKeyConfigured, 
        validateApiKey, 
        getConfigStatus 
    };
}