/**
 * 最终配置验证脚本
 * 确保所有 Supabase 配置都正确设置，支持前后端数据连接
 */

// 配置验证结果
const verificationResults = {
    configLoaded: false,
    urlValid: false,
    keysValid: false,
    connectionTest: false,
    tablesAccessible: false,
    realtimeEnabled: false
};

/**
 * 验证配置是否加载
 */
function verifyConfigLoaded() {
    console.log('🔍 验证配置加载...');
    
    if (typeof window.SUPABASE_CONFIG === 'undefined') {
        console.error('❌ SUPABASE_CONFIG 未定义');
        return false;
    }
    
    const config = window.SUPABASE_CONFIG;
    const requiredFields = ['SUPABASE_URL', 'SUPABASE_ANON_KEY'];
    
    for (const field of requiredFields) {
        if (!config[field]) {
            console.error(`❌ 缺少必需配置: ${field}`);
            return false;
        }
    }
    
    console.log('✅ 配置加载验证通过');
    verificationResults.configLoaded = true;
    return true;
}

/**
 * 验证 URL 格式
 */
function verifyUrlFormat() {
    console.log('🔍 验证 URL 格式...');
    
    const url = window.SUPABASE_CONFIG.SUPABASE_URL;
    
    try {
        const urlObj = new URL(url);
        
        if (!urlObj.hostname.includes('supabase.co')) {
            console.error('❌ URL 不是有效的 Supabase URL');
            return false;
        }
        
        if (urlObj.protocol !== 'https:') {
            console.error('❌ URL 必须使用 HTTPS 协议');
            return false;
        }
        
        console.log('✅ URL 格式验证通过');
        verificationResults.urlValid = true;
        return true;
        
    } catch (error) {
        console.error('❌ URL 格式无效:', error.message);
        return false;
    }
}

/**
 * 验证密钥格式
 */
function verifyKeyFormats() {
    console.log('🔍 验证密钥格式...');
    
    const config = window.SUPABASE_CONFIG;
    
    // 验证 Anon Key (JWT 格式)
    if (!isValidJWT(config.SUPABASE_ANON_KEY)) {
        console.error('❌ SUPABASE_ANON_KEY 格式无效');
        return false;
    }
    
    // 验证 Service Role Key (如果存在)
    if (config.SUPABASE_SERVICE_ROLE_KEY && !isValidJWT(config.SUPABASE_SERVICE_ROLE_KEY)) {
        console.error('❌ SUPABASE_SERVICE_ROLE_KEY 格式无效');
        return false;
    }
    
    console.log('✅ 密钥格式验证通过');
    verificationResults.keysValid = true;
    return true;
}

/**
 * 检查是否为有效的 JWT
 */
function isValidJWT(token) {
    if (!token || typeof token !== 'string') {
        return false;
    }
    
    const parts = token.split('.');
    if (parts.length !== 3) {
        return false;
    }
    
    try {
        // 尝试解码 header 和 payload
        const header = JSON.parse(atob(parts[0]));
        const payload = JSON.parse(atob(parts[1]));
        
        // 检查基本 JWT 结构
        return header.alg && header.typ && payload.iss;
    } catch (error) {
        return false;
    }
}

/**
 * 测试连接
 */
async function testConnection() {
    console.log('🔍 测试 Supabase 连接...');
    
    try {
        const supabase = window.supabase.createClient(
            window.SUPABASE_CONFIG.SUPABASE_URL,
            window.SUPABASE_CONFIG.SUPABASE_ANON_KEY
        );
        
        // 测试基础连接
        const { data, error } = await supabase
            .from('users')
            .select('count', { count: 'exact', head: true });
        
        if (error && error.code !== 'PGRST116') {
            throw error;
        }
        
        console.log('✅ Supabase 连接测试通过');
        verificationResults.connectionTest = true;
        return true;
        
    } catch (error) {
        console.error('❌ Supabase 连接测试失败:', error.message);
        return false;
    }
}

/**
 * 验证表访问权限
 */
async function verifyTableAccess() {
    console.log('🔍 验证表访问权限...');
    
    try {
        const supabase = window.supabase.createClient(
            window.SUPABASE_CONFIG.SUPABASE_URL,
            window.SUPABASE_CONFIG.SUPABASE_ANON_KEY
        );
        
        const tables = ['users', 'settings', 'knowledge'];
        const results = {};
        
        for (const table of tables) {
            try {
                const { data, error } = await supabase
                    .from(table)
                    .select('*')
                    .limit(1);
                
                if (error && error.code !== 'PGRST116') {
                    results[table] = `错误: ${error.message}`;
                } else {
                    results[table] = '可访问';
                }
            } catch (error) {
                results[table] = `异常: ${error.message}`;
            }
        }
        
        console.log('📊 表访问权限结果:', results);
        
        // 如果至少有一个表可访问，则认为通过
        const accessibleTables = Object.values(results).filter(result => result === '可访问').length;
        if (accessibleTables > 0) {
            console.log('✅ 表访问权限验证通过');
            verificationResults.tablesAccessible = true;
            return true;
        } else {
            console.error('❌ 没有可访问的表');
            return false;
        }
        
    } catch (error) {
        console.error('❌ 表访问权限验证失败:', error.message);
        return false;
    }
}

