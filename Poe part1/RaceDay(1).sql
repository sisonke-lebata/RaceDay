-- ================================================================
-- RACEDAY EVENT MANAGEMENT SYSTEM - DATABASE SCHEMA
-- Part 1: SQL Database Script
-- Author: [Your Name]
-- Date: September 2026
-- ================================================================

-- ================================================================
-- SECTION 1: DROP DATABASE IF EXISTS
-- ================================================================

IF EXISTS (SELECT name FROM sys.databases WHERE name = N'RaceDayDB')
BEGIN
    ALTER DATABASE RaceDayDB SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE RaceDayDB;
END
GO

-- ================================================================
-- SECTION 2: CREATE DATABASE
-- ================================================================

CREATE DATABASE RaceDayDB;
GO

USE RaceDayDB;
GO

-- ================================================================
-- SECTION 3: CREATE TABLES (8 Entities)
-- ================================================================

-- ================================================================
-- TABLE 1: Users
-- Stores user accounts with role-based access
-- ================================================================
CREATE TABLE Users (
    UserID INT IDENTITY(1,1) PRIMARY KEY,
    Email NVARCHAR(255) NOT NULL UNIQUE,
    PasswordHash NVARCHAR(500) NOT NULL,
    FirstName NVARCHAR(100) NOT NULL,
    LastName NVARCHAR(100) NOT NULL,
    Role NVARCHAR(50) NOT NULL CHECK (Role IN ('Organiser', 'Participant')),
    IsActive BIT NOT NULL DEFAULT 1,
    CreatedAt DATETIME NOT NULL DEFAULT GETDATE(),
    UpdatedAt DATETIME NOT NULL DEFAULT GETDATE()
);
GO

-- ================================================================
-- TABLE 2: UserProfiles
-- Extended user information (one-to-one with Users)
-- ================================================================
CREATE TABLE UserProfiles (
    ProfileID INT IDENTITY(1,1) PRIMARY KEY,
    UserID INT NOT NULL UNIQUE,
    PhoneNumber NVARCHAR(20) NULL,
    Bio NVARCHAR(500) NULL,
    EmergencyContactName NVARCHAR(200) NULL,
    EmergencyContactPhone NVARCHAR(20) NULL,
    MedicalConditions NVARCHAR(500) NULL,
    ProfileImageURL NVARCHAR(500) NULL,
    DateOfBirth DATE NULL,
    CONSTRAINT FK_UserProfile_User FOREIGN KEY (UserID) REFERENCES Users(UserID) ON DELETE CASCADE
);
GO

-- ================================================================
-- TABLE 3: Events
-- Main event information
-- ================================================================
CREATE TABLE Events (
    EventID INT IDENTITY(1,1) PRIMARY KEY,
    OrganiserID INT NOT NULL,
    EventName NVARCHAR(200) NOT NULL,
    Description NVARCHAR(1000) NULL,
    EventDate DATETIME NOT NULL,
    RegistrationDeadline DATETIME NOT NULL,
    Location NVARCHAR(300) NOT NULL,
    MaxParticipants INT NOT NULL CHECK (MaxParticipants > 0),
    CurrentParticipants INT NOT NULL DEFAULT 0,
    IsActive BIT NOT NULL DEFAULT 1,
    CreatedAt DATETIME NOT NULL DEFAULT GETDATE(),
    UpdatedAt DATETIME NOT NULL DEFAULT GETDATE(),
    CONSTRAINT FK_Event_Organiser FOREIGN KEY (OrganiserID) REFERENCES Users(UserID)
);
GO

-- ================================================================
-- TABLE 4: Categories
-- Event categories (5km, 10km, Half, Full, Ultra, Cycle)
-- ================================================================
CREATE TABLE Categories (
    CategoryID INT IDENTITY(1,1) PRIMARY KEY,
    CategoryName NVARCHAR(100) NOT NULL UNIQUE,
    Description NVARCHAR(500) NULL,
    Distance DECIMAL(5,2) NOT NULL CHECK (Distance > 0),
    IsActive BIT NOT NULL DEFAULT 1,
    CreatedAt DATETIME NOT NULL DEFAULT GETDATE()
);
GO

