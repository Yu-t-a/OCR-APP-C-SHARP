-- ============================================
-- Authentication, Authorization & API Management
-- Generic Database Schema Template
-- Suitable for any application type
-- ============================================

USE TyphoonOcrDB;
GO

-- ===== Authentication Tables =====

-- Users Table - Store user account information
CREATE TABLE Users (
    Id              UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWSEQUENTIALID(),
    Email           NVARCHAR(255) NOT NULL UNIQUE,
    Username        NVARCHAR(100) NOT NULL UNIQUE,
    PasswordHash    NVARCHAR(500) NOT NULL,
    Salt            NVARCHAR(100) NOT NULL,
    DisplayName     NVARCHAR(200),
    IsActive        BIT DEFAULT 1,
    IsEmailVerified BIT DEFAULT 0,
    CreatedAt       DATETIME2 DEFAULT GETUTCDATE(),
    UpdatedAt       DATETIME2 DEFAULT GETUTCDATE(),
    LastLoginAt     DATETIME2,
    FailedLoginCount INT DEFAULT 0,
    LockUntil       DATETIME2 NULL
);

-- UserRegistrations Table - Store pending user registrations
CREATE TABLE UserRegistrations (
    Id                  UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWSEQUENTIALID(),
    Email               NVARCHAR(255) NOT NULL UNIQUE,
    Username            NVARCHAR(100) NOT NULL UNIQUE,
    PasswordHash        NVARCHAR(500) NOT NULL,
    Salt                NVARCHAR(100) NOT NULL,
    VerificationToken   NVARCHAR(500) NOT NULL UNIQUE,
    IsVerified          BIT DEFAULT 0,
    CreatedAt           DATETIME2 DEFAULT GETUTCDATE(),
    ExpiresAt           DATETIME2 NOT NULL,
    VerifiedAt          DATETIME2 NULL,
    VerifiedBy          UNIQUEIDENTIFIER NULL REFERENCES Users(Id) ON DELETE SET NULL
);

-- RefreshTokens Table - Store JWT refresh tokens
CREATE TABLE RefreshTokens (
    Id          UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWSEQUENTIALID(),
    UserId      UNIQUEIDENTIFIER NOT NULL REFERENCES Users(Id) ON DELETE CASCADE,
    Token       NVARCHAR(500) NOT NULL UNIQUE,
    ExpiresAt   DATETIME2 NOT NULL,
    CreatedAt   DATETIME2 DEFAULT GETUTCDATE(),
    IsRevoked   BIT DEFAULT 0,
    RevokedAt   DATETIME2 NULL,
    RevokedBy   UNIQUEIDENTIFIER NULL REFERENCES Users(Id)
);

-- ===== Authorization Tables =====

-- Roles Table - Define user roles
CREATE TABLE Roles (
    Id          INT PRIMARY KEY IDENTITY(1,1),
    RoleName    NVARCHAR(50) NOT NULL UNIQUE,
    Description NVARCHAR(255),
    CreatedAt   DATETIME2 DEFAULT GETUTCDATE(),
    IsActive    BIT DEFAULT 1
);

-- Permissions Table - Define system permissions
CREATE TABLE Permissions (
    Id              INT PRIMARY KEY IDENTITY(1,1),
    PermissionName  NVARCHAR(100) NOT NULL UNIQUE,
    Description     NVARCHAR(255),
    Module          NVARCHAR(50),  -- 'app', 'user', 'apikey', etc.
    CreatedAt       DATETIME2 DEFAULT GETUTCDATE()
);

-- UserRoles Table - Many-to-Many relationship between Users and Roles
CREATE TABLE UserRoles (
    UserId      UNIQUEIDENTIFIER NOT NULL REFERENCES Users(Id) ON DELETE CASCADE,
    RoleId      INT NOT NULL REFERENCES Roles(Id) ON DELETE CASCADE,
    AssignedAt  DATETIME2 DEFAULT GETUTCDATE(),
    AssignedBy  UNIQUEIDENTIFIER NULL REFERENCES Users(Id),
    PRIMARY KEY (UserId, RoleId)
);

