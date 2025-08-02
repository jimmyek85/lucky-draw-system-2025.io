// Supabase 数据连接管理器
// 统一管理 index.html 和 admin.html 之间的实时数据同步
// 解决 net::ERR_ABORTED 错误和数据连接问题

class SupabaseConnectionManager {
    constructor() {
        this.supabase = null;
        this.isConnected = false;
        this.subscriptions = new Map();
        this.reconnectAttempts = 0;
        this.maxReconnectAttempts = 5;
        this.reconnectDelay = 3000;
        this.connectionListeners = [];
        this.errorHandlers = [];
        
        // 初始化配置
        this.config = window.SUPABASE_CONFIG || {};
        this.tables = this.config.TABLES || {
            USERS: 'users',
            SETTINGS: 'settings',
            KNOWLEDGE: 'knowledge'
        };
        
        // 绑定方法
        this.handleConnectionError = this.handleConnectionError.bind(this);
        this.handleReconnect = this.handleReconnect.bind(this);
    }

    // 初始化连接
    async initialize() {
        try {
            console.log('🔗 初始化 Supabase 连接管理器...');
            
            if (!this.config.SUPABASE_URL || !this.config.SUPABASE_ANON_KEY) {
                throw new Error('Supabase 配置缺失');
            }

            // 创建优化的 Supabase 客户端
            this.supabase = window.supabase.createClient(
                this.config.SUPABASE_URL,
                this.config.SUPABASE_ANON_KEY,
                {
                    auth: {
                        autoRefreshToken: true,
                        persistSession: false,
                        detectSessionInUrl: false
                    },
                    global: {
                        headers: {
                            'X-Client-Info': 'luckydraw-connection-manager',
                            'Cache-Control': 'no-cache',
                            'Pragma': 'no-cache'
                        }
                    },
                    db: {
                        schema: 'public'
                    },
                    realtime: {
                        params: {
                            eventsPerSecond: 3,
                            timeout: 30000
                        }
                    }
                }
            );

            // 测试连接
            await this.testConnection();
            
            this.isConnected = true;
            this.reconnectAttempts = 0;
            
            console.log('✅ Supabase 连接管理器初始化成功');
            this.notifyConnectionListeners('connected');
            
            return true;
        } catch (error) {
            console.error('❌ Supabase 连接初始化失败:', error);
            this.handleConnectionError(error);
            return false;
        }
    }

    // 测试连接
    async testConnection() {
        if (!this.supabase) {
            throw new Error('Supabase 客户端未初始化');
        }

        try {
            // 使用简单的查询测试连接
            const { data, error } = await this.supabase
                .from(this.tables.USERS)
                .select('id')
                .limit(1);

            if (error) {
                throw error;
            }

            console.log('✅ Supabase 连接测试成功');
            return true;
        } catch (error) {
            console.error('❌ Supabase 连接测试失败:', error);
            throw error;
        }
    }

    // 安全的数据查询
    async safeQuery(table, query = {}) {
        if (!this.isConnected || !this.supabase) {
            await this.initialize();
        }

        try {
            const { select = '*', filter = {}, limit, orderBy } = query;
            
            let queryBuilder = this.supabase.from(table).select(select);
            
            // 应用过滤器
            Object.entries(filter).forEach(([key, value]) => {
                queryBuilder = queryBuilder.eq(key, value);
            });
            
            // 应用排序
            if (orderBy) {
                queryBuilder = queryBuilder.order(orderBy.column, { ascending: orderBy.ascending !== false });
            }
            
            // 应用限制
            if (limit) {
                queryBuilder = queryBuilder.limit(limit);
            }

            const { data, error } = await queryBuilder;
            
            if (error) {
                throw error;
            }

            return data;
        } catch (error) {
            console.error(`❌ 查询 ${table} 表失败:`, error);
            this.handleConnectionError(error);
            throw error;
        }
    }

    // 安全的数据插入
    async safeInsert(table, data) {
        if (!this.isConnected || !this.supabase) {
            await this.initialize();
        }

        try {
            // 处理日期字段
            const processedData = this.processDataForInsert(data);
            
            const { data: result, error } = await this.supabase
                .from(table)
                .insert(processedData)
                .select();

            if (error) {
                throw error;
            }

            console.log(`✅ 数据插入 ${table} 表成功`);
            return result;
        } catch (error) {
            console.error(`❌ 插入 ${table} 表失败:`, error);
            this.handleConnectionError(error);
            throw error;
        }
    }

    // 安全的数据更新
    async safeUpdate(table, data, filter) {
        if (!this.isConnected || !this.supabase) {
            await this.initialize();
        }

        try {
            const processedData = this.processDataForInsert(data);
            
            let queryBuilder = this.supabase.from(table).update(processedData);
            
            // 应用过滤器
            Object.entries(filter).forEach(([key, value]) => {
                queryBuilder = queryBuilder.eq(key, value);
            });

            const { data: result, error } = await queryBuilder.select();

            if (error) {
                throw error;
            }

            console.log(`✅ 数据更新 ${table} 表成功`);
            return result;
        } catch (error) {
            console.error(`❌ 更新 ${table} 表失败:`, error);
            this.handleConnectionError(error);
            throw error;
        }
    }

    // 处理数据格式
    processDataForInsert(data) {
        const processed = { ...data };
        
        // 统一日期字段处理
        if (processed.joindate && !processed.joinDate) {
            processed.joinDate = processed.joindate;
            delete processed.joindate;
        }
        
        // 确保日期是 ISO 字符串格式
        if (processed.joinDate) {
            if (processed.joinDate instanceof Date) {
                processed.joinDate = processed.joinDate.toISOString();
            } else if (typeof processed.joinDate === 'string') {
                processed.joinDate = new Date(processed.joinDate).toISOString();
            }
        }
        
        return processed;
    }

