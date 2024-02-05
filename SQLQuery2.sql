/******************************************* MS SQL JOB START ****************************************/

	-- Yeni bir iş (job) oluşturma
	USE msdb;
	GO

	DECLARE @jobId uniqueidentifier;

	EXEC msdb.dbo.sp_add_job
		@job_name = N'DailyBackupJob',
		@enabled = 1,
		@notify_level_eventlog = 0,
		@notify_level_email = 2,
		@notify_level_netsend = 0,
		@notify_level_page = 0,
		@delete_level = 0,
		@description = N'Daily backup job for XBankDB',
		@category_name = N'Database Maintenance';

	-- İşin bir iş step'ini oluşturma
	EXEC msdb.dbo.sp_add_jobstep
		@job_id = @jobId,
		@step_id = 1,
		@step_name = N'DailyBackupStep',
		@subsystem = N'TSQL',
		@command = N'EXEC dbo.SP_GettingBackUp ''C:\Your\Backup\Test\''',  -- SP_GettingBackUp stored procedure'ünü çağır
		@database_name = N'master',
		@output_file_name = N'C:\Temp\DailyBackupOutput.txt',
		@on_success_action = 3,
		@on_fail_action = 2;

	-- İşi günlük saat 01:00'de çalışacak şekilde ayarlama
	EXEC msdb.dbo.sp_add_schedule
		@schedule_name = N'DailyBackupSchedule',
		@freq_type = 4,
		@freq_interval = 1,
		@active_start_time = 17000;  -- 17:00:00

	-- İşi çalışma sıklığı ile ilişkilendirme
	EXEC msdb.dbo.sp_attach_schedule
		@job_id = @jobId,
		@schedule_id = 1;

	-- İşi başlatma
	EXEC msdb.dbo.sp_start_job @job_id = @jobId;





	
/********************************* View Start *********************************************/


-- View for Admin with all fields
 

CREATE VIEW [dnc].Admin_Accounts
WITH SCHEMABINDING
AS
SELECT AccountID, AccountsTypeID, CustomerID, IsCorporate, IBAN, Balance, CreatedDate, ModifiedDate, IsActive
FROM [dnc].[Accounts]
GO

-- Daha sonra şifrelemek için ALTER VIEW kullanılır
ALTER VIEW [dnc].Admin_Accounts
WITH ENCRYPTION
AS
SELECT AccountID, AccountsTypeID, CustomerID, IsCorporate, IBAN, Balance, CreatedDate, ModifiedDate, IsActive
FROM [dnc].[Accounts]





-- View'ı oluştur
CREATE VIEW [dnc].Admin_AccountsTypes
WITH SCHEMABINDING
AS
SELECT ID, AccountTitle
FROM [dnc].[AccountsTypes]

-- View'ı şifrele
ALTER VIEW [dnc].Admin_AccountsTypes
WITH ENCRYPTION
AS
SELECT ID, AccountTitle
FROM [dnc].[AccountsTypes];





-- View'ı oluştur
CREATE VIEW [dnc].Admin_AccountTransaction
WITH SCHEMABINDING
AS
SELECT  TransactionID, SenderAccount, RecipientAccount, OperationTypeID, Amount, OperationTime, CreatedDate, ModifiedDate, IsActive
FROM [dnc].[AccountTransaction]


-- View'ı şifrele
ALTER VIEW [dnc].Admin_AccountTransaction
WITH ENCRYPTION
AS
SELECT  TransactionID, SenderAccount, RecipientAccount, OperationTypeID, Amount, OperationTime, CreatedDate, ModifiedDate, IsActive
FROM [dnc].[AccountTransaction];




-- View'ı oluştur
CREATE VIEW [dnc].Admin_Balances
WITH SCHEMABINDING
AS
SELECT ID, IBAN, Amount, BalancesTime, CreatedDate, ModifiedDate, IsActive
FROM [dnc].[Balances]