-- RolePermissions Table - Many-to-Many relationship between Roles and Permissions
CREATE TABLE RolePermissions (
    RoleId          INT NOT NULL REFERENCES Roles(Id) ON DELETE CASCADE,
    PermissionId    INT NOT NULL REFERENCES Permissions(Id) ON DELETE CASCADE,
    GrantedAt       DATETIME2 DEFAULT GETUTCDATE(),
    GrantedBy       UNIQUEIDENTIFIER NULL REFERENCES Users(Id) ON DELETE SET NULL,
    PRIMARY KEY (RoleId, PermissionId)
);

-- ===== API Key Management Tables =====

-- ApiKeys Table - Store API keys for external access
CREATE TABLE ApiKeys (
    Id                  UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWSEQUENTIALID(),
    UserId              UNIQUEIDENTIFIER NOT NULL REFERENCES Users(Id) ON DELETE CASCADE,
    KeyName             NVARCHAR(100) NOT NULL,
    KeyValue            NVARCHAR(500) NOT NULL UNIQUE,  -- Hashed API key
    KeyPrefix           NVARCHAR(20) NOT NULL,         -- First 8 chars for display
    IsActive            BIT DEFAULT 1,
    ExpiresAt           DATETIME2 NULL,
    RateLimitPerHour    INT DEFAULT 100,
    RateLimitPerDay     INT DEFAULT 1000,
    RateLimitPerMonth   INT DEFAULT 10000,
    CreatedAt           DATETIME2 DEFAULT GETUTCDATE(),
    LastUsedAt          DATETIME2,
    UsageCount          BIGINT DEFAULT 0,
    Description         NVARCHAR(500)
);

-- ApiUsage Table - Track API usage for rate limiting and analytics
CREATE TABLE ApiUsage (
    Id              BIGINT PRIMARY KEY IDENTITY(1,1),
    ApiKeyId        UNIQUEIDENTIFIER NOT NULL REFERENCES ApiKeys(Id) ON DELETE CASCADE,
    UserId          UNIQUEIDENTIFIER NULL REFERENCES Users(Id),
    Endpoint        NVARCHAR(255) NOT NULL,
    HttpMethod      NVARCHAR(10) NOT NULL,  -- GET, POST, PUT, DELETE
    RequestedAt     DATETIME2 DEFAULT GETUTCDATE(),
    ResponseStatus  INT,
    ProcessingTimeMs INT,
    RequestSizeBytes BIGINT,
    ResponseSizeBytes BIGINT,
    IpAddress       NVARCHAR(45),
    UserAgent       NVARCHAR(500)
);

-- ===== Audit Tables =====

-- AuditLog Table - Track important system events
CREATE TABLE AuditLog (
    Id              BIGINT PRIMARY KEY IDENTITY(1,1),
    UserId          UNIQUEIDENTIFIER NULL REFERENCES Users(Id) ON DELETE SET NULL,
    Action          NVARCHAR(100) NOT NULL,  -- 'USER_LOGIN', 'API_KEY_CREATED', etc.
    EntityType      NVARCHAR(50),           -- 'User', 'ApiKey', 'Role', etc.
    EntityId        NVARCHAR(100),
    OldValues       NVARCHAR(MAX),          -- JSON
    NewValues       NVARCHAR(MAX),          -- JSON
    IpAddress       NVARCHAR(45),
    UserAgent       NVARCHAR(500),
    CreatedAt       DATETIME2 DEFAULT GETUTCDATE()
);

-- ===== Password Management Tables =====

-- PasswordResetTokens Table - Store password reset tokens
CREATE TABLE PasswordResetTokens (
    Id          UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWSEQUENTIALID(),
    UserId      UNIQUEIDENTIFIER NOT NULL REFERENCES Users(Id) ON DELETE CASCADE,
    Token       NVARCHAR(500) NOT NULL UNIQUE,
    ExpiresAt   DATETIME2 NOT NULL,
    CreatedAt   DATETIME2 DEFAULT GETUTCDATE(),
    IsUsed      BIT DEFAULT 0,
    UsedAt      DATETIME2 NULL
);

