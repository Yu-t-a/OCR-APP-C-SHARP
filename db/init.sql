-- Create Database
IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = 'TyphoonOcrDB')
BEGIN
    CREATE DATABASE TyphoonOcrDB;
END
GO

USE TyphoonOcrDB;
GO

-- 1. ประเภทเอกสาร
CREATE TABLE DocumentTypes (
    Id              INT PRIMARY KEY IDENTITY(1,1),
    TypeCode        NVARCHAR(50) NOT NULL UNIQUE,   -- 'invoice','receipt','contract'
    TypeName        NVARCHAR(100) NOT NULL,
    SchemaTemplate  NVARCHAR(MAX),                  -- JSON template ว่า field ที่ควรมีคืออะไร
    IsActive        BIT DEFAULT 1
);

-- 2. งาน OCR (1 Job = 1 ไฟล์)
CREATE TABLE OcrJobs (
    Id              UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWSEQUENTIALID(),
    DocumentTypeId  INT REFERENCES DocumentTypes(Id),
    SourceFileName  NVARCHAR(500) NOT NULL,
    SourceFilePath  NVARCHAR(1000),
    Status          NVARCHAR(20) DEFAULT 'Pending',  -- Pending/Processing/Done/Failed
    CreatedAt       DATETIME2 DEFAULT GETUTCDATE(),
    ProcessedAt     DATETIME2
);

-- 3. ผลลัพธ์ OCR (Main Table) — รองรับหลายหน้า
CREATE TABLE OcrDocuments (
    Id              UNIQUEIDENTIFIER CONSTRAINT PK_OcrDocuments PRIMARY KEY DEFAULT NEWSEQUENTIALID(),
    JobId           UNIQUEIDENTIFIER NOT NULL REFERENCES OcrJobs(Id),
    DocumentTypeId  INT NOT NULL REFERENCES DocumentTypes(Id),
    PageNumber      INT DEFAULT 1,
    RawText         NVARCHAR(MAX),               -- OCR text ดิบทั้งหมด
    ExtractedData   NVARCHAR(MAX),               -- ★ JSON Column (flexible fields)
    Confidence      FLOAT,
    IsVerified      BIT DEFAULT 0,
    ErrorMessage    NVARCHAR(MAX),
    CreatedAt       DATETIME2 DEFAULT GETUTCDATE(),
    UpdatedAt       DATETIME2,
    CreatedBy       NVARCHAR(100)
);

-- 4. (Optional) แยก field สำคัญออกมา เพื่อ search/filter ได้เร็ว
CREATE TABLE OcrDocumentFields (
    Id          INT CONSTRAINT PK_OcrDocumentFields PRIMARY KEY IDENTITY(1,1),
    DocumentId  UNIQUEIDENTIFIER NOT NULL REFERENCES OcrDocuments(Id),
    FieldName   NVARCHAR(100) NOT NULL,    -- 'InvoiceNo', 'TotalAmount'
    FieldValue  NVARCHAR(MAX),
    FieldType   NVARCHAR(20),              -- 'text','number','date'
    Confidence  FLOAT
);

-- ===== Indexes =====
CREATE INDEX IX_OcrDocuments_JobId          ON OcrDocuments(JobId);
CREATE INDEX IX_OcrDocuments_DocumentTypeId ON OcrDocuments(DocumentTypeId);
CREATE INDEX IX_OcrDocuments_CreatedAt      ON OcrDocuments(CreatedAt);
CREATE INDEX IX_OcrDocuments_IsVerified     ON OcrDocuments(IsVerified);
CREATE INDEX IX_OcrDocumentFields_DocId     ON OcrDocumentFields(DocumentId);
CREATE INDEX IX_OcrDocumentFields_Name      ON OcrDocumentFields(FieldName);

-- JSON Check Constraint (SQL Server 2016+)
ALTER TABLE OcrDocuments
    ADD CONSTRAINT CK_OcrDocuments_ExtractedData 
    CHECK (ExtractedData IS NULL OR ISJSON(ExtractedData) = 1);

-- ===== Authentication & Authorization Tables =====

-- 5. Users - ข้อมูลผู้ใช้
CREATE TABLE Users (
    Id              UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWSEQUENTIALID(),
    Email           NVARCHAR(255) NOT NULL UNIQUE,
    Username        NVARCHAR(100) NOT NULL UNIQUE,
    PasswordHash    NVARCHAR(500) NOT NULL,
    IsActive        BIT DEFAULT 1,
    CreatedAt       DATETIME2 DEFAULT GETUTCDATE(),
    LastLoginAt     DATETIME2,
    FailedLoginCount INT DEFAULT 0
);

-- 6. Roles - บทบาท (Admin, User, etc.)
CREATE TABLE Roles (
    Id          INT PRIMARY KEY IDENTITY(1,1),
    RoleName    NVARCHAR(50) NOT NULL UNIQUE,
    Description NVARCHAR(255),
    CreatedAt   DATETIME2 DEFAULT GETUTCDATE()
);