    // 安全的实时订阅
    subscribeToTable(table, callback, options = {}) {
        if (!this.isConnected || !this.supabase) {
            console.warn('⚠️ Supabase 未连接，无法创建订阅');
            return null;
        }

        try {
            const channelName = `${table}-${Date.now()}`;
            
            // 清理已存在的订阅
            this.unsubscribeFromTable(table);
            
            const subscription = this.supabase
                .channel(channelName)
                .on('postgres_changes', {
                    event: options.event || '*',
                    schema: 'public',
                    table: table
                }, (payload) => {
                    console.log(`📡 ${table} 表数据变更:`, payload);
                    callback(payload);
                })
                .subscribe((status) => {
                    if (status === 'SUBSCRIBED') {
                        console.log(`✅ ${table} 表实时订阅已启用`);
                    } else if (status === 'CHANNEL_ERROR') {
                        console.error(`❌ ${table} 表订阅错误`);
                        this.handleConnectionError(new Error(`${table} 订阅失败`));
                    }
                });

            this.subscriptions.set(table, subscription);
            return subscription;
        } catch (error) {
            console.error(`❌ 创建 ${table} 表订阅失败:`, error);
            this.handleConnectionError(error);
            return null;
        }
    }

    // 取消表订阅
    unsubscribeFromTable(table) {
        if (this.subscriptions.has(table)) {
            const subscription = this.subscriptions.get(table);
            subscription.unsubscribe();
            this.subscriptions.delete(table);
            console.log(`🔇 ${table} 表订阅已取消`);
        }
    }

    // 取消所有订阅
    unsubscribeAll() {
        this.subscriptions.forEach((subscription, table) => {
            subscription.unsubscribe();
            console.log(`🔇 ${table} 表订阅已取消`);
        });
        this.subscriptions.clear();
    }

    // 处理连接错误
    handleConnectionError(error) {
        console.error('🔥 Supabase 连接错误:', error);
        
        this.isConnected = false;
        this.notifyErrorHandlers(error);
        
        // 如果是网络错误或连接中止，尝试重连
        if (this.shouldRetry(error)) {
            this.scheduleReconnect();
        }
    }

    // 判断是否应该重试
    shouldRetry(error) {
        const retryableErrors = [
            'net::ERR_ABORTED',
            'NetworkError',
            'Failed to fetch',
            'Connection failed',
            'CHANNEL_ERROR'
        ];
        
        return retryableErrors.some(errorType => 
            error.message?.includes(errorType) || error.toString().includes(errorType)
        ) && this.reconnectAttempts < this.maxReconnectAttempts;
    }

    // 安排重连
    scheduleReconnect() {
        if (this.reconnectAttempts >= this.maxReconnectAttempts) {
            console.error('❌ 达到最大重连次数，停止重连');
            return;
        }

        this.reconnectAttempts++;
        const delay = this.reconnectDelay * this.reconnectAttempts;
        
        console.log(`🔄 ${delay}ms 后尝试第 ${this.reconnectAttempts} 次重连...`);
        
        setTimeout(() => {
            this.handleReconnect();
        }, delay);
    }

    // 处理重连
    async handleReconnect() {
        try {
            console.log('🔄 尝试重新连接 Supabase...');
            
            // 清理现有连接
            this.cleanup();
            
            // 重新初始化
            const success = await this.initialize();
            
            if (success) {
                console.log('✅ Supabase 重连成功');
                this.notifyConnectionListeners('reconnected');
            } else {
                throw new Error('重连失败');
            }
        } catch (error) {
            console.error('❌ Supabase 重连失败:', error);
            this.scheduleReconnect();
        }
    }

    // 清理连接
    cleanup() {
        this.unsubscribeAll();
        this.isConnected = false;
        this.supabase = null;
    }

    // 添加连接监听器
    onConnectionChange(listener) {
        this.connectionListeners.push(listener);
    }

    // 添加错误处理器
    onError(handler) {
        this.errorHandlers.push(handler);
    }

    // 通知连接监听器
    notifyConnectionListeners(status) {
        this.connectionListeners.forEach(listener => {
            try {
                listener(status);
            } catch (error) {
                console.error('连接监听器错误:', error);
            }
        });
    }

    // 通知错误处理器
    notifyErrorHandlers(error) {
        this.errorHandlers.forEach(handler => {
            try {
                handler(error);
            } catch (handlerError) {
                console.error('错误处理器错误:', handlerError);
            }
        });
    }

    // 获取连接状态
    getStatus() {
        return {
            connected: this.isConnected,
            reconnectAttempts: this.reconnectAttempts,
            subscriptions: this.subscriptions.size,
            config: this.config
        };
    }

    // 强制重连
    async forceReconnect() {
        console.log('🔄 强制重新连接...');
        this.reconnectAttempts = 0;
        this.cleanup();
        return await this.initialize();
    }
}

// 创建全局实例
if (typeof window !== 'undefined') {
    window.supabaseConnectionManager = new SupabaseConnectionManager();
    
    // 页面加载时自动初始化
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', () => {
            window.supabaseConnectionManager.initialize();
        });
    } else {
        window.supabaseConnectionManager.initialize();
    }
    
    // 页面卸载时清理
    window.addEventListener('beforeunload', () => {
        window.supabaseConnectionManager.cleanup();
    });
}

// 导出类
if (typeof module !== 'undefined' && module.exports) {
    module.exports = SupabaseConnectionManager;
}