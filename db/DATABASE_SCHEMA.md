# Database Schema Documentation

## Overview

This document describes the database schema for the Typhoon OCR project's authentication, authorization, and API management system.

## Schema Files

- **`init.sql`** - OCR-specific tables (DocumentTypes, OcrJobs, OcrDocuments, OcrDocumentFields)
- **`init_auth_api.sql`** - Full authentication, authorization, and API management schema (20 tables)
- **`init_auth_minimal.sql`** - Minimal schema for small projects (6 tables)
- **`seed_test_data.sql`** - Test data for development (run only in dev)

---

# Authentication Tables

## Users

**Purpose:** Store user account information

| Column | Type | Description |
|--------|------|-------------|
| Id | UNIQUEIDENTIFIER | Primary key (auto-generated) |
| Email | NVARCHAR(255) | User email (unique) |
| Username | NVARCHAR(100) | Username (unique) |
| DisplayName | NVARCHAR(200) | Display name for UI |
| PasswordHash | NVARCHAR(500) | Hashed password (PBKDF2/bcrypt/etc) |
| Salt | NVARCHAR(100) | Password salt |
| IsActive | BIT | Account active status |
| IsEmailVerified | BIT | Email verification status |
| CreatedAt | DATETIME2 | Account creation timestamp |
| UpdatedAt | DATETIME2 | Last update timestamp |
| LastLoginAt | DATETIME2 | Last successful login |
| FailedLoginCount | INT | Failed login attempts (locks at 5) |
| LockUntil | DATETIME2 | Account lock expiry (NULL if not locked) |

**Relationships:**
- One-to-many to `RefreshTokens` (CASCADE DELETE)
- One-to-many to `UserRegistrations` (CASCADE DELETE)
- One-to-many to `UserRoles` (CASCADE DELETE)
- One-to-many to `ApiKeys` (CASCADE DELETE)
- One-to-many to `PasswordResetTokens` (CASCADE DELETE)
- One-to-many to `Sessions` (CASCADE DELETE)
- One-to-many to `UserSettings` (CASCADE DELETE)
- One-to-many to `TwoFactorSecrets` (CASCADE DELETE)
- One-to-many to `BackupCodes` (CASCADE DELETE)
- One-to-many to `AuditLog` (SET NULL on DELETE)
- One-to-many to `EmailVerificationLogs` (SET NULL on DELETE)
- One-to-many to `IpWhitelist` (NO ACTION)
- One-to-many to `IpBlacklist` (NO ACTION)
- One-to-many to `UserActivityLog` (SET NULL on DELETE)

---

## UserRegistrations

**Purpose:** Store pending user registrations awaiting email verification

| Column | Type | Description |
|--------|------|-------------|
| Id | UNIQUEIDENTIFIER | Primary key |
| Email | NVARCHAR(255) | Email for registration (unique) |
| Username | NVARCHAR(100) | Username for registration (unique) |
| PasswordHash | NVARCHAR(500) | Pre-hashed password |
| Salt | NVARCHAR(100) | Password salt |
| VerificationToken | NVARCHAR(500) | Email verification token (unique) |
| IsVerified | BIT | Verification status |
| CreatedAt | DATETIME2 | Registration timestamp |
| ExpiresAt | DATETIME2 | Token expiry time |
| VerifiedAt | DATETIME2 | Verification timestamp |
| VerifiedBy | UNIQUEIDENTIFIER | Admin who verified (FK to Users) |

**Relationships:**
- FK to `Users(VerifiedBy)` (NO ACTION on DELETE)

---

## RefreshTokens

**Purpose:** Store JWT refresh tokens for token rotation

| Column | Type | Description |
|--------|------|-------------|
| Id | UNIQUEIDENTIFIER | Primary key |
| UserId | UNIQUEIDENTIFIER | User who owns the token (FK to Users) |
| Token | NVARCHAR(500) | Refresh token value (unique) |
| ExpiresAt | DATETIME2 | Token expiry |
| CreatedAt | DATETIME2 | Creation timestamp |
| IsRevoked | BIT | Revocation status |
| RevokedAt | DATETIME2 | Revocation timestamp |
| RevokedBy | UNIQUEIDENTIFIER | Admin who revoked (FK to Users) |

