// Enhanced Supabase Connection Manager
// 增强的 Supabase 连接管理器 - 确保前后端数据连接稳定

class EnhancedSupabaseManager {
    constructor() {
        this.client = null;
        this.adminClient = null;
        this.isConnected = false;
        this.connectionAttempts = 0;
        this.maxRetries = 5;
        this.retryDelay = 2000;
        this.realtimeSubscriptions = new Map();
        this.connectionListeners = [];
        this.lastPingTime = null;
        this.pingInterval = null;
        
        this.init();
    }

    // 初始化连接
    async init() {
        try {
            console.log('🚀 初始化 Supabase 连接管理器...');
            
            // 验证配置
            if (!this.validateConfig()) {
                throw new Error('Supabase 配置无效');
            }

            // 创建客户端连接
            await this.createClients();
            
            // 测试连接
            await this.testConnection();
            
            // 启动心跳检测
            this.startHeartbeat();
            
            console.log('✅ Supabase 连接管理器初始化成功');
            this.notifyConnectionChange(true);
            
        } catch (error) {
            console.error('❌ Supabase 连接管理器初始化失败:', error);
            this.scheduleRetry();
        }
    }

    // 验证配置
    validateConfig() {
        const config = window.SUPABASE_CONFIG;
        if (!config) {
            console.error('❌ 未找到 SUPABASE_CONFIG');
            return false;
        }

        if (!config.SUPABASE_URL || !config.SUPABASE_URL.includes('.supabase.co')) {
            console.error('❌ 无效的 Supabase URL');
            return false;
        }

        if (!config.SUPABASE_ANON_KEY || !config.SUPABASE_ANON_KEY.startsWith('eyJ')) {
            console.error('❌ 无效的 Supabase Anon Key');
            return false;
        }

        console.log('✅ Supabase 配置验证通过');
        return true;
    }

