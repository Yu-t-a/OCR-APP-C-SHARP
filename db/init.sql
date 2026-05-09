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

-- ===== Seed Data for OCR System =====

-- Seed Document Types
INSERT INTO DocumentTypes (TypeCode, TypeName, SchemaTemplate, IsActive) VALUES 
('invoice', 'Invoice Document', '{"fields": ["InvoiceNo", "InvoiceDate", "TotalAmount", "VendorName"]}', 1),
('receipt', 'Receipt Document', '{"fields": ["ReceiptNo", "ReceiptDate", "Amount", "StoreName"]}', 1),
('contract', 'Contract Document', '{"fields": ["ContractNo", "ContractDate", "Parties", "EffectiveDate"]}', 1),
('id_card', 'ID Card Document', '{"fields": ["IDNumber", "Name", "BirthDate", "Address"]}', 1),
('passport', 'Passport Document', '{"fields": ["PassportNo", "Name", "Nationality", "ExpiryDate"]}', 1);