**Relationships:**
- FK to `Users(UserId)` (CASCADE DELETE)
- FK to `Users(RevokedBy)` (NO ACTION on DELETE)

---

## PasswordResetTokens

**Purpose:** Store password reset tokens for password recovery

| Column | Type | Description |
|--------|------|-------------|
| Id | UNIQUEIDENTIFIER | Primary key |
| UserId | UNIQUEIDENTIFIER | User requesting reset (FK to Users) |
| Token | NVARCHAR(500) | Reset token (unique) |
| ExpiresAt | DATETIME2 | Token expiry |
| CreatedAt | DATETIME2 | Creation timestamp |
| IsUsed | BIT | Usage status |
| UsedAt | DATETIME2 | Usage timestamp |

**Relationships:**
- FK to `Users(UserId)` (CASCADE DELETE)

---

## Sessions

**Purpose:** Store active user sessions for session-based authentication

| Column | Type | Description |
|--------|------|-------------|
| Id | NVARCHAR(128) | Session ID (string) |
| UserId | UNIQUEIDENTIFIER | User who owns the session (FK to Users) |
| IpAddress | NVARCHAR(45) | Client IP address |
| UserAgent | NVARCHAR(500) | Client user agent |
| CreatedAt | DATETIME2 | Session creation |
| ExpiresAt | DATETIME2 | Session expiry |
| LastActivityAt | DATETIME2 | Last activity timestamp |

**Relationships:**
- FK to `Users(UserId)` (CASCADE DELETE)

---

# Authorization Tables

## Roles

**Purpose:** Define user roles for RBAC

| Column | Type | Description |
|--------|------|-------------|
| Id | INT | Primary key (auto-increment) |
| RoleName | NVARCHAR(50) | Role name (unique) |
| Description | NVARCHAR(255) | Role description |
| CreatedAt | DATETIME2 | Creation timestamp |

**Seed Data:**
1. `Admin` - Full access to all features
2. `User` - Standard user access
3. `ReadOnly` - Read-only access
4. `ApiUser` - API-only access

---

## Permissions

**Purpose:** Define granular permissions

| Column | Type | Description |
|--------|------|-------------|
| Id | INT | Primary key (auto-increment) |
| PermissionName | NVARCHAR(100) | Permission name (unique) |
| Description | NVARCHAR(255) | Permission description |
| Module | NVARCHAR(50) | Module (app, user, apikey, role, audit) |
| CreatedAt | DATETIME2 | Creation timestamp |

**Seed Permissions (13 total):**
- `app.read`, `app.write` - Application access
- `user.read`, `user.write`, `user.delete` - User management
- `apikey.read`, `apikey.write`, `apikey.delete`, `apikey.view_usage` - API key management
- `role.read`, `role.write`, `role.delete` - Role management
- `audit.read` - Audit log access

---

## UserRoles

**Purpose:** Many-to-many relationship between Users and Roles

| Column | Type | Description |
|--------|------|-------------|
| UserId | UNIQUEIDENTIFIER | User ID (FK to Users) |
| RoleId | INT | Role ID (FK to Roles) |
| AssignedAt | DATETIME2 | Assignment timestamp |
| AssignedBy | UNIQUEIDENTIFIER | Admin who assigned (FK to Users) |

**Relationships:**
- FK to `Users(UserId)` (CASCADE DELETE)
- FK to `Roles(RoleId)` (CASCADE DELETE)
- FK to `Users(AssignedBy)` (NO ACTION on DELETE)

---

## RolePermissions

**Purpose:** Many-to-many relationship between Roles and Permissions

| Column | Type | Description |
|--------|------|-------------|
| RoleId | INT | Role ID (FK to Roles) |
| PermissionId | INT | Permission ID (FK to Permissions) |
| GrantedAt | DATETIME2 | Grant timestamp |
| GrantedBy | UNIQUEIDENTIFIER | Admin who granted (FK to Users) |