-- ================================================================
-- TABLE 5: EventCategories (Junction Table)
-- Many-to-many relationship between Events and Categories
-- ================================================================
CREATE TABLE EventCategories (
    EventCategoryID INT IDENTITY(1,1) PRIMARY KEY,
    EventID INT NOT NULL,
    CategoryID INT NOT NULL,
    Price DECIMAL(10,2) NOT NULL CHECK (Price >= 0),
    MaxParticipantsPerCategory INT NOT NULL CHECK (MaxParticipantsPerCategory > 0),
    CurrentParticipants INT NOT NULL DEFAULT 0,
    IsActive BIT NOT NULL DEFAULT 1,
    CONSTRAINT FK_EventCategory_Event FOREIGN KEY (EventID) REFERENCES Events(EventID) ON DELETE CASCADE,
    CONSTRAINT FK_EventCategory_Category FOREIGN KEY (CategoryID) REFERENCES Categories(CategoryID),
    CONSTRAINT UQ_EventCategory UNIQUE (EventID, CategoryID)
);
GO

-- ================================================================
-- TABLE 6: Enrolments
-- Participant registrations for events
-- ================================================================
CREATE TABLE Enrolments (
    EnrolmentID INT IDENTITY(1,1) PRIMARY KEY,
    UserID INT NOT NULL,
    EventCategoryID INT NOT NULL,
    RegistrationDate DATETIME NOT NULL DEFAULT GETDATE(),
    PaymentStatus NVARCHAR(50) NOT NULL DEFAULT 'Pending' CHECK (PaymentStatus IN ('Pending', 'Paid', 'Cancelled', 'Refunded')),
    EmergencyContactName NVARCHAR(200) NULL,
    EmergencyContactPhone NVARCHAR(20) NULL,
    IsActive BIT NOT NULL DEFAULT 1,
    CreatedAt DATETIME NOT NULL DEFAULT GETDATE(),
    UpdatedAt DATETIME NOT NULL DEFAULT GETDATE(),
    CONSTRAINT FK_Enrolment_User FOREIGN KEY (UserID) REFERENCES Users(UserID),
    CONSTRAINT FK_Enrolment_EventCategory FOREIGN KEY (EventCategoryID) REFERENCES EventCategories(EventCategoryID),
    CONSTRAINT UQ_Enrolment UNIQUE (UserID, EventCategoryID)
);
GO

-- ================================================================
-- TABLE 7: Results
-- Race results for participants
-- ================================================================
CREATE TABLE Results (
    ResultID INT IDENTITY(1,1) PRIMARY KEY,
    EnrolmentID INT NOT NULL UNIQUE,
    FinishTime TIME(3) NULL,
    OverallPosition INT NULL,
    CategoryPosition INT NULL,
    Status NVARCHAR(50) NOT NULL DEFAULT 'Registered' CHECK (Status IN ('Registered', 'Started', 'Finished', 'DNF', 'DNS')),
    Notes NVARCHAR(500) NULL,
    CreatedAt DATETIME NOT NULL DEFAULT GETDATE(),
    UpdatedAt DATETIME NOT NULL DEFAULT GETDATE(),
    CONSTRAINT FK_Result_Enrolment FOREIGN KEY (EnrolmentID) REFERENCES Enrolments(EnrolmentID)
);
GO

-- ================================================================
-- TABLE 8: WeatherLogs
-- Weather data for events
-- ================================================================
CREATE TABLE WeatherLogs (
    WeatherLogID INT IDENTITY(1,1) PRIMARY KEY,
    EventID INT NOT NULL,
    Temperature DECIMAL(5,2) NULL,
    Conditions NVARCHAR(100) NULL,
    WindSpeed DECIMAL(5,2) NULL,
    Humidity DECIMAL(5,2) NULL,
    RecordedAt DATETIME NOT NULL DEFAULT GETDATE(),
    CONSTRAINT FK_WeatherLog_Event FOREIGN KEY (EventID) REFERENCES Events(EventID) ON DELETE CASCADE
);
GO

