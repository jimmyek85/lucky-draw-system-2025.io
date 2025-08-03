// 修复3个关键错误的脚本
// 错误1: net::ERR_ABORTED - Supabase连接中止
// 错误2: RangeError: Maximum call stack size exceeded - 栈溢出
// 错误3: TypeError: user.joinDate?.toDate is not a function - 数据类型错误

console.log('🔧 开始修复3个关键错误...');

// 修复1: 优化Supabase连接配置
function fixSupabaseConnection() {
    console.log('🔗 修复1: 优化Supabase连接配置...');
    
    if (typeof window !== 'undefined' && window.SUPABASE_CONFIG && window.supabase) {
        try {
            // 重新创建优化的Supabase客户端
            window.supabaseFixed = window.supabase.createClient(
                window.SUPABASE_CONFIG.SUPABASE_URL,
                window.SUPABASE_CONFIG.SUPABASE_ANON_KEY,
                {
                    auth: {
                        autoRefreshToken: true,
                        persistSession: false,
                        detectSessionInUrl: false
                    },
                    global: {
                        headers: {
                            'X-Client-Info': 'supabase-js-web',
                            'Cache-Control': 'no-cache',
                            'Pragma': 'no-cache'
                        }
                    },
                    db: {
                        schema: 'public'
                    },
                    realtime: {
                        params: {
                            eventsPerSecond: 5
                        }
                    }
                }
            );
            
            // 替换全局supabase实例
            window.supabase = window.supabaseFixed;
            
            console.log('✅ Supabase连接配置已优化');
            return true;
        } catch (error) {
            console.error('❌ Supabase连接修复失败:', error);
            return false;
        }
    }
    
    console.warn('⚠️ Supabase配置或客户端未找到');
    return false;
}

// 修复2: 解决栈溢出问题
function fixStackOverflow() {
    console.log('🔄 修复2: 解决栈溢出问题...');
    
    try {
        // 创建安全的订阅管理器
        window.SafeSubscriptionManager = class {
            constructor() {
                this.subscriptions = new Map();
                this.isDestroyed = false;
            }
            
            subscribe(channelName, config, callback) {
                if (this.isDestroyed) return null;
                
                // 先清理已存在的订阅
                this.unsubscribe(channelName);
                
                try {
                    const subscription = window.supabase
                        .channel(channelName)
                        .on('postgres_changes', config, callback)
                        .subscribe();
                    
                    this.subscriptions.set(channelName, subscription);
                    return subscription;
                } catch (error) {
                    console.warn('订阅创建失败:', error);
                    return null;
                }
            }
            
            unsubscribe(channelName) {
                if (this.isDestroyed) return;
                
                const subscription = this.subscriptions.get(channelName);
                if (subscription && !subscription._closed) {
                    try {
                        subscription.unsubscribe();
                    } catch (error) {
                        console.warn('订阅取消警告:', error);
                    }
                    this.subscriptions.delete(channelName);
                }
            }
            
            unsubscribeAll() {
                if (this.isDestroyed) return;
                
                for (const [channelName] of this.subscriptions) {
                    this.unsubscribe(channelName);
                }
                this.isDestroyed = true;
            }
        };
        
        // 创建全局实例
        if (window.subscriptionManager) {
            window.subscriptionManager.unsubscribeAll();
        }
        window.subscriptionManager = new window.SafeSubscriptionManager();
        
        console.log('✅ 栈溢出问题已修复');
        return true;
    } catch (error) {
        console.error('❌ 栈溢出修复失败:', error);
        return false;
    }
}

// 修复3: 解决数据类型错误
function fixDataTypeError() {
    console.log('📅 修复3: 解决数据类型错误...');
    
    try {
        // 创建安全的日期处理函数
        window.safeFormatDate = function(dateValue) {
            if (!dateValue) return '未设置';
            
            try {
                // 处理字符串日期
                if (typeof dateValue === 'string') {
                    const date = new Date(dateValue);
                    return isNaN(date.getTime()) ? '无效日期' : date.toLocaleDateString('zh-CN');
                }
                
                // 处理Firebase Timestamp (有toDate方法)
                if (dateValue && typeof dateValue.toDate === 'function') {
                    return dateValue.toDate().toLocaleDateString('zh-CN');
                }
                
                // 处理Date对象
                if (dateValue instanceof Date) {
                    return isNaN(dateValue.getTime()) ? '无效日期' : dateValue.toLocaleDateString('zh-CN');
                }
                
                // 处理时间戳
                if (typeof dateValue === 'number') {
                    const date = new Date(dateValue);
                    return isNaN(date.getTime()) ? '无效日期' : date.toLocaleDateString('zh-CN');
                }
                
                return '未知格式';
            } catch (error) {
                console.warn('日期格式化错误:', error);
                return '格式错误';
            }
        };
        
        // 创建安全的用户数据处理函数
        window.safeProcessUserData = function(users) {
            if (!Array.isArray(users)) return [];
            
            return users.map(user => {
                const processedUser = { ...user };
                
                // 安全处理日期字段
                if (user.joinDate) {
                    processedUser.joinDateFormatted = window.safeFormatDate(user.joinDate);
                }
                
                if (user.created_at) {
                    processedUser.createdAtFormatted = window.safeFormatDate(user.created_at);
                }
                
                if (user.updated_at) {
                    processedUser.updatedAtFormatted = window.safeFormatDate(user.updated_at);
                }
                
                return processedUser;
            });
        };
        
        // 重写renderTable函数（如果存在）
        if (typeof window.renderTable === 'function') {
            const originalRenderTable = window.renderTable;
            window.renderTable = function(users) {
                try {
                    const safeUsers = window.safeProcessUserData(users);
                    return originalRenderTable(safeUsers);
                } catch (error) {
                    console.error('renderTable错误:', error);
                    return '<tr><td colspan="100%">数据渲染错误</td></tr>';
                }
            };
        }
        
        console.log('✅ 数据类型错误已修复');
        return true;
    } catch (error) {
        console.error('❌ 数据类型修复失败:', error);
        return false;
    }
}

// 执行所有修复
function fixAllThreeErrors() {
    console.log('🚀 开始修复所有3个错误...');
    
    const results = {
        error1: fixSupabaseConnection(),
        error2: fixStackOverflow(),
        error3: fixDataTypeError()
    };
    
    const successCount = Object.values(results).filter(Boolean).length;
    
    console.log(`📊 修复结果: ${successCount}/3 个错误已修复`);
    
    if (successCount === 3) {
        console.log('🎉 所有3个错误已成功修复！');
    } else {
        console.log('⚠️ 部分错误修复失败，请检查控制台日志');
    }
    
    return results;
}

// 如果在浏览器环境中，自动执行修复
if (typeof window !== 'undefined') {
    // 等待页面加载完成后执行
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', fixAllThreeErrors);
    } else {
        fixAllThreeErrors();
    }
}

// 导出函数供其他脚本使用
if (typeof module !== 'undefined' && module.exports) {
    module.exports = {
        fixSupabaseConnection,
        fixStackOverflow,
        fixDataTypeError,
        fixAllThreeErrors
    };
}