**Relationships:**
- FK to `Roles(RoleId)` (CASCADE DELETE)
- FK to `Permissions(PermissionId)` (CASCADE DELETE)
- FK to `Users(GrantedBy)` (SET NULL on DELETE)

---

# API Management Tables

## ApiKeys

**Purpose:** Store API keys for external access

| Column | Type | Description |
|--------|------|-------------|
| Id | UNIQUEIDENTIFIER | Primary key |
| UserId | UNIQUEIDENTIFIER | User who owns the key (FK to Users) |
| KeyName | NVARCHAR(100) | Key name/label |
| KeyValue | NVARCHAR(500) | API key value (hashed, unique) |
| KeyPrefix | NVARCHAR(50) | Key prefix (sk_live_, sk_test_) |
| IsActive | BIT | Active status |
| ExpiresAt | DATETIME2 | Key expiry (NULL = no expiry) |
| RateLimitPerHour | INT | Hourly rate limit |
| RateLimitPerDay | INT | Daily rate limit |
| RateLimitPerMonth | INT | Monthly rate limit |
| CreatedAt | DATETIME2 | Creation timestamp |
| LastUsedAt | DATETIME2 | Last usage timestamp |
| UsageCount | BIGINT | Total usage count |
| Description | NVARCHAR(500) | Key description |

**Relationships:**
- FK to `Users(UserId)` (CASCADE DELETE)
- One-to-many to `ApiUsage` (CASCADE DELETE)
- One-to-many to `IpWhitelist` (CASCADE DELETE)

---

## ApiUsage

**Purpose:** Track API usage for rate limiting and analytics

| Column | Type | Description |
|--------|------|-------------|
| Id | BIGINT | Primary key (auto-increment) |
| ApiKeyId | UNIQUEIDENTIFIER | API key used (FK to ApiKeys) |
| UserId | UNIQUEIDENTIFIER | User who made request (FK to Users) |
| Endpoint | NVARCHAR(255) | API endpoint called |
| HttpMethod | NVARCHAR(10) | HTTP method (GET, POST, PUT, DELETE) |
| RequestedAt | DATETIME2 | Request timestamp |
| ResponseStatus | INT | HTTP response code |
| ProcessingTimeMs | INT | Processing time (ms) |
| RequestSizeBytes | BIGINT | Request size |
| ResponseSizeBytes | BIGINT | Response size |
| IpAddress | NVARCHAR(45) | Client IP |
| UserAgent | NVARCHAR(500) | Client user agent |

**Relationships:**
- FK to `ApiKeys(ApiKeyId)` (CASCADE DELETE)
- FK to `Users(UserId)` (NO ACTION on DELETE)

---

## IpWhitelist

**Purpose:** Whitelist IP addresses for specific API keys

| Column | Type | Description |
|--------|------|-------------|
| Id | BIGINT | Primary key (auto-increment) |
| ApiKeyId | UNIQUEIDENTIFIER | API key (FK to ApiKeys) |
| IpAddress | NVARCHAR(45) | IP address or CIDR range |
| Description | NVARCHAR(255) | Description |
| CreatedAt | DATETIME2 | Creation timestamp |
| CreatedBy | UNIQUEIDENTIFIER | Creator (FK to Users) |

**Relationships:**
- FK to `ApiKeys(ApiKeyId)` (CASCADE DELETE)
- FK to `Users(CreatedBy)` (NO ACTION on DELETE)

---

## IpBlacklist

**Purpose:** Blacklist IP addresses globally

| Column | Type | Description |
|--------|------|-------------|
| Id | BIGINT | Primary key (auto-increment) |
| IpAddress | NVARCHAR(45) | IP address (unique) |
| Reason | NVARCHAR(500) | Blacklist reason |
| CreatedAt | DATETIME2 | Creation timestamp |
| CreatedBy | UNIQUEIDENTIFIER | Creator (FK to Users) |
| IsActive | BIT | Active status |

**Relationships:**
- FK to `Users(CreatedBy)` (SET NULL on DELETE)

---

# Audit & Logging Tables

## AuditLog

**Purpose:** Track important system events for audit trail

