-- 更新抽奖配置脚本
-- 确保新用户只能免费抽奖一次

-- 1. 确保 remaining_chances 字段存在且默认值为 1
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS remaining_chances INTEGER DEFAULT 1;

-- 2. 更新现有的 drawchances 字段默认值为 1
ALTER TABLE users 
ALTER COLUMN drawchances SET DEFAULT 1;

-- 3. 同步现有用户的 drawchances 到 remaining_chances（如果 remaining_chances 为空）
UPDATE users 
SET remaining_chances = COALESCE(remaining_chances, drawchances, 1) 
WHERE remaining_chances IS NULL;

-- 4. 插入或更新抽奖配置到 settings 表
INSERT INTO settings (key, value, description, category, is_active) VALUES
('lottery_config', '{"INITIAL_CHANCES":1,"SPIN_AGAIN_BONUS":1,"MAX_ACCUMULATED_CHANCES":10,"DAILY_FREE_CHANCES":1,"ENABLE_DAILY_FREE":false,"ALLOW_ADMIN_ADD_CHANCES":true}', '抽奖机会配置', 'game', true)
ON CONFLICT (key) DO UPDATE SET
    value = EXCLUDED.value,
    updated_at = NOW();

-- 5. 确保 settings 表存在必要的字段
ALTER TABLE settings 
ADD COLUMN IF NOT EXISTS description TEXT,
ADD COLUMN IF NOT EXISTS category TEXT DEFAULT 'general',
ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT true;

-- 6. 创建索引以提高查询性能
CREATE INDEX IF NOT EXISTS idx_users_remaining_chances ON users(remaining_chances);
CREATE INDEX IF NOT EXISTS idx_settings_key_category ON settings(key, category);

-- 7. 显示更新结果
SELECT 
    'lottery_config' as setting_key,
    value as current_config,
    'Updated successfully' as status
FROM settings 
WHERE key = 'lottery_config';

-- 8. 显示用户统计
SELECT 
    COUNT(*) as total_users,
    COUNT(CASE WHEN remaining_chances = 1 THEN 1 END) as users_with_1_chance,
    COUNT(CASE WHEN remaining_chances > 1 THEN 1 END) as users_with_multiple_chances,
    AVG(remaining_chances) as avg_remaining_chances
FROM users;

-- 完成提示
SELECT '✅ 抽奖配置更新完成！新用户将只获得1次免费抽奖机会。' as message;