-- ===== Session Management Tables =====

-- Sessions Table - Store web sessions
CREATE TABLE Sessions (
    Id              NVARCHAR(128) PRIMARY KEY,
    UserId          UNIQUEIDENTIFIER NOT NULL REFERENCES Users(Id) ON DELETE CASCADE,
    IpAddress       NVARCHAR(45),
    UserAgent       NVARCHAR(500),
    CreatedAt       DATETIME2 DEFAULT GETUTCDATE(),
    ExpiresAt       DATETIME2 NOT NULL,
    LastActivityAt  DATETIME2 DEFAULT GETUTCDATE()
);

-- ===== User Settings Tables =====

-- UserSettings Table - Store user preferences
CREATE TABLE UserSettings (
    Id              UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWSEQUENTIALID(),
    UserId          UNIQUEIDENTIFIER NOT NULL REFERENCES Users(Id) ON DELETE CASCADE,
    SettingKey      NVARCHAR(100) NOT NULL,
    SettingValue    NVARCHAR(MAX),
    CreatedAt       DATETIME2 DEFAULT GETUTCDATE(),
    UpdatedAt       DATETIME2 DEFAULT GETUTCDATE(),
    UNIQUE (UserId, SettingKey)
);

-- NotificationSettings Table - Store per-event notification preferences
CREATE TABLE NotificationSettings (
    Id              UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWSEQUENTIALID(),
    UserId          UNIQUEIDENTIFIER NOT NULL REFERENCES Users(Id) ON DELETE CASCADE,
    EventType       NVARCHAR(100) NOT NULL,  -- 'LOGIN', 'API_KEY_EXPIRY', 'PASSWORD_CHANGED', etc.
    EmailEnabled    BIT DEFAULT 1,
    SmsEnabled      BIT DEFAULT 0,
    PushEnabled     BIT DEFAULT 0,
    InAppEnabled    BIT DEFAULT 1,
    CreatedAt       DATETIME2 DEFAULT GETUTCDATE(),
    UpdatedAt       DATETIME2 DEFAULT GETUTCDATE(),
    UNIQUE (UserId, EventType)
);

-- ===== Two-Factor Authentication Tables =====

-- TwoFactorSecrets Table - Store 2FA secrets
CREATE TABLE TwoFactorSecrets (
    Id          UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWSEQUENTIALID(),
    UserId      UNIQUEIDENTIFIER NOT NULL REFERENCES Users(Id) ON DELETE CASCADE,
    Secret      NVARCHAR(500) NOT NULL,
    IsEnabled   BIT DEFAULT 0,
    CreatedAt   DATETIME2 DEFAULT GETUTCDATE(),
    EnabledAt   DATETIME2 NULL
);

-- BackupCodes Table - Store 2FA backup codes
CREATE TABLE BackupCodes (
    Id          UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWSEQUENTIALID(),
    UserId      UNIQUEIDENTIFIER NOT NULL REFERENCES Users(Id) ON DELETE CASCADE,
    Code        NVARCHAR(20) NOT NULL,
    IsUsed      BIT DEFAULT 0,
    UsedAt      DATETIME2 NULL,
    CreatedAt   DATETIME2 DEFAULT GETUTCDATE()
);

-- ===== Email Management Tables =====

-- EmailVerificationLogs Table - Log email sending attempts
CREATE TABLE EmailVerificationLogs (
    Id              BIGINT PRIMARY KEY IDENTITY(1,1),
    UserId          UNIQUEIDENTIFIER NULL REFERENCES Users(Id) ON DELETE SET NULL,
    Email           NVARCHAR(255) NOT NULL,
    EmailType       NVARCHAR(50) NOT NULL,  -- 'VERIFICATION', 'PASSWORD_RESET', '2FA'
    Token           NVARCHAR(500) NOT NULL,
    SentAt          DATETIME2 DEFAULT GETUTCDATE(),
    IsVerified      BIT DEFAULT 0,
    VerifiedAt      DATETIME2 NULL,
    IpAddress       NVARCHAR(45)
);

