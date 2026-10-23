CREATE DATABASE OGKS_DB;
GO
USE OGKS_DB;
GO

-- 1. KURUM
CREATE TABLE Institution(
    InstitutionID INT IDENTITY(1,1) PRIMARY KEY,
    Name NVARCHAR(150) NOT NULL,
    Type NVARCHAR(50) NOT NULL,
    City NVARCHAR(50),
    CreatedAt DATETIME DEFAULT GETDATE()
);

-- 2. KULLANICILAR
CREATE TABLE Users(
    UserID INT IDENTITY(1,1) PRIMARY KEY,
    InstitutionID INT NULL FOREIGN KEY REFERENCES Institution(InstitutionID), -- veli için NULL olabilir
    FullName NVARCHAR(100) NOT NULL,
    Email NVARCHAR(100) UNIQUE NOT NULL,
    PasswordHash NVARCHAR(255) NOT NULL,
    Phone NVARCHAR(20) NULL,
    IsActive BIT DEFAULT 1,
    CreatedAt DATETIME DEFAULT GETDATE()
);

-- 3. ROLLER
CREATE TABLE Roles(
    RoleID INT IDENTITY(1,1) PRIMARY KEY,
    RoleName NVARCHAR(50) NOT NULL UNIQUE
);

-- 4. KULLANICI - ROL EŞLEŞMESİ
CREATE TABLE User_Roles(
    UserID INT NOT NULL FOREIGN KEY REFERENCES Users(UserID) ON DELETE CASCADE,
    RoleID INT NOT NULL FOREIGN KEY REFERENCES Roles(RoleID) ON DELETE CASCADE,
    PRIMARY KEY(UserID, RoleID)
);

-- 5. BİREYLER
CREATE TABLE Individuals(
    IndividualID INT IDENTITY(1,1) PRIMARY KEY,
    FullName NVARCHAR(100) NOT NULL,
    TCIdentityNumber NVARCHAR(11) NOT NULL UNIQUE CHECK (LEN(TCIdentityNumber) = 11),
    BirthDate DATE,
    Gender NVARCHAR(10),
    Address NVARCHAR(255),
    IsActive BIT DEFAULT 1,
    CreatedAt DATETIME DEFAULT GETDATE()
);

-- 6. ENGEL / HASTALIK TÜRLERİ
CREATE TABLE Disability_Types(
    DisabilityTypeID INT IDENTITY(1,1) PRIMARY KEY,
    TypeName NVARCHAR(100) NOT NULL,
    Category NVARCHAR(50), -- Nörogelişimsel, Nöromüsküler, Fiziksel, Zihinsel
    Description NVARCHAR(255)
);


-- 7. TANI PROFİLLERİ
CREATE TABLE Diagnosis_Profiles(
    DiagnosisID INT IDENTITY(1,1) PRIMARY KEY,
    IndividualID INT NOT NULL FOREIGN KEY REFERENCES Individuals(IndividualID) ON DELETE CASCADE,
    DisabilityTypeID INT NULL FOREIGN KEY REFERENCES Disability_Types(DisabilityTypeID),
    ICDCode NVARCHAR(20) NOT NULL, -- ör. F84.0 (otizm), G12.0 (SMA tip 1)
    DiagnosisName NVARCHAR(150) NOT NULL,
    SeverityLevel NVARCHAR(50),
    DiagnosedDate DATE
);


-- 8. BAKIM EKİBİ (veli / doktor / uzman eşleşmesi)
CREATE TABLE Care_Team(
    AssignmentID INT IDENTITY(1,1) PRIMARY KEY,
    IndividualID INT NOT NULL FOREIGN KEY REFERENCES Individuals(IndividualID) ON DELETE CASCADE,
    UserID INT NOT NULL FOREIGN KEY REFERENCES Users(UserID) ON DELETE CASCADE,
    RelationType NVARCHAR(50) NOT NULL,
    CONSTRAINT UQ_CareTeam UNIQUE (IndividualID, UserID, RelationType)
);



-- 9. KRİZ TİPLERİ
CREATE TABLE Incident_Types(
    TypeID INT IDENTITY(1,1) PRIMARY KEY,
    DisabilityTypeID INT NULL FOREIGN KEY REFERENCES Disability_Types(DisabilityTypeID),
    TypeName NVARCHAR(100) NOT NULL,
    Description NVARCHAR(255)
);


