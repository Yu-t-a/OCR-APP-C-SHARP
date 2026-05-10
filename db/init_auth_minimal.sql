-- ============================================
-- Minimal Auth & API Schema
-- For small projects - essential features only
-- Compatible with MSSQL Server 2019/2022
-- ============================================

IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = 'TyphoonOcrDB')
BEGIN
    CREATE DATABASE TyphoonOcrDB;
END
GO

USE TyphoonOcrDB;
GO

-- ===== Tables =====

-- Users Table
CREATE TABLE Users (
    Id              UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWSEQUENTIALID(),
    Email           NVARCHAR(255) NOT NULL UNIQUE,
    Username        NVARCHAR(100) NOT NULL UNIQUE,
    DisplayName     NVARCHAR(200),
    PasswordHash    NVARCHAR(500) NOT NULL,
    Salt            NVARCHAR(100) NOT NULL,
    IsActive        BIT DEFAULT 1,
    IsEmailVerified BIT DEFAULT 0,
    CreatedAt       DATETIME2 DEFAULT GETUTCDATE(),
    UpdatedAt       DATETIME2 DEFAULT GETUTCDATE(),
    LastLoginAt     DATETIME2,
    FailedLoginCount INT DEFAULT 0,
    LockUntil       DATETIME2 NULL
);

-- Roles Table
CREATE TABLE Roles (
    Id          INT PRIMARY KEY IDENTITY(1,1),
    RoleName    NVARCHAR(50) NOT NULL UNIQUE,
    Description NVARCHAR(255),
    CreatedAt   DATETIME2 DEFAULT GETUTCDATE()
);

-- UserRoles Table
CREATE TABLE UserRoles (
    UserId      UNIQUEIDENTIFIER NOT NULL REFERENCES Users(Id) ON DELETE CASCADE,
    RoleId      INT NOT NULL REFERENCES Roles(Id) ON DELETE CASCADE,
    AssignedAt  DATETIME2 DEFAULT GETUTCDATE(),
    PRIMARY KEY (UserId, RoleId)
);

-- ApiKeys Table
CREATE TABLE ApiKeys (
    Id              UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWSEQUENTIALID(),
    UserId          UNIQUEIDENTIFIER NOT NULL REFERENCES Users(Id) ON DELETE CASCADE,
    KeyName         NVARCHAR(100) NOT NULL,
    KeyValue        NVARCHAR(500) NOT NULL UNIQUE,
    IsActive        BIT DEFAULT 1,
    ExpiresAt       DATETIME2 NULL,
    RateLimitPerHour INT DEFAULT 1000,
    CreatedAt       DATETIME2 DEFAULT GETUTCDATE(),
    LastUsedAt      DATETIME2,
    Description     NVARCHAR(500)
);

-- PasswordResetTokens Table
CREATE TABLE PasswordResetTokens (
    Id          UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWSEQUENTIALID(),
    UserId      UNIQUEIDENTIFIER NOT NULL REFERENCES Users(Id) ON DELETE CASCADE,
    Token       NVARCHAR(500) NOT NULL UNIQUE,
    ExpiresAt   DATETIME2 NOT NULL,
    CreatedAt   DATETIME2 DEFAULT GETUTCDATE(),
    IsUsed      BIT DEFAULT 0,
    UsedAt      DATETIME2 NULL
);

-- AuditLog Table (รวม activity ทุกอย่าง)
CREATE TABLE AuditLog (
    Id          BIGINT PRIMARY KEY IDENTITY(1,1),
    UserId      UNIQUEIDENTIFIER NULL REFERENCES Users(Id) ON DELETE SET NULL,
    Action      NVARCHAR(100) NOT NULL,
    EntityType  NVARCHAR(50),
    EntityId    NVARCHAR(100),
    Detail      NVARCHAR(MAX),      -- JSON or plain text
    IpAddress   NVARCHAR(45),
    CreatedAt   DATETIME2 DEFAULT GETUTCDATE()
);

-- ===== Indexes =====

CREATE INDEX IX_Users_IsActive            ON Users(IsActive);
CREATE INDEX IX_Users_IsEmailVerified     ON Users(IsEmailVerified);
CREATE INDEX IX_ApiKeys_UserId            ON ApiKeys(UserId);
CREATE INDEX IX_ApiKeys_IsActive          ON ApiKeys(IsActive);
CREATE INDEX IX_PasswordResetTokens_UserId ON PasswordResetTokens(UserId);
CREATE INDEX IX_PasswordResetTokens_IsUsed ON PasswordResetTokens(IsUsed);
CREATE INDEX IX_AuditLog_UserId           ON AuditLog(UserId);
CREATE INDEX IX_AuditLog_Action           ON AuditLog(Action);
CREATE INDEX IX_AuditLog_CreatedAt        ON AuditLog(CreatedAt);

-- ===== Seed Data =====

-- Roles
INSERT INTO Roles (RoleName, Description)
VALUES
    ('Admin', 'Full access to all features'),
    ('User',  'Standard user access');

-- ===== Stored Procedures =====

-- SP: Validate API Key
GO
CREATE PROCEDURE sp_ValidateApiKey
    @KeyValue   NVARCHAR(500),
    @IsValid    BIT OUTPUT,
    @ApiKeyId   UNIQUEIDENTIFIER OUTPUT,
    @UserId     UNIQUEIDENTIFIER OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    SET @IsValid  = 0;
    SET @ApiKeyId = NULL;
    SET @UserId   = NULL;

    SELECT @ApiKeyId = Id, @UserId = UserId
    FROM ApiKeys
    WHERE KeyValue = @KeyValue
      AND IsActive = 1
      AND (ExpiresAt IS NULL OR ExpiresAt > GETUTCDATE());

    IF @ApiKeyId IS NOT NULL
        SET @IsValid = 1;
