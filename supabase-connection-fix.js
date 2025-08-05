// Supabase 连接诊断和修复工具
// 专门解决 net::ERR_ABORTED 错误

class SupabaseConnectionFix {
    constructor() {
        this.diagnostics = [];
        this.fixes = [];
        this.retryCount = 0;
        this.maxRetries = 3;
    }

    // 诊断连接问题
    async diagnoseConnection() {
        console.log('🔍 开始诊断 Supabase 连接问题...');
        this.diagnostics = [];

        // 1. 检查配置
        await this.checkConfiguration();
        
        // 2. 检查网络连接
        await this.checkNetworkConnectivity();
        
        // 3. 检查 Supabase 服务状态
        await this.checkSupabaseService();
        
        // 4. 检查 CORS 设置
        await this.checkCorsSettings();
        
        // 5. 检查客户端配置
        await this.checkClientConfiguration();

        return this.diagnostics;
    }

    // 检查配置
    async checkConfiguration() {
        const config = window.SUPABASE_CONFIG;
        
        if (!config) {
            this.diagnostics.push({
                type: 'error',
                category: 'configuration',
                message: 'Supabase 配置未找到'
            });
            return;
        }

        if (!config.SUPABASE_URL || !config.SUPABASE_ANON_KEY) {
            this.diagnostics.push({
                type: 'error',
                category: 'configuration',
                message: 'Supabase URL 或 API Key 未配置'
            });
            return;
        }

        this.diagnostics.push({
            type: 'success',
            category: 'configuration',
            message: 'Supabase 配置检查通过'
        });
    }

    // 检查网络连接
    async checkNetworkConnectivity() {
        try {
            const response = await fetch('https://www.google.com/favicon.ico', {
                method: 'HEAD',
                mode: 'no-cors'
            });
            
            this.diagnostics.push({
                type: 'success',
                category: 'network',
                message: '网络连接正常'
            });
        } catch (error) {
            this.diagnostics.push({
                type: 'error',
                category: 'network',
                message: '网络连接异常: ' + error.message
            });
        }
    }

    // 检查 Supabase 服务状态
    async checkSupabaseService() {
        const config = window.SUPABASE_CONFIG;
        if (!config) return;

        try {
            // 尝试访问 Supabase 健康检查端点
            const healthUrl = `${config.SUPABASE_URL}/rest/v1/`;
            const response = await fetch(healthUrl, {
                method: 'HEAD',
                headers: {
                    'apikey': config.SUPABASE_ANON_KEY,
                    'Authorization': `Bearer ${config.SUPABASE_ANON_KEY}`
                }
            });

            if (response.ok) {
                this.diagnostics.push({
                    type: 'success',
                    category: 'service',
                    message: 'Supabase 服务可访问'
                });
            } else {
                this.diagnostics.push({
                    type: 'warning',
                    category: 'service',
                    message: `Supabase 服务响应异常: ${response.status}`
                });
            }
        } catch (error) {
            this.diagnostics.push({
                type: 'error',
                category: 'service',
                message: 'Supabase 服务不可访问: ' + error.message
            });
        }
    }

    // 检查 CORS 设置
    async checkCorsSettings() {
        const config = window.SUPABASE_CONFIG;
        if (!config) return;

        try {
            // 尝试简单的 CORS 请求
            const response = await fetch(`${config.SUPABASE_URL}/rest/v1/users?select=count`, {
                method: 'GET',
                headers: {
                    'apikey': config.SUPABASE_ANON_KEY,
                    'Authorization': `Bearer ${config.SUPABASE_ANON_KEY}`,
                    'Content-Type': 'application/json'
                }
            });

            if (response.ok) {
                this.diagnostics.push({
                    type: 'success',
                    category: 'cors',
                    message: 'CORS 配置正常'
                });
            } else {
                this.diagnostics.push({
                    type: 'warning',
                    category: 'cors',
                    message: `CORS 可能有问题: ${response.status}`
                });
            }
        } catch (error) {
            if (error.message.includes('CORS')) {
                this.diagnostics.push({
                    type: 'error',
                    category: 'cors',
                    message: 'CORS 错误: ' + error.message
                });
            } else {
                this.diagnostics.push({
                    type: 'error',
                    category: 'cors',
                    message: '请求被中止: ' + error.message
                });
            }
        }
    }

    // 检查客户端配置
    async checkClientConfiguration() {
        if (!window.supabase) {
            this.diagnostics.push({
                type: 'error',
                category: 'client',
                message: 'Supabase 客户端未初始化'
            });
            return;
        }

        this.diagnostics.push({
            type: 'success',
            category: 'client',
            message: 'Supabase 客户端已初始化'
        });
    }

    // 应用修复
    async applyFixes() {
        console.log('🔧 开始应用修复...');
        this.fixes = [];

        // 1. 重新初始化客户端
        await this.reinitializeClient();
        
        // 2. 配置重试机制
        await this.setupRetryMechanism();
        
        // 3. 优化请求配置
        await this.optimizeRequestConfig();

        return this.fixes;
    }

