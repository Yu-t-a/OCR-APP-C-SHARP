-- ============================================
-- Test Seed Data for init_auth_api.sql
-- For development/testing ONLY
-- DO NOT run in production
-- Run order: init.sql -> init_auth_api.sql -> seed_test_data.sql
-- ============================================

USE TyphoonOcrDB;
GO

-- ============================================
-- CLEANUP (uncomment to reset test data)
-- ============================================
-- DELETE FROM UserActivityLog;
-- DELETE FROM EmailVerificationLogs;
-- DELETE FROM IpBlacklist;
-- DELETE FROM IpWhitelist;
-- DELETE FROM BackupCodes;
-- DELETE FROM TwoFactorSecrets;
-- DELETE FROM NotificationSettings;
-- DELETE FROM UserSettings;
-- DELETE FROM Sessions;
-- DELETE FROM PasswordResetTokens;
-- DELETE FROM ApiUsage;
-- DELETE FROM ApiKeys;
-- DELETE FROM AuditLog;
-- DELETE FROM RefreshTokens;
-- DELETE FROM UserRoles WHERE AssignedBy IN ('11111111-1111-1111-1111-111111111111');
-- DELETE FROM UserRegistrations;
-- DELETE FROM Users WHERE Email LIKE '%@test.com';
-- GO

-- ============================================
-- Declare Test GUIDs (fixed for reproducibility)
-- ============================================
DECLARE @AdminId      UNIQUEIDENTIFIER = '11111111-1111-1111-1111-111111111111';
DECLARE @UserId       UNIQUEIDENTIFIER = '22222222-2222-2222-2222-222222222222';
DECLARE @ReadOnlyId   UNIQUEIDENTIFIER = '33333333-3333-3333-3333-333333333333';
DECLARE @ApiUserId    UNIQUEIDENTIFIER = '44444444-4444-4444-4444-444444444444';

DECLARE @ApiKey1Id    UNIQUEIDENTIFIER = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
DECLARE @ApiKey2Id    UNIQUEIDENTIFIER = 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb';
DECLARE @ApiKey3Id    UNIQUEIDENTIFIER = 'cccccccc-cccc-cccc-cccc-cccccccccccc';

-- ============================================
-- 1. Users
-- NOTE: PasswordHash & Salt should be real PBKDF2/bcrypt values in practice
-- ============================================
PRINT '>>> Inserting Users...';

INSERT INTO Users (Id, Email, Username, PasswordHash, Salt, DisplayName, IsActive, IsEmailVerified, LastLoginAt, FailedLoginCount)
VALUES
    (@AdminId,    'admin@test.com',    'admin',    'PBKDF2$SHA256$10000$SALT_ADMIN$HASH_ADMIN_PLACEHOLDER',    'SALT_ADMIN_01',    'Admin User',     1, 1, GETUTCDATE(),                        0),
    (@UserId,     'user@test.com',     'testuser', 'PBKDF2$SHA256$10000$SALT_USER$HASH_USER_PLACEHOLDER',      'SALT_USER_01',     'Test User',      1, 1, DATEADD(HOUR, -2, GETUTCDATE()),     0),
    (@ReadOnlyId, 'readonly@test.com', 'readonly', 'PBKDF2$SHA256$10000$SALT_RDONLY$HASH_RDONLY_PLACEHOLDER',  'SALT_READONLY_01', 'Read Only User', 1, 1, DATEADD(DAY, -1, GETUTCDATE()),      0),
    (@ApiUserId,  'apiuser@test.com',  'apiuser',  'PBKDF2$SHA256$10000$SALT_APIUSR$HASH_APIUSR_PLACEHOLDER',  'SALT_APIUSER_01',  'API User',       1, 1, DATEADD(MINUTE, -30, GETUTCDATE()),  0);

-- ============================================
-- 2. UserRegistrations (pending verification)
-- ============================================
PRINT '>>> Inserting Pending Registrations...';