| Column | Type | Description |
|--------|------|-------------|
| Id | BIGINT | Primary key (auto-increment) |
| UserId | UNIQUEIDENTIFIER | User who performed action (FK to Users) |
| Action | NVARCHAR(100) | Action name (USER_LOGIN, API_KEY_CREATED, etc.) |
| EntityType | NVARCHAR(50) | Entity type (User, ApiKey, Role, etc.) |
| EntityId | NVARCHAR(100) | Entity ID |
| OldValues | NVARCHAR(MAX) | Old values (JSON) |
| NewValues | NVARCHAR(MAX) | New values (JSON) |
| IpAddress | NVARCHAR(45) | Client IP |
| UserAgent | NVARCHAR(500) | Client user agent |
| CreatedAt | DATETIME2 | Event timestamp |

**Relationships:**
- FK to `Users(UserId)` (SET NULL on DELETE)

---

## EmailVerificationLogs

**Purpose:** Log email sending attempts for verification

| Column | Type | Description |
|--------|------|-------------|
| Id | BIGINT | Primary key (auto-increment) |
| UserId | UNIQUEIDENTIFIER | User (FK to Users) |
| Email | NVARCHAR(255) | Email address |
| EmailType | NVARCHAR(50) | Email type (VERIFICATION, PASSWORD_RESET, 2FA) |
| Token | NVARCHAR(500) | Token used |
| SentAt | DATETIME2 | Sent timestamp |
| IsVerified | BIT | Verification status |
| VerifiedAt | DATETIME2 | Verification timestamp |
| IpAddress | NVARCHAR(45) | Client IP |

**Relationships:**
- FK to `Users(UserId)` (SET NULL on DELETE)

---

## UserActivityLog

**Purpose:** Track user activities separate from audit (for analytics)

| Column | Type | Description |
|--------|------|-------------|
| Id | BIGINT | Primary key (auto-increment) |
| UserId | UNIQUEIDENTIFIER | User (FK to Users) |
| ActivityType | NVARCHAR(100) | Activity type (LOGIN, LOGOUT, PAGE_VIEW) |
| Description | NVARCHAR(500) | Description |
| Metadata | NVARCHAR(MAX) | Additional data (JSON) |
| IpAddress | NVARCHAR(45) | Client IP |
| UserAgent | NVARCHAR(500) | Client user agent |
| CreatedAt | DATETIME2 | Activity timestamp |

**Relationships:**
- FK to `Users(UserId)` (SET NULL on DELETE)

---

# User Preferences Tables

## UserSettings

**Purpose:** Store user-specific settings (key-value pairs)

| Column | Type | Description |
|--------|------|-------------|
| Id | UNIQUEIDENTIFIER | Primary key |
| UserId | UNIQUEIDENTIFIER | User (FK to Users) |
| SettingKey | NVARCHAR(100) | Setting name |
| SettingValue | NVARCHAR(MAX) | Setting value |
| CreatedAt | DATETIME2 | Creation timestamp |
| UpdatedAt | DATETIME2 | Last update timestamp |

**Relationships:**
- FK to `Users(UserId)` (CASCADE DELETE)

**Common Settings:**
- `language` - UI language (en, th, etc.)
- `timezone` - User timezone
- `theme` - UI theme (light, dark)
- `items_per_page` - Pagination setting
- `date_format` - Date display format

---

## NotificationSettings

**Purpose:** Store per-event notification preferences

| Column | Type | Description |
|--------|------|-------------|
| Id | UNIQUEIDENTIFIER | Primary key |
| UserId | UNIQUEIDENTIFIER | User (FK to Users) |
| EventType | NVARCHAR(100) | Event type |
| EmailEnabled | BIT | Email notification enabled |
| SmsEnabled | BIT | SMS notification enabled |
| PushEnabled | BIT | Push notification enabled |
| InAppEnabled | BIT | In-app notification enabled |
| CreatedAt | DATETIME2 | Creation timestamp |
| UpdatedAt | DATETIME2 | Last update timestamp |

**Relationships:**
- FK to `Users(UserId)` (CASCADE DELETE)