    // 重新初始化客户端
    async reinitializeClient() {
        try {
            const config = window.SUPABASE_CONFIG;
            if (!config) throw new Error('配置未找到');

            // 销毁现有客户端
            if (window.supabase) {
                try {
                    await window.supabase.removeAllChannels();
                } catch (e) {
                    console.warn('清理现有客户端时出错:', e);
                }
            }

            // 创建新的客户端实例，优化实时连接配置
            window.supabase = window.supabase.createClient(
                config.SUPABASE_URL,
                config.SUPABASE_ANON_KEY,
                {
                    auth: {
                        persistSession: false,
                        autoRefreshToken: true
                    },
                    realtime: {
                        params: {
                            eventsPerSecond: 10
                        },
                        heartbeatIntervalMs: 30000,
                        reconnectAfterMs: function(tries) {
                            return Math.min(tries * 1000, 30000);
                        }
                    },
                    db: {
                        schema: 'public'
                    },
                    global: {
                        headers: {
                            'Cache-Control': 'no-cache',
                            'Pragma': 'no-cache'
                        }
                    }
                }
            );

            this.fixes.push({
                type: 'success',
                category: 'client',
                message: 'Supabase 客户端重新初始化成功（已优化实时连接）'
            });
        } catch (error) {
            this.fixes.push({
                type: 'error',
                category: 'client',
                message: '客户端初始化失败: ' + error.message
            });
        }
    }

    // 设置重试机制
    async setupRetryMechanism() {
        // 创建带重试的查询函数
        window.supabaseQueryWithRetry = async (table, options = {}) => {
            let lastError;
            
            for (let i = 0; i < this.maxRetries; i++) {
                try {
                    let query = window.supabase.from(table);
                    
                    if (options.select) {
                        query = query.select(options.select);
                    }
                    
                    if (options.orderBy) {
                        query = query.order(options.orderBy.column, { 
                            ascending: options.orderBy.ascending 
                        });
                    }
                    
                    const { data, error } = await query;
                    
                    if (error) throw error;
                    
                    return data;
                } catch (error) {
                    lastError = error;
                    console.warn(`查询重试 ${i + 1}/${this.maxRetries}:`, error.message);
                    
                    if (i < this.maxRetries - 1) {
                        await new Promise(resolve => setTimeout(resolve, 1000 * (i + 1)));
                    }
                }
            }
            
            throw lastError;
        };

        this.fixes.push({
            type: 'success',
            category: 'retry',
            message: '重试机制设置完成'
        });
    }

    // 优化请求配置
    async optimizeRequestConfig() {
        // 设置全局请求拦截器
        const originalFetch = window.fetch;
        
        window.fetch = async (url, options = {}) => {
            // 如果是 Supabase 请求，添加优化配置
            if (url.includes('.supabase.co')) {
                options.headers = {
                    ...options.headers,
                    'Cache-Control': 'no-cache',
                    'Pragma': 'no-cache',
                    'X-Requested-With': 'XMLHttpRequest'
                };
                
                // 设置超时
                const controller = new AbortController();
                const timeoutId = setTimeout(() => controller.abort(), 10000);
                
                options.signal = controller.signal;
                
                try {
                    const response = await originalFetch(url, options);
                    clearTimeout(timeoutId);
                    return response;
                } catch (error) {
                    clearTimeout(timeoutId);
                    throw error;
                }
            }
            
            return originalFetch(url, options);
        };

        this.fixes.push({
            type: 'success',
            category: 'optimization',
            message: '请求配置优化完成'
        });
    }

    // 测试修复效果
    async testConnection() {
        console.log('🧪 测试连接修复效果...');
        
        try {
            const data = await window.supabaseQueryWithRetry('users', {
                select: 'count'
            });
            
            return {
                success: true,
                message: '连接测试成功',
                data: data
            };
        } catch (error) {
            return {
                success: false,
                message: '连接测试失败: ' + error.message,
                error: error
            };
        }
    }

    // 生成诊断报告
    generateReport() {
        const report = {
            timestamp: new Date().toISOString(),
            diagnostics: this.diagnostics,
            fixes: this.fixes,
            summary: {
                totalIssues: this.diagnostics.filter(d => d.type === 'error').length,
                fixesApplied: this.fixes.length,
                status: this.diagnostics.filter(d => d.type === 'error').length === 0 ? 'healthy' : 'needs_attention'
            }
        };
        
        return report;
    }
}

// 自动修复函数
async function autoFixSupabaseConnection() {
    const fixer = new SupabaseConnectionFix();
    
    console.log('🚀 开始自动修复 Supabase 连接...');
    
    // 1. 诊断问题
    await fixer.diagnoseConnection();
    
    // 2. 应用修复
    await fixer.applyFixes();
    
    // 3. 测试连接
    const testResult = await fixer.testConnection();
    
    // 4. 生成报告
    const report = fixer.generateReport();
    
    console.log('📊 修复报告:', report);
    console.log('🧪 测试结果:', testResult);
    
    return {
        report,
        testResult,
        success: testResult.success
    };
}

// 挂载到全局
if (typeof window !== 'undefined') {
    window.SupabaseConnectionFix = SupabaseConnectionFix;
    window.autoFixSupabaseConnection = autoFixSupabaseConnection;
}

// 页面加载时自动运行修复
if (typeof window !== 'undefined') {
    window.addEventListener('DOMContentLoaded', () => {
        // 延迟执行，确保其他脚本已加载
        setTimeout(autoFixSupabaseConnection, 1000);
    });
}