-- ================================================================
-- SECTION 4: INDEXES (For Performance)
-- ================================================================

CREATE INDEX IX_Users_Email ON Users(Email);
CREATE INDEX IX_Events_EventDate ON Events(EventDate);
CREATE INDEX IX_Events_OrganiserID ON Events(OrganiserID);
CREATE INDEX IX_EventCategories_EventID ON EventCategories(EventID);
CREATE INDEX IX_EventCategories_CategoryID ON EventCategories(CategoryID);
CREATE INDEX IX_Enrolments_UserID ON Enrolments(UserID);
CREATE INDEX IX_Enrolments_EventCategoryID ON Enrolments(EventCategoryID);
CREATE INDEX IX_Results_EnrolmentID ON Results(EnrolmentID);
CREATE INDEX IX_WeatherLogs_EventID ON WeatherLogs(EventID);
GO

-- ================================================================
-- SECTION 5: SAMPLE DATA
-- ================================================================

-- ================================================================
-- 5.1: Insert Users (2 Participants, 1 Organiser)
-- ================================================================
INSERT INTO Users (Email, PasswordHash, FirstName, LastName, Role) VALUES
('thabo.mokoena@gmail.com', '$2a$11$K7LZ5X9Yw2QfR4tU8pV3eO', 'Thabo', 'Mokoena', 'Participant'),
('sarah.vdmerwe@gmail.com', '$2a$11$M9N2P5R8S3T6W7X0Y1Z4A', 'Sarah', 'Van Der Merwe', 'Participant'),
('organiser@raceday.co.za', '$2a$11$P4Q7R9T2U5V8W0X3Y6Z1B', 'RaceDay', 'Organiser', 'Organiser');
GO

-- ================================================================
-- 5.2: Insert User Profiles
-- ================================================================
INSERT INTO UserProfiles (UserID, PhoneNumber, Bio, EmergencyContactName, EmergencyContactPhone, MedicalConditions, DateOfBirth) VALUES
(1, '+27 82 123 4567', 'Passionate runner, completing my 5th Comrades', 'John Mokoena', '+27 82 987 6543', 'None', '1990-05-15'),
(2, '+27 83 234 5678', 'Cyclist and marathon runner, love the Two Oceans', 'Michael Van Der Merwe', '+27 83 876 5432', 'Asthma - carry inhaler', '1988-08-22'),
(3, '+27 84 345 6789', 'RaceDay Event Organiser', 'Jane Organiser', '+27 84 765 4321', 'None', '1985-03-10');
GO

-- ================================================================
-- 5.3: Insert Categories (7 Categories)
-- ================================================================
INSERT INTO Categories (CategoryName, Description, Distance) VALUES
('5km Run', 'Short distance run - perfect for beginners', 5.0),
('10km Run', 'Medium distance run', 10.0),
('21km Half Marathon', 'Half marathon distance', 21.1),
('42km Full Marathon', 'Full marathon distance', 42.2),
('56km Ultra Marathon', 'Ultra marathon distance', 56.0),
('Cycle 100km', '100km cycling route', 100.0),
('Cycle 200km', '200km endurance cycling', 200.0);
GO

-- ================================================================
-- 5.4: Insert Events (3 Events)
-- ================================================================
INSERT INTO Events (OrganiserID, EventName, Description, EventDate, RegistrationDeadline, Location, MaxParticipants, CurrentParticipants) VALUES
(3, 'Comrades Marathon 2026', 'The Ultimate Human Race - 89km from Pietermaritzburg to Durban', '2026-06-14 05:30:00', '2026-05-30 23:59:59', 'Pietermaritzburg to Durban', 25000, 0),
(3, 'Cape Town Cycle Tour 2026', 'The worlds largest timed cycle race', '2026-03-08 06:00:00', '2026-02-20 23:59:59', 'Cape Town', 35000, 0),
(3, 'Two Oceans Marathon 2026', '56km ultra marathon around the Cape Peninsula', '2026-04-11 05:30:00', '2026-03-28 23:59:59', 'Cape Town', 15000, 0);
GO

