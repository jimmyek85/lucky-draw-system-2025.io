# 🧹 1602 幸运轮盘项目文件清理脚本
# 此脚本将删除重复和临时文件，保留核心项目文件

Write-Host "🎯 开始清理 1602 幸运轮盘项目文件..." -ForegroundColor Green
Write-Host "📁 当前目录: $(Get-Location)" -ForegroundColor Yellow

# 创建备份目录
$backupDir = ".\backup_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
Write-Host "📦 创建备份目录: $backupDir" -ForegroundColor Cyan
New-Item -ItemType Directory -Path $backupDir -Force | Out-Null

# 定义要删除的文件列表
$filesToDelete = @(
    # 重复的数据库设置文件
    "database-setup-step-by-step.sql",
    "database-setup.sql",
    "quick-fix.sql",
    
    # 重复的文档文件
    "DATABASE_SETUP_GUIDE.md",
    "DATABASE_SETUP_README.md",
    "QUICK_DATABASE_SETUP.md",
    "QUICK_FIX_DATABASE.md",
    "SETUP_DATABASE.md",
    "SUPABASE_SQL_SETUP_GUIDE.md",
    
    # 临时测试和修复文件
    "check-database-setup.html",
    "connection-test.html",
    "database-connection-test.html",
    "simple-connection-test.html",
    "debug-connection.html",
    "reconnect-supabase.html",
    "start-supabase-connection.html",
    "one-click-test.html",
    
    # 修复指导页面
    "connection-fix-solution.html",
    "database-fix-guide.html",
    "fix-column-name-error.html",
    "fix-data-connection.html",
    "fix-settings-error-guide.html",
    "fix-health-check-guide.html",
    "security-fix-guide.html",
    
    # 重复的连接文件
    "enhanced-supabase-connection.js",
    "supabase-connection-fix.js",
    "fix-connection.js",
    "final-config-verification.js",
    "verify-connections.js",
    
    # 临时SQL修复文件
    "database-verification-fix.sql",
    "fix-draw-stats-view.sql",
    "fix-security-definer-views.sql",
    "fix-settings-test-error.sql",
    "fix-system-health-check.sql",
    "update-lottery-config.sql",
    
    # 状态报告文件
    "FINAL_SYSTEM_STATUS.md",
    "SYSTEM_STATUS_REPORT.md",
    "KNOWLEDGE_BASE_FIX_SUMMARY.md",
    "LOTTERY_CONFIG_FIX_SUMMARY.md",
    "REMAINING_CHANCES_FIX_SUMMARY.md",
    "PROBLEM_DIAGNOSIS_AND_SOLUTION.md",
    "PROJECT_FILES_LIST.md",
    "FIX_SUMMARY.md",
    
    # 部署相关重复文件
    "deploy-production.html",
    "deploy-to-github.html",
    "GITHUB_DEPLOYMENT_GUIDE.md",
    "PRODUCTION_DEPLOYMENT_GUIDE.md",
    
    # 验证页面
    "supabase-connection-validator.html",
    "system-ready-check.html",
    "system-status.html",
    "full-system-test.html"
)

# 统计信息
$deletedCount = 0
$backedUpCount = 0
$notFoundCount = 0

Write-Host "`n🔍 开始处理文件..." -ForegroundColor Yellow

foreach ($file in $filesToDelete) {
    if (Test-Path $file) {
        try {
            # 备份文件
            Copy-Item $file $backupDir -Force
            $backedUpCount++
            
            # 删除文件
            Remove-Item $file -Force
            $deletedCount++
            
            Write-Host "✅ 已删除: $file" -ForegroundColor Green
        }
        catch {
            Write-Host "❌ 删除失败: $file - $($_.Exception.Message)" -ForegroundColor Red
        }
    }
    else {
        Write-Host "⚠️  文件不存在: $file" -ForegroundColor DarkYellow
        $notFoundCount++
    }
}

# 显示统计结果
Write-Host "`n📊 清理完成统计:" -ForegroundColor Cyan
Write-Host "✅ 成功删除: $deletedCount 个文件" -ForegroundColor Green
Write-Host "📦 已备份: $backedUpCount 个文件" -ForegroundColor Blue
Write-Host "⚠️  未找到: $notFoundCount 个文件" -ForegroundColor Yellow

# 显示保留的核心文件
Write-Host "`n📁 保留的核心文件:" -ForegroundColor Cyan
$coreFiles = @(
    "index.html",
    "admin.html", 
    "system-test.html",
    "config.js",
    "supabase-config.js",
    "supabase-connection.js",
    "ai-features.js",
    "supabase-complete-setup.sql",
    "README.md",
    "SUPABASE_SETUP.md",
    "API_SETUP.md",
    "DEPLOYMENT.md",
    "ADMIN_FEATURES_GUIDE.md",
    "AI_INTEGRATION.md",
    "SECURITY.md",
    "jsconfig.json",
    "favicon.ico",
    ".gitignore"
)

foreach ($file in $coreFiles) {
    if (Test-Path $file) {
        Write-Host "✅ $file" -ForegroundColor Green
    }
    else {
        Write-Host "❌ $file (缺失)" -ForegroundColor Red
    }
}

Write-Host "`n🎉 项目文件清理完成！" -ForegroundColor Green
Write-Host "📦 备份文件保存在: $backupDir" -ForegroundColor Blue
Write-Host "🚀 现在可以启动项目了！" -ForegroundColor Yellow

# 询问是否要启动项目
$startProject = Read-Host "`n是否要启动项目？(y/n)"
if ($startProject -eq 'y' -or $startProject -eq 'Y') {
    Write-Host "🚀 启动项目..." -ForegroundColor Green
    
    # 尝试使用不同的方法启动
    if (Get-Command python -ErrorAction SilentlyContinue) {
        Write-Host "使用 Python HTTP Server 启动..." -ForegroundColor Cyan
        Start-Process python -ArgumentList "-m", "http.server", "8000" -WorkingDirectory (Get-Location)
        Write-Host "🌐 项目已启动: http://localhost:8000" -ForegroundColor Green
    }
    elseif (Get-Command node -ErrorAction SilentlyContinue) {
        Write-Host "使用 Node.js HTTP Server 启动..." -ForegroundColor Cyan
        Start-Process npx -ArgumentList "http-server", "-p", "8000" -WorkingDirectory (Get-Location)
        Write-Host "🌐 项目已启动: http://localhost:8000" -ForegroundColor Green
    }
    else {
        Write-Host "⚠️  未找到 Python 或 Node.js，请手动启动项目" -ForegroundColor Yellow
        Write-Host "建议使用 VS Code Live Server 扩展" -ForegroundColor Cyan
    }
}

Write-Host "`n✨ 清理脚本执行完成！" -ForegroundColor Magenta