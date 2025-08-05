/**
 * 统一连接验证脚本
 * 用于验证所有页面的 Supabase 连接配置一致性
 */

class ConnectionVerifier {
    constructor() {
        this.results = {
            configCheck: false,
            connectionTest: false,
            tablesCheck: false,
            dataConsistency: false,
            errors: []
        };
    }

    // 验证配置文件
    async verifyConfig() {
        try {
            console.log('🔍 验证 Supabase 配置...');
            
            // 检查配置是否存在
            if (!window.SUPABASE_CONFIG) {
                throw new Error('SUPABASE_CONFIG 未定义');
            }

            const config = window.SUPABASE_CONFIG;
            
            // 验证必要的配置项
            const requiredFields = ['SUPABASE_URL', 'SUPABASE_ANON_KEY', 'TABLES'];
            for (const field of requiredFields) {
                if (!config[field]) {
                    throw new Error(`配置缺失: ${field}`);
                }
            }

            // 验证表名配置
            const requiredTables = ['USERS', 'SETTINGS', 'KNOWLEDGE'];
            for (const table of requiredTables) {
                if (!config.TABLES[table]) {
                    throw new Error(`表名配置缺失: ${table}`);
                }
            }

            this.results.configCheck = true;
            console.log('✅ 配置验证通过');
            return true;

        } catch (error) {
            this.results.errors.push(`配置验证失败: ${error.message}`);
            console.error('❌ 配置验证失败:', error);
            return false;
        }
    }

    // 测试 Supabase 连接
    async testConnection() {
        try {
            console.log('🔗 测试 Supabase 连接...');
            
            if (!window.supabaseConnectionManager) {
                throw new Error('SupabaseConnectionManager 未初始化');
            }

            // 测试连接
            const isConnected = await window.supabaseConnectionManager.testConnection();
            if (!isConnected) {
                throw new Error('Supabase 连接测试失败');
            }

            this.results.connectionTest = true;
            console.log('✅ 连接测试通过');
            return true;

        } catch (error) {
            this.results.errors.push(`连接测试失败: ${error.message}`);
            console.error('❌ 连接测试失败:', error);
            return false;
        }
    }

    // 验证数据表
    async verifyTables() {
        try {
            console.log('📊 验证数据表...');
            
            const tables = window.SUPABASE_CONFIG.TABLES;
            const tableResults = {};

            for (const [key, tableName] of Object.entries(tables)) {
                try {
                    // 尝试查询表结构
                    const result = await window.supabaseConnectionManager.safeQuery(tableName, {
                        limit: 1
                    });
                    
                    tableResults[key] = {
                        name: tableName,
                        accessible: true,
                        error: null
                    };
                    
                } catch (error) {
                    tableResults[key] = {
                        name: tableName,
                        accessible: false,
                        error: error.message
                    };
                }
            }

            // 检查是否所有表都可访问
            const allAccessible = Object.values(tableResults).every(table => table.accessible);
            
            if (allAccessible) {
                this.results.tablesCheck = true;
                console.log('✅ 所有数据表验证通过');
            } else {
                const failedTables = Object.entries(tableResults)
                    .filter(([_, table]) => !table.accessible)
                    .map(([key, table]) => `${key}(${table.name}): ${table.error}`)
                    .join(', ');
                throw new Error(`部分表无法访问: ${failedTables}`);
            }

            return tableResults;

        } catch (error) {
            this.results.errors.push(`数据表验证失败: ${error.message}`);
            console.error('❌ 数据表验证失败:', error);
            return false;
        }
    }