INSERT INTO UserRegistrations (Email, Username, PasswordHash, Salt, VerificationToken, IsVerified, ExpiresAt)
VALUES
    ('pending1@test.com', 'pending1', 'PBKDF2$SHA256$10000$SALT_P1$HASH_P1', 'SALT_PENDING_01', 'VERIFY_TOKEN_PENDING1_ABCDEF123456', 0, DATEADD(HOUR, 24, GETUTCDATE())),
    ('pending2@test.com', 'pending2', 'PBKDF2$SHA256$10000$SALT_P2$HASH_P2', 'SALT_PENDING_02', 'VERIFY_TOKEN_PENDING2_GHIJKL789012', 0, DATEADD(HOUR, 12, GETUTCDATE())),
    ('expired@test.com',  'expired',  'PBKDF2$SHA256$10000$SALT_EX$HASH_EX', 'SALT_EXPIRED_01', 'VERIFY_TOKEN_EXPIRED_MNOPQR345678',  0, DATEADD(HOUR, -6, GETUTCDATE()));   -- expired token

-- ============================================
-- 3. UserRoles (Roles: 1=Admin, 2=User, 3=ReadOnly, 4=ApiUser)
-- ============================================
PRINT '>>> Assigning User Roles...';

INSERT INTO UserRoles (UserId, RoleId, AssignedBy)
VALUES
    (@AdminId,    1, @AdminId),
    (@UserId,     2, @AdminId),
    (@ReadOnlyId, 3, @AdminId),
    (@ApiUserId,  4, @AdminId);

-- ============================================
-- 4. RefreshTokens
-- ============================================
PRINT '>>> Inserting Refresh Tokens...';

INSERT INTO RefreshTokens (UserId, Token, ExpiresAt, IsRevoked)
VALUES
    (@AdminId,    'RT_ADMIN_ACTIVE_ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890AABB',  DATEADD(DAY, 7, GETUTCDATE()),  0),
    (@UserId,     'RT_USER_ACTIVE_QRSTUVWXYZ0987654321ABCDEFGHIJKLMNOPQRST',   DATEADD(DAY, 7, GETUTCDATE()),  0),
    (@UserId,     'RT_USER_REVOKED_ZZZZZZZZZZZZZ1111111111AAAAAAAAAAAABBBBB',  DATEADD(DAY, -1, GETUTCDATE()), 1),   -- revoked
    (@ApiUserId,  'RT_APIUSER_ACTIVE_LMNOPQRSTUVWXYZ123456789ABCDEFGHIJKLM',   DATEADD(DAY, 30, GETUTCDATE()), 0);

-- ============================================
-- 5. ApiKeys
-- ============================================
PRINT '>>> Inserting API Keys...';

INSERT INTO ApiKeys (Id, UserId, KeyName, KeyValue, KeyPrefix, IsActive, ExpiresAt, RateLimitPerHour, RateLimitPerDay, RateLimitPerMonth, Description)
VALUES
    (@ApiKey1Id, @ApiUserId, 'Production Key',   'sk_live_HASHED_PRODUCTION_KEY_VALUE_ABCDEFGHIJKLMNOPQRST', 'sk_live_', 1, DATEADD(YEAR, 1, GETUTCDATE()),  1000, 10000, 100000, 'Main production API key'),
    (@ApiKey2Id, @AdminId,   'Admin Debug Key',  'sk_test_HASHED_ADMIN_DEBUG_KEY_VALUE_PQRSTUVWXYZ12345678', 'sk_test_', 1, NULL,                             100,  1000,  10000,  'Admin debug key - no expiry'),
    (@ApiKey3Id, @UserId,    'Dev Sandbox Key',  'sk_test_HASHED_DEV_SANDBOX_KEY_VALUE_UVWXYZ1234567890AB',  'sk_test_', 1, DATEADD(MONTH, 1, GETUTCDATE()),  50,   500,   5000,   'Dev sandbox key'),
    (NEWID(),    @ApiUserId, 'Expired Key',      'sk_live_HASHED_EXPIRED_KEY_VALUE_CDEFGHIJKLMNOPQRSTU123',  'sk_live_', 0, DATEADD(DAY, -1, GETUTCDATE()),   100,  1000,  10000,  'Expired inactive key');

