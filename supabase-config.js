// Supabase Configuration
// 请在这里设置您的 Supabase 项目配置
// 您可以从 Supabase Dashboard 获取这些信息: https://app.supabase.com/

const SUPABASE_CONFIG = {
    // Supabase 项目 URL
    SUPABASE_URL: 'https://ibirsieaeozhsvleegri.supabase.co',
    
    // Supabase anon 公钥
    SUPABASE_ANON_KEY: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImliaXJzaWVhZW96aHN2bGVlZ3JpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTM4OTQ5MzIsImV4cCI6MjA2OTQ3MDkzMn0.MYzEhk1XYS9d4n-ToLZIb4AsUjzoiOndNeIqdDdY0SM',
    
    // 数据库表名配置
    TABLES: {
        USERS: 'users',
        SETTINGS: 'settings', 
        KNOWLEDGE: 'knowledge'
    },
    
    // 实时订阅配置
    REALTIME_CONFIG: {
        // 是否启用实时更新
        ENABLED: true,
        // 重连间隔（毫秒）
        RECONNECT_INTERVAL: 3000,
        // 最大重连次数
        MAX_RECONNECT_ATTEMPTS: 5
    }
};

// 检查 Supabase 配置是否已设置
function isSupabaseConfigured() {
    return SUPABASE_CONFIG.SUPABASE_URL && 
           SUPABASE_CONFIG.SUPABASE_URL !== 'https://your-project-id.supabase.co' && 
           SUPABASE_CONFIG.SUPABASE_ANON_KEY && 
           SUPABASE_CONFIG.SUPABASE_ANON_KEY !== 'your-supabase-anon-key-here' &&
           SUPABASE_CONFIG.SUPABASE_URL.includes('.supabase.co') &&
           SUPABASE_CONFIG.SUPABASE_ANON_KEY.startsWith('eyJ');
}

// 验证 Supabase URL 格式
function validateSupabaseUrl(url) {
    if (!url || typeof url !== 'string') {
        return false;
    }
    
    // Supabase URL 格式验证
    return url.startsWith('https://') && url.includes('.supabase.co');
}

// 获取当前配置状态
function getSupabaseConfigStatus() {
    return {
        configured: isSupabaseConfigured(),
        urlValid: validateSupabaseUrl(SUPABASE_CONFIG.SUPABASE_URL),
        realtimeEnabled: SUPABASE_CONFIG.REALTIME_CONFIG.ENABLED,
        tables: SUPABASE_CONFIG.TABLES
    };
}

// 将配置挂载到 window 对象（用于浏览器环境）
if (typeof window !== 'undefined') {
    window.SUPABASE_CONFIG = SUPABASE_CONFIG;
    window.isSupabaseConfigured = isSupabaseConfigured;
    window.validateSupabaseUrl = validateSupabaseUrl;
    window.getSupabaseConfigStatus = getSupabaseConfigStatus;
}

// 导出配置（用于模块化）
if (typeof module !== 'undefined' && module.exports) {
    module.exports = { 
        SUPABASE_CONFIG, 
        isSupabaseConfigured, 
        validateSupabaseUrl, 
        getSupabaseConfigStatus 
    };
}