**Event Types:**
- `LOGIN_SUCCESS`, `LOGIN_FAILED`
- `PASSWORD_CHANGED`, `PASSWORD_RESET`
- `EMAIL_VERIFIED`
- `API_KEY_CREATED`, `API_KEY_EXPIRY`, `API_KEY_DELETED`
- `RATE_LIMIT_EXCEEDED`
- `ACCOUNT_LOCKED`
- `ROLE_CHANGED`
- `2FA_ENABLED`, `2FA_DISABLED`

---

# Two-Factor Authentication Tables

## TwoFactorSecrets

**Purpose:** Store 2FA secrets (TOTP)

| Column | Type | Description |
|--------|------|-------------|
| Id | UNIQUEIDENTIFIER | Primary key |
| UserId | UNIQUEIDENTIFIER | User (FK to Users) |
| Secret | NVARCHAR(500) | TOTP secret (base32) |
| IsEnabled | BIT | 2FA enabled status |
| CreatedAt | DATETIME2 | Creation timestamp |
| EnabledAt | DATETIME2 | Enable timestamp |

**Relationships:**
- FK to `Users(UserId)` (CASCADE DELETE)

---

## BackupCodes

**Purpose:** Store 2FA backup codes for account recovery

| Column | Type | Description |
|--------|------|-------------|
| Id | UNIQUEIDENTIFIER | Primary key |
| UserId | UNIQUEIDENTIFIER | User (FK to Users) |
| Code | NVARCHAR(50) | Backup code |
| IsUsed | BIT | Usage status |
| UsedAt | DATETIME2 | Usage timestamp |
| CreatedAt | DATETIME2 | Creation timestamp |

**Relationships:**
- FK to `Users(UserId)` (CASCADE DELETE)

---

# Stored Procedures

## sp_CheckRateLimit

**Purpose:** Check if an API key has exceeded its rate limit

**Parameters:**
- `@ApiKey` (UNIQUEIDENTIFIER) - API key ID
- `@Endpoint` (NVARCHAR(255)) - API endpoint
- `@IsAllowed` (BIT OUTPUT) - Whether request is allowed
- `@RemainingRequests` (INT OUTPUT) - Remaining requests in current period
- `@ResetTime` (DATETIME2 OUTPUT) - When rate limit resets

---

## sp_LogApiUsage

**Purpose:** Log API usage for analytics and rate limiting

**Parameters:**
- `@ApiKey` (UNIQUEIDENTIFIER) - API key ID
- `@UserId` (UNIQUEIDENTIFIER) - User ID
- `@Endpoint` (NVARCHAR(255)) - API endpoint
- `@HttpMethod` (NVARCHAR(10)) - HTTP method
- `@ResponseStatus` (INT) - HTTP response code
- `@ProcessingTimeMs` (INT) - Processing time
- `@RequestSizeBytes` (BIGINT) - Request size
- `@ResponseSizeBytes` (BIGINT) - Response size
- `@IpAddress` (NVARCHAR(45)) - Client IP
- `@UserAgent` (NVARCHAR(500)) - Client user agent

---

## sp_GetUserPermissions

**Purpose:** Get all permissions for a user

**Parameters:**
- `@UserId` (UNIQUEIDENTIFIER) - User ID

**Returns:** List of permission names

---

## sp_CheckUserPermission

**Purpose:** Check if a user has a specific permission

**Parameters:**
- `@UserId` (UNIQUEIDENTIFIER) - User ID
- `@PermissionName` (NVARCHAR(100)) - Permission name
- `@HasPermission` (BIT OUTPUT) - Whether user has permission

---

## sp_ValidateApiKey

**Purpose:** Validate an API key

**Parameters:**
- `@KeyValue` (NVARCHAR(500)) - API key value
- `@IsValid` (BIT OUTPUT) - Whether key is valid
- `@ApiKey` (UNIQUEIDENTIFIER OUTPUT) - API key ID
- `@UserId` (UNIQUEIDENTIFIER OUTPUT) - User ID

---

## sp_LogAudit

**Purpose:** Log an audit event