-- ============================================
-- 6. ApiUsage
-- ============================================
PRINT '>>> Inserting API Usage Logs...';

INSERT INTO ApiUsage (ApiKeyId, UserId, Endpoint, HttpMethod, RequestedAt, ResponseStatus, ProcessingTimeMs, RequestSizeBytes, ResponseSizeBytes, IpAddress, UserAgent)
VALUES
    (@ApiKey1Id, @ApiUserId, '/api/v1/app/process',  'POST', DATEADD(MINUTE, -30, GETUTCDATE()), 200, 1250, 2048, 5120, '192.168.1.100', 'MyApp/1.0.0 (iOS 17)'),
    (@ApiKey1Id, @ApiUserId, '/api/v1/app/results',  'GET',  DATEADD(MINUTE, -28, GETUTCDATE()), 200, 85,   256,  8192, '192.168.1.100', 'MyApp/1.0.0 (iOS 17)'),
    (@ApiKey1Id, @ApiUserId, '/api/v1/app/process',  'POST', DATEADD(MINUTE, -20, GETUTCDATE()), 200, 1100, 3072, 6144, '10.0.0.50',     'MyApp/2.0.0 (Android 14)'),
    (@ApiKey1Id, @ApiUserId, '/api/v1/app/process',  'POST', DATEADD(MINUTE, -15, GETUTCDATE()), 422, 45,   2048, 512,  '10.0.0.50',     'MyApp/2.0.0 (Android 14)'),
    (@ApiKey2Id, @AdminId,   '/api/v1/admin/users',  'GET',  DATEADD(MINUTE, -10, GETUTCDATE()), 200, 120,  128,  4096, '127.0.0.1',     'curl/7.88.1'),
    (@ApiKey2Id, @AdminId,   '/api/v1/admin/keys',   'GET',  DATEADD(MINUTE, -8,  GETUTCDATE()), 200, 95,   128,  2048, '127.0.0.1',     'curl/7.88.1'),
    (@ApiKey3Id, @UserId,    '/api/v1/app/results',  'GET',  DATEADD(MINUTE, -5,  GETUTCDATE()), 200, 70,   128,  3072, '203.0.113.10',  'PostmanRuntime/7.32.0'),
    (@ApiKey1Id, @ApiUserId, '/api/v1/app/results',  'GET',  DATEADD(MINUTE, -2,  GETUTCDATE()), 429, 5,    128,  256,  '1.2.3.4',       'bot/1.0'),              -- rate limited
    (@ApiKey1Id, @ApiUserId, '/api/v1/app/validate', 'POST', DATEADD(MINUTE, -1,  GETUTCDATE()), 401, 3,    512,  256,  '5.6.7.8',       'unknown/0.0');         -- unauthorized

-- ============================================
-- 7. Sessions
-- ============================================
PRINT '>>> Inserting Sessions...';