-- ===== IP Management Tables =====

-- IpWhitelist Table - Whitelist IPs for API keys
CREATE TABLE IpWhitelist (
    Id          BIGINT PRIMARY KEY IDENTITY(1,1),
    ApiKeyId    UNIQUEIDENTIFIER NOT NULL REFERENCES ApiKeys(Id) ON DELETE CASCADE,
    IpAddress   NVARCHAR(45) NOT NULL,
    Description NVARCHAR(255),
    CreatedAt   DATETIME2 DEFAULT GETUTCDATE(),
    CreatedBy   UNIQUEIDENTIFIER NULL REFERENCES Users(Id)
);

-- IpBlacklist Table - Blacklist IPs globally
CREATE TABLE IpBlacklist (
    Id          BIGINT PRIMARY KEY IDENTITY(1,1),
    IpAddress   NVARCHAR(45) NOT NULL UNIQUE,
    Reason      NVARCHAR(500),
    CreatedAt   DATETIME2 DEFAULT GETUTCDATE(),
    CreatedBy   UNIQUEIDENTIFIER NULL REFERENCES Users(Id) ON DELETE SET NULL,
    IsActive    BIT DEFAULT 1
);

-- ===== User Activity Tables =====

-- UserActivityLog Table - Track user activities (separate from audit)
CREATE TABLE UserActivityLog (
    Id              BIGINT PRIMARY KEY IDENTITY(1,1),
    UserId          UNIQUEIDENTIFIER NULL REFERENCES Users(Id) ON DELETE SET NULL,
    ActivityType    NVARCHAR(100) NOT NULL,  -- 'LOGIN', 'LOGOUT', 'PAGE_VIEW', etc.
    Description     NVARCHAR(500),
    Metadata        NVARCHAR(MAX),  -- JSON
    IpAddress       NVARCHAR(45),
    UserAgent       NVARCHAR(500),
    CreatedAt       DATETIME2 DEFAULT GETUTCDATE()
);

-- ===== Indexes =====

-- Users Indexes
CREATE INDEX IX_Users_IsActive ON Users(IsActive);

-- UserRegistrations Indexes
CREATE INDEX IX_UserRegistrations_IsVerified ON UserRegistrations(IsVerified);
CREATE INDEX IX_UserRegistrations_ExpiresAt ON UserRegistrations(ExpiresAt);

-- RefreshTokens Indexes
CREATE INDEX IX_RefreshTokens_UserId ON RefreshTokens(UserId);
CREATE INDEX IX_RefreshTokens_ExpiresAt ON RefreshTokens(ExpiresAt);
CREATE INDEX IX_RefreshTokens_IsRevoked ON RefreshTokens(IsRevoked);

-- Roles Indexes
CREATE INDEX IX_Roles_IsActive ON Roles(IsActive);

-- Permissions Indexes
CREATE INDEX IX_Permissions_Module ON Permissions(Module);

-- UserRoles Indexes
CREATE INDEX IX_UserRoles_UserId ON UserRoles(UserId);
CREATE INDEX IX_UserRoles_RoleId ON UserRoles(RoleId);

-- RolePermissions Indexes
CREATE INDEX IX_RolePermissions_RoleId ON RolePermissions(RoleId);
CREATE INDEX IX_RolePermissions_PermissionId ON RolePermissions(PermissionId);

-- ApiKeys Indexes
CREATE INDEX IX_ApiKeys_UserId ON ApiKeys(UserId);
CREATE INDEX IX_ApiKeys_KeyPrefix ON ApiKeys(KeyPrefix);
CREATE INDEX IX_ApiKeys_IsActive ON ApiKeys(IsActive);
CREATE INDEX IX_ApiKeys_ExpiresAt ON ApiKeys(ExpiresAt);