-- ================================================================
-- 5.5: Insert Event Categories (Linking Events with Categories)
-- ================================================================
INSERT INTO EventCategories (EventID, CategoryID, Price, MaxParticipantsPerCategory, CurrentParticipants) VALUES
-- Comrades Marathon (Event 1)
(1, 1, 350.00, 5000, 0),  -- 5km Run
(1, 4, 750.00, 10000, 0), -- Full Marathon
(1, 5, 950.00, 10000, 0), -- Ultra Marathon
-- Cape Town Cycle Tour (Event 2)
(2, 6, 450.00, 20000, 0), -- Cycle 100km
(2, 7, 650.00, 15000, 0), -- Cycle 200km
-- Two Oceans Marathon (Event 3)
(3, 3, 500.00, 5000, 0),  -- Half Marathon
(3, 4, 700.00, 5000, 0),  -- Full Marathon
(3, 5, 850.00, 5000, 0);  -- Ultra Marathon
GO

-- ================================================================
-- 5.6: Insert Enrolments (Sample Participant Registrations)
-- ================================================================
INSERT INTO Enrolments (UserID, EventCategoryID, PaymentStatus, EmergencyContactName, EmergencyContactPhone) VALUES
(1, 1, 'Paid', 'John Mokoena', '+27 82 987 6543'),  -- Thabo - Comrades 5km
(1, 3, 'Paid', 'John Mokoena', '+27 82 987 6543'),  -- Thabo - Comrades Ultra
(2, 7, 'Pending', 'Michael Van Der Merwe', '+27 83 876 5432'), -- Sarah - Two Oceans Half
(2, 8, 'Paid', 'Michael Van Der Merwe', '+27 83 876 5432'); -- Sarah - Two Oceans Full
GO

-- ================================================================
-- 5.7: Insert Results (Sample Race Results)
-- ================================================================
INSERT INTO Results (EnrolmentID, FinishTime, OverallPosition, CategoryPosition, Status, Notes) VALUES
(1, '00:22:34', 15, 3, 'Finished', 'Personal best for 5km!'),
(2, '05:45:12', 245, 58, 'Finished', 'Great performance, finished strong'),
(4, '04:23:45', 312, 67, 'Finished', 'Good race, consistent pacing');
GO

-- ================================================================
-- 5.8: Insert Weather Logs
-- ================================================================
INSERT INTO WeatherLogs (EventID, Temperature, Conditions, WindSpeed, Humidity) VALUES
(1, 18.5, 'Partly cloudy', 12.0, 65.0),
(1, 22.0, 'Sunny', 8.0, 55.0),
(2, 25.0, 'Clear', 15.0, 45.0),
(2, 28.0, 'Sunny', 10.0, 40.0);
GO

-- ================================================================
-- SECTION 6: VIEWS (For Common Queries)
-- ================================================================

-- ================================================================
-- View 1: Event Details with Category Information
-- ================================================================
CREATE VIEW vw_EventDetails AS
SELECT 
    e.EventID,
    e.EventName,
    e.Description,
    e.EventDate,
    e.RegistrationDeadline,
    e.Location,
    e.MaxParticipants,
    e.CurrentParticipants,
    u.FirstName + ' ' + u.LastName AS OrganiserName,
    c.CategoryID,
    c.CategoryName,
    c.Distance,
    ec.Price,
    ec.MaxParticipantsPerCategory,
    ec.CurrentParticipants AS CurrentCategoryParticipants,
    (ec.MaxParticipantsPerCategory - ec.CurrentParticipants) AS AvailableSlots
FROM Events e
INNER JOIN Users u ON e.OrganiserID = u.UserID
INNER JOIN EventCategories ec ON e.EventID = ec.EventID
INNER JOIN Categories c ON ec.CategoryID = c.CategoryID
WHERE e.IsActive = 1 AND ec.IsActive = 1 AND c.IsActive = 1;
GO

-- ================================================================
-- View 2: User Enrolment History
-- ================================================================
CREATE VIEW vw_UserEnrolments AS
SELECT 
    u.UserID,
    u.Email,
    u.FirstName + ' ' + u.LastName AS FullName,
    e.EventName,
    e.EventDate,
    e.Location,
    c.CategoryName,
    c.Distance,
    en.RegistrationDate,
    en.PaymentStatus,
    r.FinishTime,
    r.OverallPosition,
    r.CategoryPosition,
    r.Status AS ResultStatus,
    r.Notes AS ResultNotes