INSERT INTO Sessions (Id, UserId, IpAddress, UserAgent, ExpiresAt, LastActivityAt)
VALUES
    ('sess_admin_01_abcdefghijklmnopqrstuvwxyz12345678',   @AdminId,    '192.168.1.1',   'Mozilla/5.0 (Windows NT 10.0; Win64) Chrome/120.0',  DATEADD(HOUR, 8, GETUTCDATE()),  GETUTCDATE()),
    ('sess_user_01_abcdefghijklmnopqrstuvwxyz901234567',   @UserId,     '203.0.113.10',  'Mozilla/5.0 (Macintosh; Intel Mac) Firefox/121.0',   DATEADD(HOUR, 4, GETUTCDATE()),  DATEADD(MINUTE, -15, GETUTCDATE())),
    ('sess_user_02_expired_zzzzzzzzzzzzzzzzzzzzzzzz999',   @UserId,     '203.0.113.10',  'Mozilla/5.0 (Macintosh; Intel Mac) Firefox/121.0',   DATEADD(DAY, -1, GETUTCDATE()),  DATEADD(DAY, -1, GETUTCDATE())),   -- expired
    ('sess_apiuser_01_abcdefghijklmnopqrstuvwxyz00000',    @ApiUserId,  '10.0.0.1',      'MyApp/1.0.0 (production)',                           DATEADD(HOUR, 12, GETUTCDATE()), DATEADD(MINUTE, -5, GETUTCDATE())),
    ('sess_readonly_01_abcdefghijklmnopqrstuvwxyz11111',   @ReadOnlyId, '10.0.1.5',      'Mozilla/5.0 (iPhone; CPU iPhone OS 17) Safari/17.0', DATEADD(HOUR, 2, GETUTCDATE()),  DATEADD(MINUTE, -30, GETUTCDATE()));

-- ============================================
-- 8. PasswordResetTokens
-- ============================================
PRINT '>>> Inserting Password Reset Tokens...';

INSERT INTO PasswordResetTokens (UserId, Token, ExpiresAt, IsUsed)
VALUES
    (@UserId,     'RESET_TOKEN_ACTIVE_USER_ABCDEFGHIJKLMN0123456789XYZ',   DATEADD(HOUR, 1,  GETUTCDATE()),  0),    -- active
    (@ReadOnlyId, 'RESET_TOKEN_USED_READONLY_PQRSTUVWXYZ0987654321ABC',    DATEADD(HOUR, -2, GETUTCDATE()),  1),    -- already used
    (@AdminId,    'RESET_TOKEN_EXPIRED_ADMIN_ZZZAAA111BBB222CCC333DDD4',   DATEADD(HOUR, -5, GETUTCDATE()),  0);    -- expired

-- ============================================
-- 9. UserSettings
-- ============================================
PRINT '>>> Inserting User Settings...';

INSERT INTO UserSettings (UserId, SettingKey, SettingValue)
VALUES
    (@AdminId,    'language',        'th'),
    (@AdminId,    'timezone',        'Asia/Bangkok'),
    (@AdminId,    'theme',           'dark'),
    (@AdminId,    'items_per_page',  '50'),
    (@UserId,     'language',        'en'),
    (@UserId,     'timezone',        'UTC'),
    (@UserId,     'theme',           'light'),
    (@UserId,     'items_per_page',  '20'),
    (@UserId,     'date_format',     'YYYY-MM-DD'),
    (@ReadOnlyId, 'language',        'th'),
    (@ReadOnlyId, 'timezone',        'Asia/Bangkok'),
    (@ReadOnlyId, 'theme',           'light'),
    (@ApiUserId,  'language',        'en'),
    (@ApiUserId,  'timezone',        'UTC');

-- ============================================
-- 10. NotificationSettings (via SP for default values)
-- ============================================
PRINT '>>> Inserting Notification Settings...';

EXEC sp_CreateDefaultNotificationSettings @AdminId;
EXEC sp_CreateDefaultNotificationSettings @UserId;
EXEC sp_CreateDefaultNotificationSettings @ReadOnlyId;
EXEC sp_CreateDefaultNotificationSettings @ApiUserId;

-- Override: Admin wants email on every login
UPDATE NotificationSettings
SET EmailEnabled = 1, PushEnabled = 1
WHERE UserId = @AdminId AND EventType = 'LOGIN_SUCCESS';

-- Override: API User wants SMS on rate limit exceeded
UPDATE NotificationSettings
SET SmsEnabled = 1
WHERE UserId = @ApiUserId AND EventType = 'RATE_LIMIT_EXCEEDED';