-- 10. KRİZ / OLAY KAYITLARI
CREATE TABLE Incident_Logs(
    IncidentID INT IDENTITY(1,1) PRIMARY KEY,
    IndividualID INT NOT NULL FOREIGN KEY REFERENCES Individuals(IndividualID),
    TypeID INT NOT NULL FOREIGN KEY REFERENCES Incident_Types(TypeID),
    LoggedByUserID INT NOT NULL FOREIGN KEY REFERENCES Users(UserID),
    SeverityScore INT CHECK (SeverityScore BETWEEN 1 AND 10),
    Triggers NVARCHAR(255) NULL,
    Description NVARCHAR(MAX),
    IncidentDate DATETIME DEFAULT GETDATE()
);


-- 11. RANDEVULAR
CREATE TABLE Appointments(
    AppointmentID INT IDENTITY(1,1) PRIMARY KEY,
    IndividualID INT NOT NULL FOREIGN KEY REFERENCES Individuals(IndividualID) ON DELETE CASCADE,
    SpecialistUserID INT NOT NULL FOREIGN KEY REFERENCES Users(UserID),
    InstitutionID INT NULL FOREIGN KEY REFERENCES Institution(InstitutionID),
    StartTime DATETIME NOT NULL,
    EndTime DATETIME NOT NULL,
    Status NVARCHAR(20) NOT NULL DEFAULT 'Planned'
        CHECK (Status IN ('Planned','Completed','Cancelled','NoShow')),
    Notes NVARCHAR(255),
    CreatedAt DATETIME DEFAULT GETDATE(),
    CONSTRAINT CK_Appointment_Time CHECK (EndTime > StartTime)
);


-- Çakışma önleme: aynı uzman aynı başlangıç saatinde iki aktif randevu alamaz
CREATE UNIQUE INDEX UX_Appointments_NoOverlapStart
    ON Appointments(SpecialistUserID, StartTime)
    WHERE Status <> 'Cancelled';


-- 12. SEANSLAR
CREATE TABLE Sessions(
    SessionID INT IDENTITY(1,1) PRIMARY KEY,
    AppointmentID INT NOT NULL UNIQUE FOREIGN KEY REFERENCES Appointments(AppointmentID) ON DELETE CASCADE,
    Summary NVARCHAR(MAX),
    Attendance NVARCHAR(20) DEFAULT 'Attended'
        CHECK (Attendance IN ('Attended','Late','Absent')),
    CreatedAt DATETIME DEFAULT GETDATE()
);



-- 13. BEP HEDEFLERİ
CREATE TABLE BEP_Goals(
    GoalID INT IDENTITY(1,1) PRIMARY KEY,
    IndividualID INT NOT NULL FOREIGN KEY REFERENCES Individuals(IndividualID) ON DELETE CASCADE,
    CreatedByUserID INT NOT NULL FOREIGN KEY REFERENCES Users(UserID),
    Title NVARCHAR(150) NOT NULL,
    Description NVARCHAR(500),
    StartDate DATE NOT NULL DEFAULT GETDATE(),
    TargetDate DATE,
    Status NVARCHAR(20) NOT NULL DEFAULT 'Active'
        CHECK (Status IN ('Active','Achieved','Paused','Dropped'))
);


-- 14. BEP PUANLARI
CREATE TABLE BEP_Scores(
    ScoreID INT IDENTITY(1,1) PRIMARY KEY,
    GoalID INT NOT NULL FOREIGN KEY REFERENCES BEP_Goals(GoalID) ON DELETE CASCADE,
    SessionID INT NULL FOREIGN KEY REFERENCES Sessions(SessionID),
    ScoredByUserID INT NOT NULL FOREIGN KEY REFERENCES Users(UserID),
    Score INT NOT NULL CHECK (Score BETWEEN 0 AND 100),
    Note NVARCHAR(255),
    ScoreDate DATETIME DEFAULT GETDATE()
);




-- 15. İLAÇLAR
CREATE TABLE Medications(
    MedicationID INT IDENTITY(1,1) PRIMARY KEY,
    IndividualID INT NOT NULL FOREIGN KEY REFERENCES Individuals(IndividualID) ON DELETE CASCADE,
    PrescribedByUserID INT NOT NULL FOREIGN KEY REFERENCES Users(UserID),
    MedicationName NVARCHAR(150) NOT NULL,
    Dose NVARCHAR(50) NOT NULL,
    Frequency NVARCHAR(100) NOT NULL,
    Route NVARCHAR(50), -- oral, intratekal, IV vb.
    StartDate DATE NOT NULL DEFAULT GETDATE(),
    EndDate DATE NULL,
    IsActive BIT DEFAULT 1
);