-- ApiUsage Indexes
CREATE INDEX IX_ApiUsage_ApiKeyId ON ApiUsage(ApiKeyId);
CREATE INDEX IX_ApiUsage_UserId ON ApiUsage(UserId);
CREATE INDEX IX_ApiUsage_RequestedAt ON ApiUsage(RequestedAt);
CREATE INDEX IX_ApiUsage_ResponseStatus ON ApiUsage(ResponseStatus);
CREATE INDEX IX_ApiUsage_Endpoint ON ApiUsage(Endpoint);

-- AuditLog Indexes
CREATE INDEX IX_AuditLog_UserId ON AuditLog(UserId);
CREATE INDEX IX_AuditLog_Action ON AuditLog(Action);
CREATE INDEX IX_AuditLog_CreatedAt ON AuditLog(CreatedAt);
CREATE INDEX IX_AuditLog_EntityType ON AuditLog(EntityType);

-- PasswordResetTokens Indexes
CREATE INDEX IX_PasswordResetTokens_UserId ON PasswordResetTokens(UserId);
CREATE INDEX IX_PasswordResetTokens_ExpiresAt ON PasswordResetTokens(ExpiresAt);
CREATE INDEX IX_PasswordResetTokens_IsUsed ON PasswordResetTokens(IsUsed);

-- Sessions Indexes
CREATE INDEX IX_Sessions_UserId ON Sessions(UserId);
CREATE INDEX IX_Sessions_ExpiresAt ON Sessions(ExpiresAt);
CREATE INDEX IX_Sessions_LastActivityAt ON Sessions(LastActivityAt);

-- UserSettings Indexes
CREATE INDEX IX_UserSettings_UserId ON UserSettings(UserId);
CREATE INDEX IX_UserSettings_SettingKey ON UserSettings(SettingKey);

-- NotificationSettings Indexes
CREATE INDEX IX_NotificationSettings_UserId ON NotificationSettings(UserId);

-- TwoFactorSecrets Indexes
CREATE INDEX IX_TwoFactorSecrets_UserId ON TwoFactorSecrets(UserId);
CREATE INDEX IX_TwoFactorSecrets_IsEnabled ON TwoFactorSecrets(IsEnabled);

-- BackupCodes Indexes
CREATE INDEX IX_BackupCodes_UserId ON BackupCodes(UserId);
CREATE INDEX IX_BackupCodes_Code ON BackupCodes(Code);
CREATE INDEX IX_BackupCodes_IsUsed ON BackupCodes(IsUsed);

-- EmailVerificationLogs Indexes
CREATE INDEX IX_EmailVerificationLogs_UserId ON EmailVerificationLogs(UserId);
CREATE INDEX IX_EmailVerificationLogs_Email ON EmailVerificationLogs(Email);
CREATE INDEX IX_EmailVerificationLogs_Token ON EmailVerificationLogs(Token);
CREATE INDEX IX_EmailVerificationLogs_EmailType ON EmailVerificationLogs(EmailType);
CREATE INDEX IX_EmailVerificationLogs_SentAt ON EmailVerificationLogs(SentAt);

-- IpWhitelist Indexes
CREATE INDEX IX_IpWhitelist_ApiKeyId ON IpWhitelist(ApiKeyId);
CREATE INDEX IX_IpWhitelist_IpAddress ON IpWhitelist(IpAddress);

-- IpBlacklist Indexes
CREATE INDEX IX_IpBlacklist_IsActive ON IpBlacklist(IsActive);

-- UserActivityLog Indexes
CREATE INDEX IX_UserActivityLog_UserId ON UserActivityLog(UserId);
CREATE INDEX IX_UserActivityLog_ActivityType ON UserActivityLog(ActivityType);
CREATE INDEX IX_UserActivityLog_CreatedAt ON UserActivityLog(CreatedAt);

-- ===== Seed Data =====

-- Seed Roles
INSERT INTO Roles (RoleName, Description) VALUES 
('Admin', 'Full access to all features and user management'),
('User', 'Standard user with application access'),
('ReadOnly', 'Read-only access to application data'),
('ApiUser', 'User with API key access only');