-- View'ı şifrele
ALTER VIEW [dnc].Admin_Balances
WITH ENCRYPTION
AS
SELECT ID, IBAN, Amount, BalancesTime, CreatedDate, ModifiedDate, IsActive
FROM [dnc].[Balances]




-- View'ı oluştur
CREATE VIEW [dnc].Admin_BankCustomer
WITH SCHEMABINDING
AS
SELECT CustomerID, CredentialNO, FirstName, LastName, BirthOfDate, CreatedDate, ModifiedDate, IsActive
FROM [dnc].[BankCustomer]

-- View'ı şifrele
ALTER VIEW [dnc].Admin_BankCustomer
WITH ENCRYPTION
AS
SELECT CustomerID, CredentialNO, FirstName, LastName, BirthOfDate, CreatedDate, ModifiedDate, IsActive
FROM [dnc].[BankCustomer]




-- View'ı oluştur
CREATE VIEW [dnc].Admin_BankCustomerContactInformation
WITH SCHEMABINDING
AS
SELECT ContactID, CustomerID, ContactTypeID, ContactInforamation, CreatedDate, ModifiedDate, IsActive
FROM [dnc].[BankCustomerContactInformation]


-- View'ı şifrele
ALTER VIEW [dnc].Admin_BankCustomerContactInformation
WITH ENCRYPTION
AS
SELECT ContactID, CustomerID, ContactTypeID, ContactInforamation, CreatedDate, ModifiedDate, IsActive
FROM [dnc].[BankCustomerContactInformation]





-- View'ı oluştur
CREATE VIEW [dnc].Admin_BankCustomerLogin
WITH SCHEMABINDING
AS
SELECT LoginID, CustomerID, UserPassword, PasswordSalt, CreatedDate, ModifiedDate, IsActive
FROM [dnc].[BankCustomerLogin]

-- View'ı şifrele
ALTER VIEW [dnc].Admin_BankCustomerLogin
WITH ENCRYPTION
AS
SELECT LoginID, CustomerID, UserPassword, PasswordSalt, CreatedDate, ModifiedDate, IsActive
FROM [dnc].[BankCustomerLogin]





-- View'ı oluştur
CREATE VIEW [dnc].Admin_BankLog
WITH SCHEMABINDING
AS
SELECT LogID, EventDate, LogDescription
FROM [dnc].[BankLog]


-- View'ı şifrele
ALTER VIEW [dnc].Admin_BankLog
WITH ENCRYPTION
AS
SELECT LogID, EventDate, LogDescription
FROM [dnc].[BankLog]





-- View'ı oluştur
CREATE VIEW [dnc].Admin_Bills
WITH SCHEMABINDING
AS
SELECT ID, InstituteID, AccountID, Amount, PaymentStatus, PreviousBillID, CreatedDate, ModifiedDate, IsActive
FROM [dnc].[Bills]


-- View'ı şifrele
ALTER VIEW [dnc].Admin_Bills
WITH ENCRYPTION
AS
SELECT ID, InstituteID, AccountID, Amount, PaymentStatus, PreviousBillID, CreatedDate, ModifiedDate, IsActive
FROM [dnc].[Bills]




-- View'ı oluştur
CREATE VIEW [dnc].Admin_Currency
WITH SCHEMABINDING
AS
SELECT CurrencyID, Unit, Title, CurrencyCode, ForexBuying, ForexSelling, CreatedDate, ModifiedDate, IsActive
FROM [dnc].[Currency]


-- View'ı şifrele
ALTER VIEW [dnc].Admin_Currency
WITH ENCRYPTION
AS
SELECT CurrencyID, Unit, Title, CurrencyCode, ForexBuying, ForexSelling, CreatedDate, ModifiedDate, IsActive
FROM [dnc].[Currency]




-- View'ı oluştur
CREATE VIEW [dnc].Admin_CustomerContactType
WITH SCHEMABINDING
AS
SELECT ID, ContactTitle
FROM [dnc].[CustomerContactType]