END;
GO

-- SP: Update Failed Login (lock after 5 attempts)
CREATE PROCEDURE sp_UpdateFailedLogin
    @Email      NVARCHAR(255),
    @IsSuccess  BIT
AS
BEGIN
    SET NOCOUNT ON;

    IF @IsSuccess = 1
    BEGIN
        UPDATE Users
        SET FailedLoginCount = 0,
            LastLoginAt      = GETUTCDATE(),
            LockUntil        = NULL,
            UpdatedAt        = GETUTCDATE()
        WHERE Email = @Email;
    END
    ELSE
    BEGIN
        UPDATE Users
        SET FailedLoginCount = FailedLoginCount + 1,
            LockUntil        = CASE WHEN FailedLoginCount + 1 >= 5
                                    THEN DATEADD(MINUTE, 30, GETUTCDATE())
                                    ELSE NULL END,
            UpdatedAt        = GETUTCDATE()
        WHERE Email = @Email;
    END
END;
GO

-- SP: Log Audit
CREATE PROCEDURE sp_LogAudit
    @UserId     UNIQUEIDENTIFIER = NULL,
    @Action     NVARCHAR(100),
    @EntityType NVARCHAR(50)  = NULL,
    @EntityId   NVARCHAR(100) = NULL,
    @Detail     NVARCHAR(MAX) = NULL,
    @IpAddress  NVARCHAR(45)  = NULL
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO AuditLog (UserId, Action, EntityType, EntityId, Detail, IpAddress, CreatedAt)
    VALUES (@UserId, @Action, @EntityType, @EntityId, @Detail, @IpAddress, GETUTCDATE());
END;
GO

-- ===== Test Seed Data (DEV ONLY) =====
-- NOTE: Remove this section before production deployment

DECLARE @AdminId UNIQUEIDENTIFIER = '11111111-1111-1111-1111-111111111111';
DECLARE @UserId  UNIQUEIDENTIFIER = '22222222-2222-2222-2222-222222222222';
DECLARE @ApiKeyId UNIQUEIDENTIFIER = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';

-- Test Users
INSERT INTO Users (Id, Email, Username, DisplayName, PasswordHash, Salt, IsActive, IsEmailVerified)
VALUES
    (@AdminId, 'admin@test.com', 'admin', 'Admin User',
     'PBKDF2$SHA256$10000$SALT_ADMIN$HASH_ADMIN_PLACEHOLDER', 'SALT_ADMIN_01', 1, 1),
    (@UserId,  'user@test.com',  'testuser', 'Test User',
     'PBKDF2$SHA256$10000$SALT_USER$HASH_USER_PLACEHOLDER',   'SALT_USER_01',  1, 1);

-- Assign Roles (1=Admin, 2=User)
INSERT INTO UserRoles (UserId, RoleId)
VALUES
    (@AdminId, 1),
    (@UserId,  2);

-- Test API Key
INSERT INTO ApiKeys (Id, UserId, KeyName, KeyValue, IsActive, ExpiresAt, RateLimitPerHour, Description)
VALUES
    (@ApiKeyId, @AdminId, 'Dev Key',
     'sk_test_MINIMAL_DEV_KEY_ABCDEFGHIJKLMNOPQRSTUVWXYZ123', 1,
     DATEADD(YEAR, 1, GETUTCDATE()), 500, 'Dev test API key');

-- Test Password Reset Token
INSERT INTO PasswordResetTokens (UserId, Token, ExpiresAt, IsUsed)
VALUES
    (@UserId, 'RESET_TOKEN_TESTUSER_ABCDEF123456', DATEADD(HOUR, 1, GETUTCDATE()), 0);

-- Test Audit Logs
EXEC sp_LogAudit @UserId = @AdminId, @Action = 'USER_LOGIN',      @EntityType = 'User',   @EntityId = '11111111-1111-1111-1111-111111111111', @Detail = N'{"method":"password"}',         @IpAddress = '127.0.0.1';
EXEC sp_LogAudit @UserId = @AdminId, @Action = 'API_KEY_CREATED', @EntityType = 'ApiKey', @EntityId = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',  @Detail = N'{"keyName":"Dev Key"}',          @IpAddress = '127.0.0.1';
EXEC sp_LogAudit @UserId = @UserId,  @Action = 'USER_LOGIN',      @EntityType = 'User',   @EntityId = '22222222-2222-2222-2222-222222222222', @Detail = N'{"method":"password"}',         @IpAddress = '203.0.113.10';
EXEC sp_LogAudit @UserId = NULL,     @Action = 'LOGIN_FAILED',    @EntityType = 'User',   @EntityId = 'unknown@test.com',                    @Detail = N'{"attempts":3,"ip":"1.2.3.4"}', @IpAddress = '1.2.3.4';

PRINT '========================================';
PRINT 'Minimal Auth Schema Created';
PRINT '========================================';
PRINT 'Tables:      Users, Roles, UserRoles, ApiKeys';
PRINT '             PasswordResetTokens, AuditLog';
PRINT 'Procedures:  sp_ValidateApiKey, sp_UpdateFailedLogin, sp_LogAudit';
PRINT 'Seed Roles:  1=Admin, 2=User';
PRINT 'Test Data:   admin@test.com, user@test.com';
PRINT '========================================';
GO