    // 验证数据一致性
    async verifyDataConsistency() {
        try {
            console.log('🔄 验证数据一致性...');
            
            // 获取用户数据样本
            const users = await window.supabaseConnectionManager.safeQuery(
                window.SUPABASE_CONFIG.TABLES.USERS, 
                { limit: 5 }
            );

            if (!users || users.length === 0) {
                console.log('⚠️ 用户表为空，跳过数据一致性检查');
                this.results.dataConsistency = true;
                return true;
            }

            // 检查数据结构一致性
            const expectedFields = ['name', 'phone', 'email', 'drawchances', 'joindate'];
            const sampleUser = users[0];
            
            for (const field of expectedFields) {
                if (!(field in sampleUser) && !(field.toLowerCase() in sampleUser)) {
                    console.warn(`⚠️ 字段可能缺失: ${field}`);
                }
            }

            this.results.dataConsistency = true;
            console.log('✅ 数据一致性验证通过');
            return true;

        } catch (error) {
            this.results.errors.push(`数据一致性验证失败: ${error.message}`);
            console.error('❌ 数据一致性验证失败:', error);
            return false;
        }
    }

    // 执行完整验证
    async runFullVerification() {
        console.log('🚀 开始完整连接验证...');
        
        const steps = [
            { name: '配置验证', method: 'verifyConfig' },
            { name: '连接测试', method: 'testConnection' },
            { name: '数据表验证', method: 'verifyTables' },
            { name: '数据一致性验证', method: 'verifyDataConsistency' }
        ];

        for (const step of steps) {
            console.log(`\n📋 执行: ${step.name}`);
            await this[step.method]();
        }

        return this.generateReport();
    }

    // 生成验证报告
    generateReport() {
        const totalChecks = 4;
        const passedChecks = Object.values(this.results).filter(v => v === true).length;
        const successRate = (passedChecks / totalChecks * 100).toFixed(1);

        const report = {
            summary: {
                total: totalChecks,
                passed: passedChecks,
                failed: totalChecks - passedChecks,
                successRate: `${successRate}%`
            },
            details: this.results,
            recommendations: this.generateRecommendations()
        };

        console.log('\n📊 验证报告:');
        console.log(`总检查项: ${report.summary.total}`);
        console.log(`通过: ${report.summary.passed}`);
        console.log(`失败: ${report.summary.failed}`);
        console.log(`成功率: ${report.summary.successRate}`);

        if (this.results.errors.length > 0) {
            console.log('\n❌ 错误列表:');
            this.results.errors.forEach((error, index) => {
                console.log(`${index + 1}. ${error}`);
            });
        }

        if (report.recommendations.length > 0) {
            console.log('\n💡 建议:');
            report.recommendations.forEach((rec, index) => {
                console.log(`${index + 1}. ${rec}`);
            });
        }

        return report;
    }

    // 生成改进建议
    generateRecommendations() {
        const recommendations = [];

        if (!this.results.configCheck) {
            recommendations.push('检查 supabase-config.js 文件是否正确加载和配置');
        }

        if (!this.results.connectionTest) {
            recommendations.push('验证 Supabase URL 和 API 密钥是否正确');
            recommendations.push('检查网络连接和防火墙设置');
        }

        if (!this.results.tablesCheck) {
            recommendations.push('确认数据库表已正确创建');
            recommendations.push('检查数据库权限设置');
        }

        if (!this.results.dataConsistency) {
            recommendations.push('检查数据表结构是否与应用程序期望一致');
        }

        if (this.results.errors.length === 0) {
            recommendations.push('所有检查通过！系统连接正常');
        }

        return recommendations;
    }
}

// 导出验证器
window.ConnectionVerifier = ConnectionVerifier;

// 自动执行验证（如果在浏览器环境中）
if (typeof window !== 'undefined' && window.document) {
    document.addEventListener('DOMContentLoaded', async () => {
        // 等待其他脚本加载
        setTimeout(async () => {
            if (window.SUPABASE_CONFIG && window.supabaseConnectionManager) {
                const verifier = new ConnectionVerifier();
                const report = await verifier.runFullVerification();
                
                // 将报告存储到全局变量供其他脚本使用
                window.connectionReport = report;
                
                // 触发自定义事件
                window.dispatchEvent(new CustomEvent('connectionVerified', { 
                    detail: report 
                }));
            }
        }, 2000);
    });
}