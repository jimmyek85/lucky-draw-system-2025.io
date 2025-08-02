// 修复前端后端连接问题的脚本
// 此脚本将诊断并修复用户数据无法保存到Supabase数据库的问题

class ConnectionFixer {
    constructor() {
        this.supabase = null;
        this.issues = [];
        this.fixes = [];
    }

    async initialize() {
        console.log('🔧 开始连接修复程序...');
        
        // 1. 检查配置
        await this.checkConfiguration();
        
        // 2. 初始化Supabase客户端
        await this.initializeSupabase();
        
        // 3. 检查数据库连接
        await this.checkDatabaseConnection();
        
        // 4. 检查数据库权限
        await this.checkDatabasePermissions();
        
        // 5. 清理离线数据
        await this.cleanupOfflineData();
        
        // 6. 测试用户注册流程
        await this.testUserRegistration();
        
        // 7. 应用修复
        await this.applyFixes();
        
        this.generateReport();
    }

    async checkConfiguration() {
        console.log('📋 检查配置...');
        
        if (!window.SUPABASE_CONFIG) {
            this.issues.push('❌ SUPABASE_CONFIG 未找到');
            return;
        }

        const config = window.SUPABASE_CONFIG;
        
        if (!config.SUPABASE_URL || config.SUPABASE_URL === 'https://your-project-id.supabase.co') {
            this.issues.push('❌ Supabase URL 未正确配置');
        }
        
        if (!config.SUPABASE_ANON_KEY || config.SUPABASE_ANON_KEY === 'your-supabase-anon-key-here') {
            this.issues.push('❌ Supabase API Key 未正确配置');
        }
        
        if (!config.SUPABASE_ANON_KEY.startsWith('eyJ')) {
            this.issues.push('❌ Supabase API Key 格式不正确');
        }
        
        console.log('✅ 配置检查完成');
    }

    async initializeSupabase() {
        console.log('🔧 初始化Supabase客户端...');
        
        try {
            this.supabase = window.supabase.createClient(
                window.SUPABASE_CONFIG.SUPABASE_URL,
                window.SUPABASE_CONFIG.SUPABASE_ANON_KEY
            );
            console.log('✅ Supabase客户端初始化成功');
        } catch (error) {
            this.issues.push(`❌ Supabase客户端初始化失败: ${error.message}`);
        }
    }

    async checkDatabaseConnection() {
        console.log('🔗 检查数据库连接...');
        
        if (!this.supabase) {
            this.issues.push('❌ Supabase客户端未初始化');
            return;
        }

        try {
            const { data, error } = await this.supabase
                .from('users')
                .select('count')
                .limit(1);
            
            if (error && error.code !== 'PGRST116') {
                this.issues.push(`❌ 数据库连接失败: ${error.message}`);
                
                // 分析错误类型并提供修复建议
                if (error.message.includes('JWT')) {
                    this.fixes.push('🔑 需要检查API Key是否有效');
                } else if (error.message.includes('permission')) {
                    this.fixes.push('🔐 需要检查数据库权限配置');
                } else if (error.message.includes('relation') || error.message.includes('does not exist')) {
                    this.fixes.push('📊 需要创建数据库表结构');
                }
            } else {
                console.log('✅ 数据库连接成功');
            }
        } catch (error) {
            this.issues.push(`❌ 数据库连接测试失败: ${error.message}`);
        }
    }

    async checkDatabasePermissions() {
        console.log('🔐 检查数据库权限...');
        
        if (!this.supabase) return;

        try {
            // 测试读取权限
            const { data: readTest, error: readError } = await this.supabase
                .from('users')
                .select('*')
                .limit(1);
            
            if (readError) {
                this.issues.push(`❌ 读取权限测试失败: ${readError.message}`);
            } else {
                console.log('✅ 读取权限正常');
            }

            // 测试写入权限
            const testUser = {
                name: 'Connection Test User',
                phone: '+60_test_' + Date.now(),
                email: 'test@connection-fix.com',
                address: 'Test Address',
                drawchances: 1,
                joindate: new Date().toISOString(),
                prizeswon: []
            };

            const { data: insertTest, error: insertError } = await this.supabase
                .from('users')
                .insert([testUser])
                .select()
                .single();
            
            if (insertError) {
                this.issues.push(`❌ 写入权限测试失败: ${insertError.message}`);
                
                // 分析权限错误并提供修复建议
                if (insertError.message.includes('RLS')) {
                    this.fixes.push('🛡️ 需要配置行级安全策略(RLS)');
                } else if (insertError.message.includes('permission')) {
                    this.fixes.push('👤 需要为anon角色添加INSERT权限');
                }
            } else {
                console.log('✅ 写入权限正常');
                
                // 清理测试数据
                await this.supabase.from('users').delete().eq('phone', testUser.phone);
                console.log('🧹 测试数据已清理');
            }
        } catch (error) {
            this.issues.push(`❌ 权限检查失败: ${error.message}`);
        }
    }

