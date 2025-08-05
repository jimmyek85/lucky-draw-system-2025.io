-- 修复remaining_chances字段问题
-- 确保users表中有remaining_chances字段
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS remaining_chances INTEGER DEFAULT 3;

-- 同步现有的drawchances字段到remaining_chances
UPDATE users SET remaining_chances = drawchances WHERE drawchances IS NOT NULL;

-- 确保draw_count字段存在
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS draw_count INTEGER DEFAULT 0;

-- 创建settings表（如果不存在）用于存储内容管理数据
CREATE TABLE IF NOT EXISTS settings (
    key VARCHAR(255) PRIMARY KEY,
    value TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 插入默认的内容管理数据
INSERT INTO settings (key, value) VALUES
('terms_conditions', '领奖条款与条件内容将在这里显示') 
ON CONFLICT (key) DO NOTHING;

INSERT INTO settings (key, value) VALUES
('promotion_content', '🎉🎉🎉特价优惠🎉🎉🎉\n（周一至周四） monday to thursday：\n消费满55令吉以上(以一张单据为准)可以8令吉优惠价购得660ml瓶装精酿啤酒 (只限3瓶)\nSpend RM55 or more (based on one receipt), you can purchase ~660ml bottles of craft beer~ at a discounted price of RM8 (limited to 3 bottles)') 
ON CONFLICT (key) DO NOTHING;

-- 更新分享内容
INSERT INTO settings (key, value) VALUES
('share_content', '🎉 1602手工精酿邀请您参加2025年古晋美食节！🍻\n\n快来我们的档口品尝新鲜出炉的鲜啤酒！现场分享此消息，即可额外获赠RM2代金券，还能参与我们的幸运轮盘大抽奖活动！🎁\n\n人人有机会，好酒好礼有惊喜！1602在古晋美食节档口等着您的光临!\n如今特价优惠！周一到周四来喝酒超级优惠而且更划算！！！\n\n🎉 1602 Craft Beer invites you to the 2025 Kuching Food Festival! 🍻\n\nCome to our booth to taste freshly brewed craft beer! Share this message on-site to receive an additional RM2 voucher and participate in our lucky wheel draw! 🎁\n\nEveryone has a chance to win great prizes! 1602 is waiting for you at the Kuching Food Festival booth!\nSpecial promotion now! Super discounts and great value when you come for drinks Monday to Thursday!!!') 
ON CONFLICT (key) DO NOTHING;

-- 启用行级安全策略 (RLS)
ALTER TABLE settings ENABLE ROW LEVEL SECURITY;

-- 创建安全策略（允许匿名读取，但需要认证才能写入）
CREATE POLICY "Allow anonymous read access" ON settings FOR SELECT USING (true);

-- 完成设置
SELECT 'Database fix for remaining_chances completed successfully!' as status;