-- 16. İLAÇ KULLANIM KAYITLARI
CREATE TABLE Medication_Logs(
    LogID INT IDENTITY(1,1) PRIMARY KEY,
    MedicationID INT NOT NULL FOREIGN KEY REFERENCES Medications(MedicationID) ON DELETE CASCADE,
    GivenByUserID INT NOT NULL FOREIGN KEY REFERENCES Users(UserID),
    GivenAt DATETIME NOT NULL DEFAULT GETDATE(),
    Status NVARCHAR(20) NOT NULL DEFAULT 'Given'
        CHECK (Status IN ('Given','Missed','Refused')),
    Note NVARCHAR(255)
);


-- 17. YAN ETKİ RAPORLARI (bakıcı girer, doktor geri bildirim verir)
CREATE TABLE Side_Effect_Reports(
    ReportID INT IDENTITY(1,1) PRIMARY KEY,
    MedicationID INT NOT NULL FOREIGN KEY REFERENCES Medications(MedicationID) ON DELETE CASCADE,
    ReportedByUserID INT NOT NULL FOREIGN KEY REFERENCES Users(UserID),
    Description NVARCHAR(MAX) NOT NULL,
    Severity INT CHECK (Severity BETWEEN 1 AND 5),
    ReportedAt DATETIME DEFAULT GETDATE(),
    DoctorUserID INT NULL FOREIGN KEY REFERENCES Users(UserID),
    DoctorFeedback NVARCHAR(MAX) NULL,
    FeedbackAt DATETIME NULL
);




-- 18. EKİPMAN
CREATE TABLE Equipment(
    EquipmentID INT IDENTITY(1,1) PRIMARY KEY,
    InstitutionID INT NULL FOREIGN KEY REFERENCES Institution(InstitutionID),
    Name NVARCHAR(150) NOT NULL,
    Type NVARCHAR(50) NOT NULL, -- tekerlekli sandalye, ortez, ventilatör, öksürük makinesi, aspiratör, eğitim materyali
    SerialNo NVARCHAR(100) NULL UNIQUE,
    Status NVARCHAR(20) NOT NULL DEFAULT 'Available'
        CHECK (Status IN ('Available','Assigned','Maintenance','Retired')),
    MaintenanceDate DATE NULL
);


-- 19. ZİMMET KAYITLARI
CREATE TABLE Equipment_Assignments(
    AssignmentID INT IDENTITY(1,1) PRIMARY KEY,
    EquipmentID INT NOT NULL FOREIGN KEY REFERENCES Equipment(EquipmentID),
    IndividualID INT NOT NULL FOREIGN KEY REFERENCES Individuals(IndividualID) ON DELETE CASCADE,
    AssignedByUserID INT NOT NULL FOREIGN KEY REFERENCES Users(UserID),
    AssignedDate DATE NOT NULL DEFAULT GETDATE(),
    ReturnDate DATE NULL,
    Note NVARCHAR(255),
    CONSTRAINT CK_Assignment_Dates CHECK (ReturnDate IS NULL OR ReturnDate >= AssignedDate)
);


-- Bir cihaz aynı anda sadece bir kişide olabilir
CREATE UNIQUE INDEX UX_Equipment_ActiveAssignment
    ON Equipment_Assignments(EquipmentID)
    WHERE ReturnDate IS NULL;



-- 20. SMA KLİNİK DETAYLARI (tanıya 1-1 bağlı)
CREATE TABLE SMA_Clinical_Details(
    SMADetailID INT IDENTITY(1,1) PRIMARY KEY,
    DiagnosisID INT NOT NULL UNIQUE FOREIGN KEY REFERENCES Diagnosis_Profiles(DiagnosisID) ON DELETE CASCADE,
    SMAType TINYINT NOT NULL CHECK (SMAType BETWEEN 1 AND 4),
    SMN1Deletion NVARCHAR(30) NULL, -- Homozigot / Heterozigot / Nokta mutasyonu
    SMN2CopyCount TINYINT NULL CHECK (SMN2CopyCount BETWEEN 0 AND 8),
    GeneticTestDate DATE NULL,
    Notes NVARCHAR(255)
);