    async cleanupOfflineData() {
        console.log('📱 检查并清理离线数据...');
        
        const offlineUser = localStorage.getItem('offlineUser');
        if (offlineUser) {
            try {
                const userData = JSON.parse(offlineUser);
                console.log('⚠️ 发现离线用户数据:', userData);
                
                if (this.supabase && this.issues.length === 0) {
                    // 如果连接正常，尝试同步离线数据
                    console.log('🔄 尝试同步离线数据到数据库...');
                    
                    const { data: existingUser, error: fetchError } = await this.supabase
                        .from('users')
                        .select('*')
                        .eq('phone', userData.phone)
                        .single();
                    
                    if (!existingUser && fetchError?.code === 'PGRST116') {
                        // 用户不存在，插入数据
                        const { data: newUser, error: insertError } = await this.supabase
                            .from('users')
                            .insert([userData])
                            .select()
                            .single();
                        
                        if (!insertError) {
                            localStorage.removeItem('offlineUser');
                            console.log('✅ 离线数据同步成功，本地数据已清理');
                            this.fixes.push('🔄 离线用户数据已同步到数据库');
                        } else {
                            this.issues.push(`❌ 离线数据同步失败: ${insertError.message}`);
                        }
                    } else if (existingUser) {
                        localStorage.removeItem('offlineUser');
                        console.log('✅ 用户已存在于数据库，本地离线数据已清理');
                        this.fixes.push('🔄 离线数据已清理（用户已存在）');
                    }
                } else {
                    this.issues.push('⚠️ 发现离线用户数据，但数据库连接有问题');
                    this.fixes.push('🔧 修复数据库连接后需要手动同步离线数据');
                }
            } catch (error) {
                console.error('离线数据处理错误:', error);
                this.issues.push(`❌ 离线数据处理失败: ${error.message}`);
            }
        } else {
            console.log('✅ 未发现离线用户数据');
        }
    }

    async testUserRegistration() {
        console.log('👤 测试用户注册流程...');
        
        if (!this.supabase || this.issues.length > 0) {
            console.log('⏭️ 跳过用户注册测试（存在其他问题）');
            return;
        }

        try {
            const testUser = {
                name: 'Registration Test User',
                phone: '+60_reg_test_' + Date.now(),
                email: 'regtest@connection-fix.com',
                address: 'Registration Test Address',
                drawchances: 1,
                joindate: new Date().toISOString(),
                prizeswon: []
            };

            const { data: newUser, error: insertError } = await this.supabase
                .from('users')
                .insert([testUser])
                .select()
                .single();
            
            if (insertError) {
                this.issues.push(`❌ 用户注册测试失败: ${insertError.message}`);
            } else {
                console.log('✅ 用户注册测试成功');
                
                // 清理测试数据
                await this.supabase.from('users').delete().eq('phone', testUser.phone);
                console.log('🧹 注册测试数据已清理');
            }
        } catch (error) {
            this.issues.push(`❌ 用户注册测试失败: ${error.message}`);
        }
    }

    async applyFixes() {
        console.log('🔧 应用修复...');
        
        // 移除离线模式提示（如果存在）
        const offlineNotice = document.querySelector('.fixed.top-0.bg-yellow-600');
        if (offlineNotice) {
            offlineNotice.remove();
            this.fixes.push('🗑️ 移除了离线模式提示');
        }
        
        // 如果没有严重问题，重新初始化应用
        if (this.issues.length === 0 && this.supabase) {
            console.log('🔄 重新初始化应用连接...');
            
            // 更新全局supabase实例
            if (window.supabase) {
                window.supabase = this.supabase;
            }
            
            this.fixes.push('🔄 应用连接已重新初始化');
        }
    }

    generateReport() {
        console.log('\n📊 连接修复报告');
        console.log('='.repeat(50));
        
        if (this.issues.length === 0) {
            console.log('🎉 恭喜！前端后端连接正常，没有发现问题。');
        } else {
            console.log('⚠️ 发现以下问题:');
            this.issues.forEach(issue => console.log(`  ${issue}`));
        }
        
        if (this.fixes.length > 0) {
            console.log('\n🔧 已应用的修复:');
            this.fixes.forEach(fix => console.log(`  ${fix}`));
        }
        
        console.log('\n💡 建议:');
        if (this.issues.some(issue => issue.includes('配置'))) {
            console.log('  1. 检查 supabase-config.js 中的 URL 和 API Key');
            console.log('  2. 确保从 Supabase Dashboard 获取正确的配置信息');
        }
        
        if (this.issues.some(issue => issue.includes('权限') || issue.includes('RLS'))) {
            console.log('  3. 在 Supabase Dashboard 中检查行级安全策略(RLS)');
            console.log('  4. 确保 anon 角色有足够的权限');
        }
        
        if (this.issues.some(issue => issue.includes('表') || issue.includes('relation'))) {
            console.log('  5. 运行 SUPABASE_SETUP.md 中的 SQL 语句创建数据库表');
        }
        
        console.log('\n📞 如需进一步帮助，请查看:');
        console.log('  - SUPABASE_SETUP.md 文件');
        console.log('  - debug-connection.html 页面');
        console.log('  - test-supabase-connection.html 页面');
        
        console.log('='.repeat(50));
        
        // 返回修复状态
        return {
            success: this.issues.length === 0,
            issues: this.issues,
            fixes: this.fixes
        };
    }
}

// 自动运行修复程序
if (typeof window !== 'undefined') {
    window.ConnectionFixer = ConnectionFixer;
    
    // 页面加载完成后自动运行
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', async () => {
            const fixer = new ConnectionFixer();
            await fixer.initialize();
        });
    } else {
        // 如果页面已加载，立即运行
        setTimeout(async () => {
            const fixer = new ConnectionFixer();
            await fixer.initialize();
        }, 1000);
    }
}

// 导出供其他模块使用
if (typeof module !== 'undefined' && module.exports) {
    module.exports = ConnectionFixer;
}