-- ============================================
-- 11. TwoFactorSecrets
-- ============================================
PRINT '>>> Inserting 2FA Secrets...';

INSERT INTO TwoFactorSecrets (UserId, Secret, IsEnabled, EnabledAt)
VALUES
    (@AdminId,   'TOTP_BASE32_SECRET_ADMIN_JBSWY3DPEHPK3PXPJBSWY3D',   1, DATEADD(DAY, -30, GETUTCDATE())),  -- enabled
    (@UserId,    'TOTP_BASE32_SECRET_USER_JBSWY3DPEHPK3PXQJBSWY3E',    0, NULL),                              -- setup but not enabled
    (@ApiUserId, 'TOTP_BASE32_SECRET_APIUSR_JBSWY3DPEHPK3PXRJBSWY3F', 1, DATEADD(DAY, -7,  GETUTCDATE()));  -- enabled

-- ============================================
-- 12. BackupCodes
-- ============================================
PRINT '>>> Inserting 2FA Backup Codes...';

INSERT INTO BackupCodes (UserId, Code, IsUsed, UsedAt)
VALUES
    (@AdminId,   'BACK-A1B2-C3D4', 0, NULL),
    (@AdminId,   'BACK-E5F6-G7H8', 0, NULL),
    (@AdminId,   'BACK-I9J0-K1L2', 0, NULL),
    (@AdminId,   'BACK-M3N4-O5P6', 0, NULL),
    (@AdminId,   'BACK-Q7R8-S9T0', 0, NULL),
    (@AdminId,   'BACK-USED-1111', 1, DATEADD(DAY, -5, GETUTCDATE())),     -- used code
    (@ApiUserId, 'BACK-Y5Z6-A7B8', 0, NULL),
    (@ApiUserId, 'BACK-C9D0-E1F2', 0, NULL),
    (@ApiUserId, 'BACK-G3H4-I5J6', 0, NULL),
    (@ApiUserId, 'BACK-K7L8-M9N0', 0, NULL),
    (@ApiUserId, 'BACK-O1P2-Q3R4', 0, NULL);

-- ============================================
-- 13. EmailVerificationLogs
-- ============================================
PRINT '>>> Inserting Email Verification Logs...';

INSERT INTO EmailVerificationLogs (UserId, Email, EmailType, Token, IsVerified, VerifiedAt, IpAddress)
VALUES
    (@AdminId,    'admin@test.com',    'VERIFICATION',   'EVTOKEN_ADMIN_VERIFIED_001',    1, DATEADD(DAY, -60, GETUTCDATE()), '192.168.1.1'),
    (@UserId,     'user@test.com',     'VERIFICATION',   'EVTOKEN_USER_VERIFIED_001',     1, DATEADD(DAY, -30, GETUTCDATE()), '203.0.113.10'),
    (@UserId,     'user@test.com',     'PASSWORD_RESET', 'EVTOKEN_USER_PWRESET_001',      1, DATEADD(DAY, -5,  GETUTCDATE()), '203.0.113.10'),
    (@ReadOnlyId, 'readonly@test.com', 'VERIFICATION',   'EVTOKEN_READONLY_VERIFIED_001', 1, DATEADD(DAY, -15, GETUTCDATE()), '10.0.1.5'),
    (@ApiUserId,  'apiuser@test.com',  'VERIFICATION',   'EVTOKEN_APIUSER_VERIFIED_001',  1, DATEADD(DAY, -20, GETUTCDATE()), '10.0.0.1'),
    (@ApiUserId,  'apiuser@test.com',  '2FA',            'EVTOKEN_APIUSER_2FA_001',       1, DATEADD(DAY, -7,  GETUTCDATE()), '10.0.0.1'),
    (NULL,        'pending1@test.com', 'VERIFICATION',   'EVTOKEN_PENDING1_001',          0, NULL,                            '172.16.0.1');  -- pending

-- ============================================
-- 14. IpWhitelist
-- ============================================
PRINT '>>> Inserting IP Whitelist...';