-- Seed Permissions (Generic - customize for your application)
INSERT INTO Permissions (PermissionName, Description, Module) VALUES 
('app.read', 'Read application data', 'app'),
('app.write', 'Create application data', 'app'),
('app.delete', 'Delete application data', 'app'),
('app.verify', 'Verify application data', 'app'),
('user.read', 'View user information', 'user'),
('user.manage', 'Manage users (create, update, delete)', 'user'),
('apikey.read', 'View API keys', 'apikey'),
('apikey.create', 'Create API keys', 'apikey'),
('apikey.manage', 'Manage API keys (update, delete)', 'apikey'),
('apikey.view_usage', 'View API usage statistics', 'apikey'),
('role.read', 'View roles', 'role'),
('role.manage', 'Manage roles and permissions', 'role'),
('audit.read', 'View audit logs', 'audit');

-- Seed RolePermissions for Admin (all permissions)
INSERT INTO RolePermissions (RoleId, PermissionId)
SELECT 1, Id FROM Permissions;

-- Seed RolePermissions for User (basic application access)
INSERT INTO RolePermissions (RoleId, PermissionId)
SELECT 2, Id FROM Permissions WHERE PermissionName IN ('app.read', 'app.write');

-- Seed RolePermissions for ReadOnly (read only)
INSERT INTO RolePermissions (RoleId, PermissionId)
SELECT 3, Id FROM Permissions WHERE PermissionName IN ('app.read');

-- Seed RolePermissions for ApiUser (API access)
INSERT INTO RolePermissions (RoleId, PermissionId)
SELECT 4, Id FROM Permissions WHERE PermissionName IN ('app.read', 'app.write', 'apikey.read', 'apikey.view_usage');

-- Seed Notification Event Types (available notification events)
-- NOTE: These are inserted per-user when user registers. Below is a reference list.
-- EventType values: 'LOGIN_SUCCESS', 'LOGIN_FAILED', 'PASSWORD_CHANGED', 'PASSWORD_RESET',
--                   'EMAIL_VERIFIED', 'API_KEY_CREATED', 'API_KEY_EXPIRY', 'API_KEY_DELETED',
--                   'RATE_LIMIT_EXCEEDED', 'ACCOUNT_LOCKED', 'ROLE_CHANGED', '2FA_ENABLED', '2FA_DISABLED'
GO

-- ===== Stored Procedures =====

-- SP: Check Rate Limit for API Key
CREATE PROCEDURE sp_CheckRateLimit
    @ApiKey UNIQUEIDENTIFIER,
    @Endpoint NVARCHAR(255),
    @IsAllowed BIT OUTPUT,
    @RemainingRequests INT OUTPUT,
    @ResetTime DATETIME2 OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @RateLimitPerHour INT;
    DECLARE @CurrentHour DATETIME2 = DATEADD(HOUR, DATEDIFF(HOUR, 0, GETUTCDATE()), 0);
    DECLARE @RequestCount INT;
    
    -- Get rate limit setting
    SELECT @RateLimitPerHour = RateLimitPerHour
    FROM ApiKeys
    WHERE Id = @ApiKey AND IsActive = 1 AND (ExpiresAt IS NULL OR ExpiresAt > GETUTCDATE());
    
    IF @RateLimitPerHour IS NULL
    BEGIN
        SET @IsAllowed = 0;
        SET @RemainingRequests = 0;
        SET @ResetTime = GETUTCDATE();
        RETURN;
    END;
    
    -- Count requests in current hour
    SELECT @RequestCount = COUNT(*)
    FROM ApiUsage
    WHERE ApiKeyId = @ApiKey
      AND RequestedAt >= @CurrentHour;
    
    SET @RemainingRequests = @RateLimitPerHour - @RequestCount;
    SET @ResetTime = DATEADD(HOUR, 1, @CurrentHour);
    
    IF @RequestCount >= @RateLimitPerHour
    BEGIN
        SET @IsAllowed = 0;
    END
    ELSE
    BEGIN
        SET @IsAllowed = 1;
    END;