/**
 * 验证实时功能
 */
async function verifyRealtimeFeatures() {
    console.log('🔍 验证实时功能...');
    
    try {
        const supabase = window.supabase.createClient(
            window.SUPABASE_CONFIG.SUPABASE_URL,
            window.SUPABASE_CONFIG.SUPABASE_ANON_KEY,
            {
                realtime: {
                    params: {
                        eventsPerSecond: 10
                    }
                }
            }
        );
        
        // 测试实时订阅
        const channel = supabase
            .channel('test-channel')
            .on('postgres_changes', 
                { event: '*', schema: 'public', table: 'users' }, 
                (payload) => {
                    console.log('📡 实时数据变化:', payload);
                }
            );
        
        await channel.subscribe();
        
        // 等待一小段时间确保订阅成功
        await new Promise(resolve => setTimeout(resolve, 1000));
        
        // 清理订阅
        await channel.unsubscribe();
        
        console.log('✅ 实时功能验证通过');
        verificationResults.realtimeEnabled = true;
        return true;
        
    } catch (error) {
        console.error('❌ 实时功能验证失败:', error.message);
        return false;
    }
}

/**
 * 运行完整验证
 */
async function runFullVerification() {
    console.log('🚀 开始完整配置验证...');
    console.log('='.repeat(50));
    
    const startTime = Date.now();
    
    // 依次运行所有验证
    const steps = [
        { name: '配置加载', func: verifyConfigLoaded },
        { name: 'URL 格式', func: verifyUrlFormat },
        { name: '密钥格式', func: verifyKeyFormats },
        { name: '连接测试', func: testConnection },
        { name: '表访问权限', func: verifyTableAccess },
        { name: '实时功能', func: verifyRealtimeFeatures }
    ];
    
    let passedSteps = 0;
    
    for (const step of steps) {
        try {
            const result = await step.func();
            if (result) {
                passedSteps++;
            }
        } catch (error) {
            console.error(`❌ ${step.name} 验证异常:`, error.message);
        }
        
        // 添加分隔线
        console.log('-'.repeat(30));
    }
    
    const endTime = Date.now();
    const duration = endTime - startTime;
    
    // 输出最终结果
    console.log('='.repeat(50));
    console.log('📊 验证结果汇总:');
    console.log(`✅ 通过: ${passedSteps}/${steps.length} 项`);
    console.log(`⏱️ 耗时: ${duration}ms`);
    console.log(`📈 成功率: ${(passedSteps / steps.length * 100).toFixed(1)}%`);
    
    if (passedSteps === steps.length) {
        console.log('🎉 所有验证通过！系统已就绪！');
        return true;
    } else if (passedSteps >= steps.length * 0.8) {
        console.log('⚠️ 大部分验证通过，系统基本可用');
        return true;
    } else {
        console.log('❌ 验证失败过多，请检查配置');
        return false;
    }
}

/**
 * 获取验证结果
 */
function getVerificationResults() {
    return {
        results: verificationResults,
        summary: {
            total: Object.keys(verificationResults).length,
            passed: Object.values(verificationResults).filter(result => result).length,
            failed: Object.values(verificationResults).filter(result => !result).length
        }
    };
}

// 导出函数供外部使用
if (typeof window !== 'undefined') {
    window.FinalConfigVerification = {
        runFullVerification,
        getVerificationResults,
        verifyConfigLoaded,
        verifyUrlFormat,
        verifyKeyFormats,
        testConnection,
        verifyTableAccess,
        verifyRealtimeFeatures
    };
}

// 如果直接运行此脚本，自动开始验证
if (typeof window !== 'undefined' && document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', () => {
        setTimeout(() => {
            if (window.SUPABASE_CONFIG && window.supabase) {
                runFullVerification();
            } else {
                console.error('❌ 缺少必要的依赖，请确保已加载 supabase-config.js 和 Supabase JS');
            }
        }, 1000);
    });
} else if (typeof window !== 'undefined' && window.SUPABASE_CONFIG && window.supabase) {
    // 如果页面已加载且依赖可用，立即运行
    setTimeout(runFullVerification, 100);
}