-- View'ı şifrele
ALTER VIEW [dnc].Admin_CustomerContactType
WITH ENCRYPTION
AS
SELECT ID, ContactTitle
FROM [dnc].[CustomerContactType]




-- View'ı oluştur
CREATE VIEW [dnc].Admin_Departments
WITH SCHEMABINDING
AS
SELECT DepartmentID, Title, CreatedDate, ModifiedDate, IsActive
FROM [dnc].[Departments]

-- View'ı şifrele
ALTER VIEW [dnc].Admin_Departments
WITH ENCRYPTION
AS
SELECT DepartmentID, Title, CreatedDate, ModifiedDate, IsActive
FROM [dnc].[Departments]




-- View'ı oluştur
CREATE VIEW [dnc].Admin_EmployeeAuthorization
WITH SCHEMABINDING
AS
SELECT AuthorizationID, RoleID, ObjectName, ObjectType, PermissionType, CreatedDate, ModifiedDate, IsActive
FROM [dnc].[EmployeeAuthorization]

-- View'ı şifrele
ALTER VIEW [dnc].Admin_EmployeeAuthorization
WITH ENCRYPTION
AS
SELECT AuthorizationID, RoleID, ObjectName, ObjectType, PermissionType, CreatedDate, ModifiedDate, IsActive
FROM [dnc].[EmployeeAuthorization]




-- View'ı oluştur
CREATE VIEW [dnc].Admin_EmployeeRoles
WITH SCHEMABINDING
AS
SELECT RoleID, Title, CreatedDate, ModifiedDate, IsActive
FROM [dnc].[EmployeeRoles]

-- View'ı şifrele
ALTER VIEW [dnc].Admin_EmployeeRoles
WITH ENCRYPTION
AS
SELECT RoleID, Title, CreatedDate, ModifiedDate, IsActive
FROM [dnc].[EmployeeRoles];




-- View'ı oluştur
CREATE VIEW [dnc].Admin_Employees
WITH SCHEMABINDING
AS
SELECT EmployeeID, FirstName, LastName, RoleID, DepartmentID, CreatedDate, ModifiedDate, IsActive
FROM [dnc].[Employees]

-- View'ı şifrele
ALTER VIEW [dnc].Admin_Employees
WITH ENCRYPTION
AS
SELECT EmployeeID, FirstName, LastName, RoleID, DepartmentID, CreatedDate, ModifiedDate, IsActive
FROM [dnc].[Employees]




-- View'ı oluştur
CREATE VIEW [dnc].Admin_EmployeesLogin
WITH SCHEMABINDING
AS
SELECT LoginID, EmployeeID, UserPassword, PasswordSalt, CreatedDate, ModifiedDate, IsActive
FROM [dnc].[EmployeesLogin]

-- View'ı şifrele
ALTER VIEW [dnc].Admin_EmployeesLogin
WITH ENCRYPTION
AS
SELECT LoginID, EmployeeID, UserPassword, PasswordSalt, CreatedDate, ModifiedDate, IsActive
FROM [dnc].[EmployeesLogin]




-- View'ı oluştur
CREATE VIEW [dnc].Admin_Institute
WITH SCHEMABINDING
AS
SELECT InstituteID, InstituteTitle, CreatedDate, ModifiedDate, IsActive
FROM [dnc].[Institute]

-- View'ı şifrele
ALTER VIEW [dnc].Admin_Institute
WITH ENCRYPTION
AS
SELECT InstituteID, InstituteTitle, CreatedDate, ModifiedDate, IsActive
FROM [dnc].[Institute]




-- View'ı oluştur
CREATE VIEW [dnc].Admin_OperationType
WITH SCHEMABINDING
AS
SELECT ID, OperationTitle
FROM [dnc].[OpearationType]