END;
GO

-- SP: Log API Usage
CREATE PROCEDURE sp_LogApiUsage
    @ApiKey UNIQUEIDENTIFIER,
    @UserId UNIQUEIDENTIFIER = NULL,
    @Endpoint NVARCHAR(255),
    @HttpMethod NVARCHAR(10),
    @ResponseStatus INT,
    @ProcessingTimeMs INT = NULL,
    @RequestSizeBytes BIGINT = NULL,
    @ResponseSizeBytes BIGINT = NULL,
    @IpAddress NVARCHAR(45) = NULL,
    @UserAgent NVARCHAR(500) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    INSERT INTO ApiUsage (
        ApiKeyId, UserId, Endpoint, HttpMethod, RequestedAt,
        ResponseStatus, ProcessingTimeMs, RequestSizeBytes, ResponseSizeBytes,
        IpAddress, UserAgent
    )
    VALUES (
        @ApiKey, @UserId, @Endpoint, @HttpMethod, GETUTCDATE(),
        @ResponseStatus, @ProcessingTimeMs, @RequestSizeBytes, @ResponseSizeBytes,
        @IpAddress, @UserAgent
    );
    
    -- Update last used timestamp and usage count
    UPDATE ApiKeys
    SET LastUsedAt = GETUTCDATE(),
        UsageCount = UsageCount + 1
    WHERE Id = @ApiKey;
END;
GO

-- SP: Get User Permissions
CREATE PROCEDURE sp_GetUserPermissions
    @UserId UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT DISTINCT p.Id, p.PermissionName, p.Description, p.Module
    FROM Permissions p
    INNER JOIN RolePermissions rp ON p.Id = rp.PermissionId
    INNER JOIN UserRoles ur ON rp.RoleId = ur.RoleId
    WHERE ur.UserId = @UserId
      AND EXISTS (SELECT 1 FROM Roles WHERE Id = rp.RoleId AND IsActive = 1)
    ORDER BY p.Module, p.PermissionName;
END;
GO

-- SP: Check User Permission
CREATE PROCEDURE sp_CheckUserPermission
    @UserId UNIQUEIDENTIFIER,
    @PermissionName NVARCHAR(255),
    @HasPermission BIT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    IF EXISTS (
        SELECT 1
        FROM Permissions p
        INNER JOIN RolePermissions rp ON p.Id = rp.PermissionId
        INNER JOIN UserRoles ur ON rp.RoleId = ur.RoleId
        INNER JOIN Roles r ON ur.RoleId = r.Id
        WHERE ur.UserId = @UserId
          AND p.PermissionName = @PermissionName
          AND r.IsActive = 1
    )
    BEGIN
        SET @HasPermission = 1;
    END
    ELSE
    BEGIN
        SET @HasPermission = 0;
    END;
END;
GO

-- SP: Validate API Key
CREATE PROCEDURE sp_ValidateApiKey
    @KeyValue NVARCHAR(500),
    @IsValid BIT OUTPUT,
    @ApiKey UNIQUEIDENTIFIER OUTPUT,
    @UserId UNIQUEIDENTIFIER OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    SET @IsValid = 0;
    SET @ApiKey = NULL;
    SET @UserId = NULL;

    SELECT @ApiKey = Id, @UserId = UserId
    FROM ApiKeys
    WHERE KeyValue = @KeyValue
      AND IsActive = 1
      AND (ExpiresAt IS NULL OR ExpiresAt > GETUTCDATE());

    IF @ApiKey IS NOT NULL
        SET @IsValid = 1;
END;
GO