**Parameters:**
- `@UserId` (UNIQUEIDENTIFIER) - User ID
- `@Action` (NVARCHAR(100)) - Action name
- `@EntityType` (NVARCHAR(50)) - Entity type
- `@EntityId` (NVARCHAR(100)) - Entity ID
- `@OldValues` (NVARCHAR(MAX)) - Old values (JSON)
- `@NewValues` (NVARCHAR(MAX)) - New values (JSON)
- `@IpAddress` (NVARCHAR(45)) - Client IP
- `@UserAgent` (NVARCHAR(500)) - Client user agent

---

## sp_UpdateFailedLogin

**Purpose:** Update failed login count and lock account after 5 attempts

**Parameters:**
- `@Email` (NVARCHAR(255)) - User email
- `@IsSuccess` (BIT) - Whether login was successful

**Behavior:**
- On success: Reset failed count, update last login, clear lock
- On failure: Increment failed count, lock after 5 attempts (30 min lock)

---

## sp_CreateDefaultNotificationSettings

**Purpose:** Create default notification settings for a new user

**Parameters:**
- `@UserId` (UNIQUEIDENTIFIER) - User ID

**Behavior:** Inserts 13 event types with default preferences

---

# Minimal Schema (`init_auth_minimal.sql`)

The minimal schema includes only essential tables for small projects:

1. **Users** - User accounts
2. **Roles** - Role definitions (Admin, User only)
3. **UserRoles** - User-role assignments
4. **ApiKeys** - API keys (simple rate limiting: per hour only)
5. **PasswordResetTokens** - Password reset tokens
6. **AuditLog** - Combined audit + activity logging

**Excluded from minimal:**
- UserRegistrations (use Users.IsEmailVerified instead)
- RefreshTokens (if not using JWT refresh)
- Sessions (if not using session-based auth)
- UserSettings, NotificationSettings
- 2FA (TwoFactorSecrets, BackupCodes)
- EmailVerificationLogs (use AuditLog instead)
- IpWhitelist, IpBlacklist
- UserActivityLog (use AuditLog instead)
- Complex rate limiting (per day/month)

**Stored Procedures (minimal):**
- `sp_ValidateApiKey`
- `sp_UpdateFailedLogin`
- `sp_LogAudit`

---

# Seed Data

## Roles (Full Schema)
1. Admin - Full access
2. User - Standard access
3. ReadOnly - Read-only access
4. ApiUser - API-only access

## Permissions (13 total)
- App: `app.read`, `app.write`
- User: `user.read`, `user.write`, `user.delete`
- ApiKey: `apikey.read`, `apikey.write`, `apikey.delete`, `apikey.view_usage`
- Role: `role.read`, `role.write`, `role.delete`
- Audit: `audit.read`

## Test Data (Development Only)

**Users:**
- `admin@test.com` (Admin role)
- `user@test.com` (User role)
- `readonly@test.com` (ReadOnly role)
- `apiuser@test.com` (ApiUser role)

**Pending Registrations:**
- `pending1@test.com` (valid token)
- `pending2@test.com` (valid token)
- `expired@test.com` (expired token)

**API Keys:**
- Production key (high limits)
- Admin debug key (no expiry)
- Dev sandbox key (medium limits)
- Expired key (inactive)

**IP Blacklist:**
- 1.2.3.4 - Brute force attempts
- 5.6.7.8 - Suspicious bot activity
- 9.10.11.12 - Known malicious IP
- 13.14.15.16 - Temporarily blocked

---

# Database Connection

## Docker Setup

**Database:** TyphoonOcrDB
**Host:** sqlserver (container name)
**Port:** 1433
**User:** sa
**Password:** From `.env.MSSQL_SA_PASSWORD` (default: YourStrong@Passw0rd)

## Adminer

**URL:** http://localhost:8080
**System:** MS SQL
**Server:** sqlserver
**Username:** sa
**Password:** YourStrong@Passw0rd
**Database:** TyphoonOcrDB

---

# Initialization Order

SQL files execute in alphabetical order via `init-db.sh`:

1. `init.sql` - Creates database + OCR tables
2. `init_auth_api.sql` - Creates auth/API tables + seed data
3. `seed_test_data.sql` - (Dev only) Inserts test data

**Note:** `init_auth_minimal.sql` is not auto-run. Use it standalone for small projects.