FROM Users u
INNER JOIN Enrolments en ON u.UserID = en.UserID
INNER JOIN EventCategories ec ON en.EventCategoryID = ec.EventCategoryID
INNER JOIN Events e ON ec.EventID = e.EventID
INNER JOIN Categories c ON ec.CategoryID = c.CategoryID
LEFT JOIN Results r ON en.EnrolmentID = r.EnrolmentID
WHERE en.IsActive = 1;
GO

-- ================================================================
-- SECTION 7: STORED PROCEDURES
-- ================================================================

-- ================================================================
-- Stored Procedure: Enrol Participant in Event
-- ================================================================
CREATE PROCEDURE sp_EnrolParticipant
    @UserID INT,
    @EventCategoryID INT,
    @EmergencyContactName NVARCHAR(200),
    @EmergencyContactPhone NVARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRANSACTION;
    
    BEGIN TRY
        -- Check if event category is active and has available slots
        DECLARE @MaxParticipants INT, @CurrentParticipants INT, @EventID INT;
        
        SELECT 
            @MaxParticipants = ec.MaxParticipantsPerCategory,
            @CurrentParticipants = ec.CurrentParticipants,
            @EventID = ec.EventID
        FROM EventCategories ec
        WHERE ec.EventCategoryID = @EventCategoryID AND ec.IsActive = 1;
        
        IF @MaxParticipants IS NULL
        BEGIN
            RAISERROR('Event category not found or inactive', 16, 1);
            RETURN;
        END
        
        IF @CurrentParticipants >= @MaxParticipants
        BEGIN
            RAISERROR('Event category is fully booked', 16, 1);
            RETURN;
        END
        
        -- Check if user is already enrolled
        IF EXISTS (SELECT 1 FROM Enrolments WHERE UserID = @UserID AND EventCategoryID = @EventCategoryID AND IsActive = 1)
        BEGIN
            RAISERROR('User already enrolled in this event category', 16, 1);
            RETURN;
        END
        
        -- Insert enrolment
        INSERT INTO Enrolments (UserID, EventCategoryID, EmergencyContactName, EmergencyContactPhone, PaymentStatus)
        VALUES (@UserID, @EventCategoryID, @EmergencyContactName, @EmergencyContactPhone, 'Pending');
        
        -- Update participant count in EventCategories
        UPDATE EventCategories
        SET CurrentParticipants = CurrentParticipants + 1
        WHERE EventCategoryID = @EventCategoryID;
        
        -- Update participant count in Events
        UPDATE Events
        SET CurrentParticipants = CurrentParticipants + 1
        WHERE EventID = @EventID;
        
        COMMIT TRANSACTION;
        
        SELECT SCOPE_IDENTITY() AS EnrolmentID;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO

-- ================================================================
-- Stored Procedure: Record Result
-- ================================================================
CREATE PROCEDURE sp_RecordResult
    @EnrolmentID INT,
    @FinishTime TIME(3),
    @Status NVARCHAR(50),
    @Notes NVARCHAR(500) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRANSACTION;
    
    BEGIN TRY
        -- Check if enrolment exists and is active
        IF NOT EXISTS (SELECT 1 FROM Enrolments WHERE EnrolmentID = @EnrolmentID AND IsActive = 1)
        BEGIN
            RAISERROR('Enrolment not found or inactive', 16, 1);
            RETURN;
        END
        
        -- Check if result already exists
        IF EXISTS (SELECT 1 FROM Results WHERE EnrolmentID = @EnrolmentID)
        BEGIN
            -- Update existing result
            UPDATE Results
            SET FinishTime = @FinishTime,
                Status = @Status,
                Notes = @Notes,
                UpdatedAt = GETDATE()
            WHERE EnrolmentID = @EnrolmentID;
        END
        ELSE
        BEGIN
            -- Insert new result
            INSERT INTO Results (EnrolmentID, FinishTime, Status, Notes)
            VALUES (@EnrolmentID, @FinishTime, @Status, @Notes);
        END
        
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO

-- ================================================================
-- SECTION 8: FUNCTIONS
-- ================================================================

-- ================================================================
-- Function: Get Available Categories for Event
-- ================================================================
CREATE FUNCTION fn_GetAvailableCategories(@EventID INT)
RETURNS TABLE
AS
RETURN
(
    SELECT 
        ec.EventCategoryID,
        c.CategoryName,
        c.Distance,
        ec.Price,
        ec.MaxParticipantsPerCategory,
        ec.CurrentParticipants,
        (ec.MaxParticipantsPerCategory - ec.CurrentParticipants) AS AvailableSlots
    FROM EventCategories ec
    INNER JOIN Categories c ON ec.CategoryID = c.CategoryID
    WHERE ec.EventID = @EventID 
        AND ec.IsActive = 1 
        AND ec.CurrentParticipants < ec.MaxParticipantsPerCategory
);
GO

-- ================================================================
-- SECTION 9: TRIGGERS
-- ================================================================

-- ================================================================
-- Trigger: Update Event CurrentParticipants when Enrolment changes
-- ================================================================
CREATE TRIGGER trg_UpdateEventParticipantCount
ON Enrolments
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Update for INSERT
    IF EXISTS (SELECT 1 FROM inserted)
    BEGIN
        UPDATE e
        SET e.CurrentParticipants = (
            SELECT COUNT(DISTINCT en.UserID)
            FROM Enrolments en
            INNER JOIN EventCategories ec ON en.EventCategoryID = ec.EventCategoryID
            WHERE ec.EventID = e.EventID AND en.IsActive = 1
        )
        FROM Events e
        INNER JOIN EventCategories ec ON e.EventID = ec.EventID
        INNER JOIN inserted i ON ec.EventCategoryID = i.EventCategoryID
        WHERE e.IsActive = 1;
    END
    
    -- Update for DELETE
    IF EXISTS (SELECT 1 FROM deleted)
    BEGIN
        UPDATE e
        SET e.CurrentParticipants = (
            SELECT COUNT(DISTINCT en.UserID)
            FROM Enrolments en
            INNER JOIN EventCategories ec ON en.EventCategoryID = ec.EventCategoryID
            WHERE ec.EventID = e.EventID AND en.IsActive = 1
        )
        FROM Events e
        INNER JOIN EventCategories ec ON e.EventID = ec.EventID
        INNER JOIN deleted d ON ec.EventCategoryID = d.EventCategoryID
        WHERE e.IsActive = 1;
    END
END
GO

-- ================================================================
-- SECTION 10: VERIFICATION QUERIES
-- ================================================================

-- Verify Database Creation
SELECT 
    ' Database Created Successfully' AS Status,
    DB_NAME() AS DatabaseName,
    (SELECT COUNT(*) FROM Users) AS UsersCount,
    (SELECT COUNT(*) FROM Events) AS EventsCount,
    (SELECT COUNT(*) FROM Categories) AS CategoriesCount,
    (SELECT COUNT(*) FROM Enrolments) AS EnrolmentsCount,
    (SELECT COUNT(*) FROM Results) AS ResultsCount,
    (SELECT COUNT(*) FROM WeatherLogs) AS WeatherLogsCount;
GO

-- Show all tables
SELECT 
    TABLE_SCHEMA,
    TABLE_NAME,
    '' AS Status
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_TYPE = 'BASE TABLE'
ORDER BY TABLE_NAME;
GO

-- Show sample data from each table
SELECT '?? Users' AS TableName, * FROM Users;
SELECT '?? Events' AS TableName, * FROM Events;
SELECT '?? Categories' AS TableName, * FROM Categories;
SELECT '?? Enrolments' AS TableName, * FROM Enrolments;
SELECT '?? Results' AS TableName, * FROM Results;
SELECT '?? WeatherLogs' AS TableName, * FROM WeatherLogs;
GO

-- ================================================================
-- END OF SCRIPT
-- ================================================================