-- SP: Create Default Notification Settings for new user
CREATE PROCEDURE sp_CreateDefaultNotificationSettings
    @UserId UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO NotificationSettings (UserId, EventType, EmailEnabled, SmsEnabled, PushEnabled, InAppEnabled)
    VALUES
        (@UserId, 'LOGIN_SUCCESS',        0, 0, 0, 1),
        (@UserId, 'LOGIN_FAILED',         1, 0, 0, 1),
        (@UserId, 'PASSWORD_CHANGED',     1, 0, 0, 1),
        (@UserId, 'PASSWORD_RESET',       1, 0, 0, 1),
        (@UserId, 'EMAIL_VERIFIED',       1, 0, 0, 1),
        (@UserId, 'API_KEY_CREATED',      1, 0, 0, 1),
        (@UserId, 'API_KEY_EXPIRY',       1, 0, 1, 1),
        (@UserId, 'API_KEY_DELETED',      1, 0, 0, 1),
        (@UserId, 'RATE_LIMIT_EXCEEDED',  1, 0, 1, 1),
        (@UserId, 'ACCOUNT_LOCKED',       1, 0, 1, 1),
        (@UserId, 'ROLE_CHANGED',         1, 0, 0, 1),
        (@UserId, '2FA_ENABLED',          1, 0, 0, 1),
        (@UserId, '2FA_DISABLED',         1, 0, 1, 1);
END;
GO

-- SP: Log Audit Event
CREATE PROCEDURE sp_LogAudit
    @UserId UNIQUEIDENTIFIER = NULL,
    @Action NVARCHAR(100),
    @EntityType NVARCHAR(50) = NULL,
    @EntityId NVARCHAR(100) = NULL,
    @OldValues NVARCHAR(MAX) = NULL,
    @NewValues NVARCHAR(MAX) = NULL,
    @IpAddress NVARCHAR(45) = NULL,
    @UserAgent NVARCHAR(500) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    INSERT INTO AuditLog (
        UserId, Action, EntityType, EntityId, OldValues, NewValues,
        IpAddress, UserAgent, CreatedAt
    )
    VALUES (
        @UserId, @Action, @EntityType, @EntityId, @OldValues, @NewValues,
        @IpAddress, @UserAgent, GETUTCDATE()
    );
END;
GO

-- SP: Update Failed Login Count
CREATE PROCEDURE sp_UpdateFailedLogin
    @Email NVARCHAR(255),
    @IsSuccess BIT
AS
BEGIN
    SET NOCOUNT ON;
    
    IF @IsSuccess = 1
    BEGIN
        -- Reset failed login count and update last login
        UPDATE Users
        SET FailedLoginCount = 0,
            LastLoginAt = GETUTCDATE(),
            LockUntil = NULL
        WHERE Email = @Email;
    END
    ELSE
    BEGIN
        -- Increment failed login count
        UPDATE Users
        SET FailedLoginCount = FailedLoginCount + 1,
            LockUntil = CASE 
                WHEN FailedLoginCount >= 4 THEN DATEADD(MINUTE, 30, GETUTCDATE())
                ELSE NULL
            END
        WHERE Email = @Email;
    END;
END;
GO

PRINT '========================================';
PRINT 'Auth, API & Authorization Schema Created';
PRINT '========================================';
PRINT 'Tables: Users, UserRegistrations, RefreshTokens, Roles, Permissions';
PRINT '        UserRoles, RolePermissions, ApiKeys, ApiUsage, AuditLog';
PRINT '        PasswordResetTokens, Sessions, UserSettings, NotificationSettings';
PRINT '        TwoFactorSecrets, BackupCodes, EmailVerificationLogs';
PRINT '        IpWhitelist, IpBlacklist, UserActivityLog';
PRINT 'Stored Procedures: sp_CheckRateLimit, sp_LogApiUsage, sp_GetUserPermissions';
PRINT '                   sp_CheckUserPermission, sp_ValidateApiKey, sp_LogAudit';
PRINT '                   sp_UpdateFailedLogin, sp_CreateDefaultNotificationSettings';
PRINT 'Seed Data: 4 Roles, 13 Generic Permissions, RolePermissions mappings';
PRINT '========================================';
PRINT 'NOTE: Customize permissions and role mappings for your application';
PRINT '========================================';
GO