INSERT INTO IpWhitelist (ApiKeyId, IpAddress, Description, CreatedBy)
VALUES
    (@ApiKey1Id, '192.168.1.0/24', 'Office network range',      @AdminId),
    (@ApiKey1Id, '10.0.0.50',      'Production server',         @AdminId),
    (@ApiKey1Id, '10.0.0.51',      'Production server backup',  @AdminId),
    (@ApiKey2Id, '127.0.0.1',      'Localhost admin access',    @AdminId),
    (@ApiKey3Id, '203.0.113.10',   'Developer workstation',     @AdminId);

-- ============================================
-- 15. IpBlacklist
-- ============================================
PRINT '>>> Inserting IP Blacklist...';

INSERT INTO IpBlacklist (IpAddress, Reason, CreatedBy, IsActive)
VALUES
    ('1.2.3.4',     'Brute force login attempts - blocked permanently', @AdminId, 1),
    ('5.6.7.8',     'Suspicious bot activity - scraping endpoints',     @AdminId, 1),
    ('9.10.11.12',  'Known malicious IP - third party threat feed',     @AdminId, 1),
    ('13.14.15.16', 'Temporary block - rate abuse',                     @AdminId, 0);  -- inactive

-- ============================================
-- 16. AuditLog
-- ============================================
PRINT '>>> Inserting Audit Logs...';

INSERT INTO AuditLog (UserId, Action, EntityType, EntityId, OldValues, NewValues, IpAddress, UserAgent)
VALUES
    (@AdminId,   'USER_LOGIN',        'User',       CAST(@AdminId AS NVARCHAR(100)),    NULL,
        N'{"loginAt":"' + CONVERT(NVARCHAR, GETUTCDATE(), 126) + N'","method":"password"}',
        '192.168.1.1',  'Mozilla/5.0 Chrome/120.0'),

    (@AdminId,   'API_KEY_CREATED',   'ApiKey',     CAST(@ApiKey1Id AS NVARCHAR(100)),  NULL,
        N'{"keyName":"Production Key","rateLimitPerHour":1000}',
        '192.168.1.1',  'Mozilla/5.0 Chrome/120.0'),

    (@AdminId,   'ROLE_ASSIGNED',     'UserRoles',  CAST(@UserId AS NVARCHAR(100)),     NULL,
        N'{"userId":"22222222-2222-2222-2222-222222222222","roleId":2,"roleName":"User"}',
        '192.168.1.1',  'Mozilla/5.0 Chrome/120.0'),

    (@UserId,    'USER_LOGIN',        'User',       CAST(@UserId AS NVARCHAR(100)),     NULL,
        N'{"loginAt":"' + CONVERT(NVARCHAR, DATEADD(HOUR, -2, GETUTCDATE()), 126) + N'","method":"password"}',
        '203.0.113.10', 'Mozilla/5.0 Firefox/121.0'),

    (@UserId,    'PASSWORD_CHANGED',  'User',       CAST(@UserId AS NVARCHAR(100)),
        N'{"changedAt":"previous"}',
        N'{"changedAt":"' + CONVERT(NVARCHAR, DATEADD(DAY, -5, GETUTCDATE()), 126) + N'"}',
        '203.0.113.10', 'Mozilla/5.0 Firefox/121.0'),

    (@AdminId,   'IP_BLACKLISTED',    'IpBlacklist','1.2.3.4',                          NULL,
        N'{"ip":"1.2.3.4","reason":"Brute force login attempts"}',
        '192.168.1.1',  'Mozilla/5.0 Chrome/120.0'),

    (@AdminId,   '2FA_ENABLED',       'User',       CAST(@AdminId AS NVARCHAR(100)),    NULL,
        N'{"method":"TOTP","enabledAt":"' + CONVERT(NVARCHAR, DATEADD(DAY, -30, GETUTCDATE()), 126) + N'"}',
        '192.168.1.1',  'Mozilla/5.0 Chrome/120.0'),

    (NULL,       'LOGIN_FAILED',      'User',       'unknown@evil.com',                 NULL,
        N'{"email":"unknown@evil.com","attempts":5,"ip":"1.2.3.4"}',
        '1.2.3.4',      'curl/7.88.1');