-- 21. FONKSİYONEL DEĞERLENDİRMELER (HFMSE, CHOP INTEND, RULM)
CREATE TABLE Functional_Assessments(
    AssessmentID INT IDENTITY(1,1) PRIMARY KEY,
    IndividualID INT NOT NULL FOREIGN KEY REFERENCES Individuals(IndividualID) ON DELETE CASCADE,
    AssessedByUserID INT NOT NULL FOREIGN KEY REFERENCES Users(UserID),
    ScaleName NVARCHAR(30) NOT NULL
        CHECK (ScaleName IN ('HFMSE','CHOP INTEND','RULM','6MWT','Diğer')),
    Score DECIMAL(6,2) NOT NULL,
    AssessmentDate DATE NOT NULL DEFAULT GETDATE(),
    Notes NVARCHAR(255)
);


-- 22. SOLUNUM KAYITLARI
CREATE TABLE Respiratory_Logs(
    RespLogID INT IDENTITY(1,1) PRIMARY KEY,
    IndividualID INT NOT NULL FOREIGN KEY REFERENCES Individuals(IndividualID) ON DELETE CASCADE,
    LoggedByUserID INT NOT NULL FOREIGN KEY REFERENCES Users(UserID),
    SpO2 TINYINT NULL CHECK (SpO2 BETWEEN 0 AND 100),
    FVC DECIMAL(5,2) NULL, -- % beklenen değer
    NIVHours DECIMAL(4,1) NULL CHECK (NIVHours BETWEEN 0 AND 24), -- BiPAP/NIV günlük kullanım saati
    CoughAssistUsed BIT DEFAULT 0,
    Notes NVARCHAR(255),
    LogDate DATETIME DEFAULT GETDATE()
);


-- 23. TEDAVİ TAKVİMİ (Spinraza, Zolgensma, Evrysdi vb.)
CREATE TABLE Treatment_Schedules(
    ScheduleID INT IDENTITY(1,1) PRIMARY KEY,
    IndividualID INT NOT NULL FOREIGN KEY REFERENCES Individuals(IndividualID) ON DELETE CASCADE,
    MedicationID INT NULL FOREIGN KEY REFERENCES Medications(MedicationID),
    AppointmentID INT NULL FOREIGN KEY REFERENCES Appointments(AppointmentID), -- Spinraza gibi hastane uygulamaları için
    TreatmentName NVARCHAR(100) NOT NULL,
    Route NVARCHAR(50), -- intratekal, oral, IV
    DoseDate DATE NOT NULL,
    NextDoseDate DATE NULL,
    Status NVARCHAR(20) NOT NULL DEFAULT 'Planned'
        CHECK (Status IN ('Planned','Done','Missed','Cancelled')),
    Notes NVARCHAR(255),
    CONSTRAINT CK_Treatment_Dates CHECK (NextDoseDate IS NULL OR NextDoseDate > DoseDate)
);


-- 24. BÜYÜME KAYITLARI (boy / kilo)
CREATE TABLE Growth_Records(
    GrowthID INT IDENTITY(1,1) PRIMARY KEY,
    IndividualID INT NOT NULL FOREIGN KEY REFERENCES Individuals(IndividualID) ON DELETE CASCADE,
    MeasuredByUserID INT NOT NULL FOREIGN KEY REFERENCES Users(UserID),
    WeightKg DECIMAL(5,2) NULL CHECK (WeightKg > 0),
    HeightCm DECIMAL(5,1) NULL CHECK (HeightCm > 0),
    MeasuredDate DATE NOT NULL DEFAULT GETDATE()
);

CREATE INDEX IX_Incident_Individual_Date   ON Incident_Logs(IndividualID, IncidentDate);
CREATE INDEX IX_Appointments_Individual    ON Appointments(IndividualID, StartTime);
CREATE INDEX IX_BEP_Goals_Individual       ON BEP_Goals(IndividualID);
CREATE INDEX IX_BEP_Scores_Goal            ON BEP_Scores(GoalID, ScoreDate);
CREATE INDEX IX_Medications_Individual     ON Medications(IndividualID);
CREATE INDEX IX_MedLogs_Medication         ON Medication_Logs(MedicationID, GivenAt);
CREATE INDEX IX_SideEffects_Medication     ON Side_Effect_Reports(MedicationID);
CREATE INDEX IX_CareTeam_User              ON Care_Team(UserID);
CREATE INDEX IX_FuncAssess_Individual      ON Functional_Assessments(IndividualID, AssessmentDate);
CREATE INDEX IX_Resp_Individual            ON Respiratory_Logs(IndividualID, LogDate);
CREATE INDEX IX_Treatment_Individual       ON Treatment_Schedules(IndividualID, DoseDate);
CREATE INDEX IX_Growth_Individual          ON Growth_Records(IndividualID, MeasuredDate);

--deneme yazısı