-- View'ı şifrele
ALTER VIEW [dnc].Admin_OperationType
WITH ENCRYPTION
AS
SELECT ID, OperationTitle
FROM [dnc].[OpearationType]




-- View'ı oluştur
CREATE VIEW [dnc].Admin_UserBankCards
WITH SCHEMABINDING
AS
SELECT CardID, CardNo, ExpirationDate, CvcCode, AccountID, CreatedDate, ModifiedDate, IsActive
FROM [dnc].[UserBankCards]

-- View'ı şifrele
ALTER VIEW [dnc].Admin_UserBankCards
WITH ENCRYPTION
AS
SELECT CardID, CardNo, ExpirationDate, CvcCode, AccountID, CreatedDate, ModifiedDate, IsActive
FROM [dnc].[UserBankCards]




-- View'ı oluştur
CREATE VIEW [dnc].Admin_UserNotification
WITH SCHEMABINDING
AS
SELECT NotificationID, Title, Explanation, CustomerID, CreatedDate, ModifiedDate, IsActive
FROM [dnc].[UserNotification]

-- View'ı şifrele
ALTER VIEW [dnc].Admin_UserNotification
WITH ENCRYPTION
AS
SELECT NotificationID, Title, Explanation, CustomerID, CreatedDate, ModifiedDate, IsActive
FROM [dnc].[UserNotification]




/*************************************** Application Function *****************************************************/

-- Toplam Hesap Bakiyesini Getirme

CREATE FUNCTION dnc.GetTotalBalance(@CustomerID uniqueidentifier)
RETURNS money
AS
BEGIN
    DECLARE @TotalBalance money;

    SELECT @TotalBalance = SUM(Balance)
    FROM [XBankDB].[dnc].[Accounts]
    WHERE CustomerID = @CustomerID AND IsActive = 1;

    RETURN @TotalBalance;
END;


-- Belirli Bir Hesabın İşlem Geçmişini Getirme Fonksiyonu

CREATE FUNCTION dbo.GetAccountTransactionHistory(@AccountID uniqueidentifier)
RETURNS TABLE
AS
RETURN
(
    SELECT *
    FROM [XBankDB].[dnc].[AccountTransaction]
    WHERE SenderAccount = @AccountID OR RecipientAccount = @AccountID
);



-- Belirli Bir Müşterinin Önceki Faturalarını Getirme Fonksiyonu

CREATE FUNCTION dbo.GetCustomerPreviousBills(@CustomerID uniqueidentifier)
RETURNS TABLE
AS
RETURN
(
    SELECT *
    FROM [XBankDB].[dnc].[Bills]
    WHERE AccountID = @CustomerID AND IsActive = 1
)


-- Belirli Bir Tarih Aralığındaki Hesap Hareketlerini Getirme Fonksiyonu

CREATE FUNCTION dbo.GetTransactionsByDateRange(@StartDate datetime, @EndDate datetime)
RETURNS TABLE
AS
RETURN
(
    SELECT *
    FROM [XBankDB].[dnc].[AccountTransaction]
    WHERE OperationTime BETWEEN @StartDate AND @EndDate
)




/*************************************** Application INDEX *****************************************************/

-- Accounts Tablosu İçin Custom Index
-- IsActive alanı üzerinde filtreleme yapılacaksa
CREATE INDEX idx_Accounts_IsActive
ON [dnc].[Accounts](IsActive);

 


--Bills Tablosu İçin Custom Index:
-- CustomerID ve PaymentStatus alanları üzerinde sık sık filtreleme yapılacaksa
CREATE INDEX idx_Bills_CustomerPaymentStatus
ON [XBankDB].[dnc].[Bills](AccountID, PaymentStatus);



--Currency Tablosu İçin Custom Index:
-- CurrencyCode alanı üzerinde sık sık sıralama yapılacaksa
CREATE INDEX idx_Currency_CurrencyCode
ON [XBankDB].[dnc].[Currency](CurrencyCode);