-- 7. UserRoles - ความสัมพันธ์ User ↔ Role
CREATE TABLE UserRoles (
    UserId      UNIQUEIDENTIFIER NOT NULL REFERENCES Users(Id),
    RoleId      INT NOT NULL REFERENCES Roles(Id),
    AssignedAt  DATETIME2 DEFAULT GETUTCDATE(),
    PRIMARY KEY (UserId, RoleId)
);

-- 8. Permissions - สิทธิ์ (ocr.read, ocr.write, etc.)
CREATE TABLE Permissions (
    Id              INT PRIMARY KEY IDENTITY(1,1),
    PermissionName  NVARCHAR(100) NOT NULL UNIQUE,
    Description     NVARCHAR(255),
    CreatedAt       DATETIME2 DEFAULT GETUTCDATE()
);

-- 9. RolePermissions - ความสัมพันธ์ Role ↔ Permission
CREATE TABLE RolePermissions (
    RoleId          INT NOT NULL REFERENCES Roles(Id),
    PermissionId    INT NOT NULL REFERENCES Permissions(Id),
    GrantedAt       DATETIME2 DEFAULT GETUTCDATE(),
    PRIMARY KEY (RoleId, PermissionId)
);

-- ===== API Key Management Tables =====

-- 10. ApiKeys - API Keys สำหรับการเรียกใช้ API
CREATE TABLE ApiKeys (
    Id              UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWSEQUENTIALID(),
    UserId          UNIQUEIDENTIFIER NOT NULL REFERENCES Users(Id),
    KeyName         NVARCHAR(100) NOT NULL,
    KeyValue        NVARCHAR(500) NOT NULL UNIQUE,  -- hashed API key
    IsActive        BIT DEFAULT 1,
    ExpiresAt       DATETIME2,
    RateLimitPerHour INT DEFAULT 100,
    CreatedAt       DATETIME2 DEFAULT GETUTCDATE(),
    LastUsedAt      DATETIME2
);

-- 11. ApiUsage - Tracking การใช้งาน API (สำหรับ Rate Limiting)
CREATE TABLE ApiUsage (
    Id              BIGINT PRIMARY KEY IDENTITY(1,1),
    ApiKeyId        UNIQUEIDENTIFIER NOT NULL REFERENCES ApiKeys(Id),
    Endpoint        NVARCHAR(255) NOT NULL,
    RequestedAt     DATETIME2 DEFAULT GETUTCDATE(),
    ResponseStatus  INT,
    ProcessingTimeMs INT
);

-- 12. RefreshTokens - สำหรับ JWT Refresh Token
CREATE TABLE RefreshTokens (
    Id          UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWSEQUENTIALID(),
    UserId      UNIQUEIDENTIFIER NOT NULL REFERENCES Users(Id),
    Token       NVARCHAR(500) NOT NULL UNIQUE,
    ExpiresAt   DATETIME2 NOT NULL,
    CreatedAt   DATETIME2 DEFAULT GETUTCDATE(),
    IsRevoked   BIT DEFAULT 0
);

-- ===== Indexes for Auth & API Tables =====
CREATE INDEX IX_Users_Email ON Users(Email);
CREATE INDEX IX_Users_Username ON Users(Username);
CREATE INDEX IX_ApiKeys_UserId ON ApiKeys(UserId);
CREATE INDEX IX_ApiKeys_KeyValue ON ApiKeys(KeyValue);
CREATE INDEX IX_ApiUsage_ApiKeyId ON ApiUsage(ApiKeyId);
CREATE INDEX IX_ApiUsage_RequestedAt ON ApiUsage(RequestedAt);
CREATE INDEX IX_RefreshTokens_Token ON RefreshTokens(Token);
CREATE INDEX IX_RefreshTokens_UserId ON RefreshTokens(UserId);

-- ===== Seed Data =====

-- Seed Roles
INSERT INTO Roles (RoleName, Description) VALUES 
('Admin', 'Full access to all features'),
('User', 'Basic OCR access'),
('ReadOnly', 'Read-only access');

-- Seed Permissions
INSERT INTO Permissions (PermissionName, Description) VALUES 
('ocr.read', 'Read OCR results'),
('ocr.write', 'Create OCR jobs'),
('ocr.delete', 'Delete OCR documents'),
('user.manage', 'Manage users'),
('apikey.manage', 'Manage API keys');

-- Seed RolePermissions for Admin (all permissions)
INSERT INTO RolePermissions (RoleId, PermissionId)
SELECT 1, Id FROM Permissions WHERE PermissionName IN ('ocr.read', 'ocr.write', 'ocr.delete', 'user.manage', 'apikey.manage');

-- Seed RolePermissions for User (basic OCR access)
INSERT INTO RolePermissions (RoleId, PermissionId)
SELECT 2, Id FROM Permissions WHERE PermissionName IN ('ocr.read', 'ocr.write');

-- Seed RolePermissions for ReadOnly (read only)
INSERT INTO RolePermissions (RoleId, PermissionId)
SELECT 3, Id FROM Permissions WHERE PermissionName IN ('ocr.read');