    // 创建客户端连接
    async createClients() {
        const config = window.SUPABASE_CONFIG;
        
        // 用户端客户端（使用 anon key）
        this.client = window.supabase.createClient(
            config.SUPABASE_URL,
            config.SUPABASE_ANON_KEY,
            {
                auth: {
                    autoRefreshToken: true,
                    persistSession: true,
                    detectSessionInUrl: false
                },
                realtime: {
                    params: {
                        eventsPerSecond: 10
                    },
                    heartbeatIntervalMs: 30000,
                    reconnectAfterMs: (tries) => Math.min(tries * 1000, 30000)
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

        // 管理员客户端（使用 service role key，如果可用）
        if (config.SUPABASE_SERVICE_ROLE_KEY) {
            this.adminClient = window.supabase.createClient(
                config.SUPABASE_URL,
                config.SUPABASE_SERVICE_ROLE_KEY,
                {
                    auth: {
                        autoRefreshToken: false,
                        persistSession: false
                    },
                    db: {
                        schema: 'public'
                    }
                }
            );
        }

        console.log('✅ Supabase 客户端创建成功');
    }

    // 测试连接
    async testConnection() {
        try {
            console.log('🔍 测试 Supabase 连接...');
            
            // 测试基本查询
            const { data, error } = await this.client
                .from('users')
                .select('count', { count: 'exact', head: true });

            if (error) {
                throw error;
            }

            this.isConnected = true;
            this.connectionAttempts = 0;
            this.lastPingTime = Date.now();
            
            console.log('✅ Supabase 连接测试成功');
            return true;
            
        } catch (error) {
            console.error('❌ Supabase 连接测试失败:', error);
            this.isConnected = false;
            throw error;
        }
    }

    // 启动心跳检测
    startHeartbeat() {
        if (this.pingInterval) {
            clearInterval(this.pingInterval);
        }

        this.pingInterval = setInterval(async () => {
            try {
                await this.ping();
            } catch (error) {
                console.warn('⚠️ 心跳检测失败:', error);
                this.handleConnectionLoss();
            }
        }, 30000); // 每30秒检测一次

        console.log('💓 心跳检测已启动');
    }

    // 心跳检测
    async ping() {
        const { data, error } = await this.client
            .from('users')
            .select('count', { count: 'exact', head: true });

        if (error) {
            throw error;
        }

        this.lastPingTime = Date.now();
        return true;
    }

    // 处理连接丢失
    handleConnectionLoss() {
        if (this.isConnected) {
            this.isConnected = false;
            console.warn('⚠️ 检测到连接丢失，尝试重连...');
            this.notifyConnectionChange(false);
            this.scheduleRetry();
        }
    }

    // 安排重试
    scheduleRetry() {
        if (this.connectionAttempts >= this.maxRetries) {
            console.error('❌ 达到最大重试次数，停止重连');
            return;
        }

        this.connectionAttempts++;
        const delay = this.retryDelay * this.connectionAttempts;
        
        console.log(`🔄 ${delay/1000}秒后进行第${this.connectionAttempts}次重连尝试...`);
        
        setTimeout(() => {
            this.init();
        }, delay);
    }

    // 获取客户端
    getClient(useAdmin = false) {
        if (useAdmin && this.adminClient) {
            return this.adminClient;
        }
        return this.client;
    }

    // 安全查询
    async safeQuery(tableName, query, useAdmin = false) {
        try {
            if (!this.isConnected) {
                throw new Error('数据库连接未建立');
            }

            const client = this.getClient(useAdmin);
            const result = await client.from(tableName)[query.method](...(query.params || []));
            
            if (result.error) {
                throw result.error;
            }

            return result;
            
        } catch (error) {
            console.error(`❌ 查询失败 (${tableName}):`, error);
            
            // 如果是连接错误，尝试重连
            if (error.message.includes('fetch') || error.message.includes('network')) {
                this.handleConnectionLoss();
            }
            
            throw error;
        }
    }

    // 创建实时订阅
    createRealtimeSubscription(tableName, callback, filter = '*') {
        try {
            if (!this.isConnected) {
                throw new Error('数据库连接未建立');
            }

            const subscriptionKey = `${tableName}_${filter}`;
            
            // 如果已存在订阅，先取消
            if (this.realtimeSubscriptions.has(subscriptionKey)) {
                this.removeRealtimeSubscription(subscriptionKey);
            }

            const channel = this.client
                .channel(`realtime:${tableName}`)
                .on('postgres_changes', 
                    { 
                        event: filter, 
                        schema: 'public', 
                        table: tableName 
                    }, 
                    callback
                )
                .subscribe((status) => {
                    console.log(`📡 实时订阅状态 (${tableName}):`, status);
                });

            this.realtimeSubscriptions.set(subscriptionKey, channel);
            console.log(`✅ 创建实时订阅: ${tableName}`);
            
            return subscriptionKey;
            
        } catch (error) {
            console.error(`❌ 创建实时订阅失败 (${tableName}):`, error);
            throw error;
        }
    }

    // 移除实时订阅
    removeRealtimeSubscription(subscriptionKey) {
        const channel = this.realtimeSubscriptions.get(subscriptionKey);
        if (channel) {
            this.client.removeChannel(channel);
            this.realtimeSubscriptions.delete(subscriptionKey);
            console.log(`🗑️ 移除实时订阅: ${subscriptionKey}`);
        }
    }

    // 添加连接状态监听器
    addConnectionListener(callback) {
        this.connectionListeners.push(callback);
    }

    // 移除连接状态监听器
    removeConnectionListener(callback) {
        const index = this.connectionListeners.indexOf(callback);
        if (index > -1) {
            this.connectionListeners.splice(index, 1);
        }
    }

    // 通知连接状态变化
    notifyConnectionChange(isConnected) {
        this.connectionListeners.forEach(callback => {
            try {
                callback(isConnected);
            } catch (error) {
                console.error('❌ 连接状态监听器错误:', error);
            }
        });
    }

    // 获取连接状态
    getConnectionStatus() {
        return {
            isConnected: this.isConnected,
            lastPingTime: this.lastPingTime,
            connectionAttempts: this.connectionAttempts,
            activeSubscriptions: this.realtimeSubscriptions.size
        };
    }

    // 清理资源
    cleanup() {
        if (this.pingInterval) {
            clearInterval(this.pingInterval);
            this.pingInterval = null;
        }

        // 清理所有实时订阅
        this.realtimeSubscriptions.forEach((channel, key) => {
            this.removeRealtimeSubscription(key);
        });

        this.connectionListeners = [];
        console.log('🧹 Supabase 连接管理器资源已清理');
    }
}

// 创建全局实例
window.enhancedSupabaseManager = new EnhancedSupabaseManager();

// 导出便捷方法
window.getSupabaseClient = (useAdmin = false) => {
    return window.enhancedSupabaseManager.getClient(useAdmin);
};

window.safeSupabaseQuery = (tableName, query, useAdmin = false) => {
    return window.enhancedSupabaseManager.safeQuery(tableName, query, useAdmin);
};

window.createRealtimeSubscription = (tableName, callback, filter = '*') => {
    return window.enhancedSupabaseManager.createRealtimeSubscription(tableName, callback, filter);
};

window.getSupabaseConnectionStatus = () => {
    return window.enhancedSupabaseManager.getConnectionStatus();
};

console.log('🔗 Enhanced Supabase Connection Manager 已加载');