-- ============================================
-- 17. UserActivityLog
-- ============================================
PRINT '>>> Inserting User Activity Logs...';

INSERT INTO UserActivityLog (UserId, ActivityType, Description, Metadata, IpAddress, UserAgent)
VALUES
    (@AdminId,    'LOGIN',          'Admin logged in',                      N'{"method":"password","2fa":true}',             '192.168.1.1',   'Mozilla/5.0 Chrome/120.0'),
    (@AdminId,    'PAGE_VIEW',      'Viewed user management page',          N'{"page":"/admin/users","duration":15}',         '192.168.1.1',   'Mozilla/5.0 Chrome/120.0'),
    (@AdminId,    'API_KEY_CREATE', 'Created Production API key',           N'{"keyName":"Production Key"}',                  '192.168.1.1',   'Mozilla/5.0 Chrome/120.0'),
    (@AdminId,    'IP_BLACKLIST',   'Blacklisted IP address',               N'{"ip":"1.2.3.4"}',                              '192.168.1.1',   'Mozilla/5.0 Chrome/120.0'),
    (@UserId,     'LOGIN',          'User logged in',                       N'{"method":"password","2fa":false}',             '203.0.113.10',  'Mozilla/5.0 Firefox/121.0'),
    (@UserId,     'PAGE_VIEW',      'Viewed dashboard',                     N'{"page":"/dashboard","duration":45}',           '203.0.113.10',  'Mozilla/5.0 Firefox/121.0'),
    (@UserId,     'PASSWORD_CHANGE','Changed account password',             N'{"trigger":"user_initiated"}',                  '203.0.113.10',  'Mozilla/5.0 Firefox/121.0'),
    (@UserId,     'LOGOUT',         'User logged out',                      N'{"sessionDuration":3600}',                      '203.0.113.10',  'Mozilla/5.0 Firefox/121.0'),
    (@ApiUserId,  'LOGIN',          'API user logged in via API key',       N'{"method":"api_key","keyPrefix":"sk_live_"}',   '10.0.0.1',      'MyApp/1.0.0'),
    (@ApiUserId,  'API_CALL',       'API call to process endpoint',         N'{"endpoint":"/api/v1/app/process","status":200}','10.0.0.1',     'MyApp/1.0.0'),
    (@ReadOnlyId, 'LOGIN',          'Readonly user logged in',              N'{"method":"password","2fa":false}',             '10.0.1.5',      'Mozilla/5.0 Safari/17.0'),
    (@ReadOnlyId, 'PAGE_VIEW',      'Viewed reports page',                  N'{"page":"/reports","duration":120}',            '10.0.1.5',      'Mozilla/5.0 Safari/17.0'),
    (NULL,        'LOGIN_FAILED',   'Failed login - unknown user',          N'{"email":"hacker@evil.com","attempts":5}',      '1.2.3.4',       'curl/7.88.1');

PRINT '========================================';
PRINT 'Test Seed Data Inserted Successfully!';
PRINT '========================================';
PRINT 'Users: admin@test.com (Admin)';
PRINT '       user@test.com (User)';
PRINT '       readonly@test.com (ReadOnly)';
PRINT '       apiuser@test.com (ApiUser)';
PRINT 'Pending: pending1@test.com, pending2@test.com';
PRINT 'Expired: expired@test.com';
PRINT '========================================';
PRINT 'API Keys: Production, Admin Debug, Dev Sandbox, Expired';
PRINT 'IP Blacklist: 1.2.3.4, 5.6.7.8, 9.10.11.12, 13.14.15.16';
PRINT '========================================';
GO
