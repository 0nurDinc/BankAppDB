-- Veritabanindan BackUp Alma

CREATE PROCEDURE SP_GettingBackUp(@BackUpFilePath NVARCHAR(2000))
AS
	BEGIN 
		IF TRIM(@BackUpFilePath) <> ''
			BEGIN
				DECLARE @Timestamp NVARCHAR(50) = REPLACE(CONVERT(NVARCHAR, GETDATE(), 120), ':', '')
				DECLARE @BackupFileName NVARCHAR(2000) = 'XBankDbBackUp_' + @Timestamp + '.bak'
				DECLARE @FullBackUpPath NVARCHAR(2000) = @BackUpFilePath + @BackupFileName

				BEGIN TRY
					BACKUP DATABASE XBankDB TO DISK = @FullBackUpPath WITH INIT
					
					INSERT INTO dnc.BankLog(LogDescription) 
						VALUES('Veritabanı yedeği başarı ile alındı. Yedek dosya: ' + @FullBackUpPath)
					
					PRINT 'Veritabanı yedeği başarı ile alındı. Yedek dosya: ' + @FullBackUpPath
				END TRY
				BEGIN CATCH
					INSERT INTO dnc.BankLog(LogDescription)
						VALUES('Veritabanı yedeği alınamadı, Hata Mesajı: ' + ERROR_MESSAGE())

					PRINT '! Veritabanı yedeği alınamadı, Hata Mesajı: ' + ERROR_MESSAGE()
				END CATCH
			END
		ELSE
			BEGIN
				INSERT INTO dnc.BankLog(LogDescription) VALUES ('Geçerli Bir Dosya Yolu Belirtmelisiniz')
				PRINT '! Geçerli Bir Dosya Yolu Belirtmelisiniz'
			END
	END

EXECUTE SP_GettingBackUp 'C:\Your\Backup\Test/'


-- Veritabanindan Script Alma

CREATE PROCEDURE SP_GettingScript(@ScriptFilePath NVARCHAR(2000))
AS
	BEGIN
		IF @ScriptFilePath IS NOT NULL AND TRIM(@ScriptFilePath) <> ''
			BEGIN
				DECLARE @Timestamp NVARCHAR(50) = REPLACE(CONVERT(NVARCHAR, GETDATE(), 120), ':', '')
				DECLARE @ScriptFileName NVARCHAR(2000) = 'XBankDbScript_' + @Timestamp + '.bak'
				DECLARE @FullScriptPath NVARCHAR(2000) = @ScriptFilePath + @ScriptFileName

				BEGIN TRY
					DECLARE @Cmd NVARCHAR(MAX)
					SET @Cmd = 'sqlcmd 
								-S . 
								-d XBankDB 
								-E 
								-Q "EXEC sp_scriptpublicationcustomprocs" 
								-o "' + @FullScriptPath + '"'

					EXEC xp_cmdshell @Cmd;
					
					INSERT INTO dnc.BankLog(LogDescription) 
						VALUES('Veritabanı scripti başarı ile alındı. Script dosya: ' + @FullScriptPath)
					
					PRINT 'Veritabanı scripti başarı ile alındı. Script dosya: ' + @FullScriptPath
				END TRY
				BEGIN CATCH
					INSERT INTO dnc.BankLog(LogDescription)
						VALUES('Veritabanı scripti alınamadı, Hata Mesajı: ' + ERROR_MESSAGE())

					PRINT '! Veritabanı scripti alınamadı, Hata Mesajı: ' + ERROR_MESSAGE()
				END CATCH
			END
		ELSE 
			BEGIN
				INSERT INTO dnc.BankLog(LogDescription) VALUES ('Geçerli Bir Dosya Yolu Belirtmelisiniz')
				PRINT '! Geçerli Bir Dosya Yolu Belirtmelisiniz'
			END
	END

EXECUTE SP_GettingScript 'C:\Your\Backup\Test/'


-- Veritabanına Döviz Kurlarını Çekme

CREATE PROCEDURE SP_GetCurrencyData
AS
BEGIN
	BEGIN TRY
		DECLARE @URL AS VARCHAR(250) = 'https://www.tcmb.gov.tr/kurlar/today.xml',
				@OBJ AS INT,
				@RESULT AS INT

		EXEC @RESULT = SP_OACREATE 'MSXML2.XMLHttp', @OBJ OUT 
		EXEC @RESULT = SP_OAMethod @OBJ, 'open', NULL, 'GET', @URL, false
		EXEC @RESULT = SP_OAMethod @OBJ, 'SEND', NULL, ''

		CREATE TABLE #TEMPXML (STRXML VARCHAR(MAX))
		INSERT INTO #TEMPXML (STRXML) EXEC @RESULT = SP_OAGetProperty @OBJ, 'ResponseXML.xml'

		DECLARE @XML AS XML
		SELECT @XML = STRXML FROM #TEMPXML
		DROP TABLE #TEMPXML

		DECLARE @HDOC AS INT
		EXEC SP_XML_PREPAREDOCUMENT @HDOC OUTPUT, @XML

		-- Tüm veriler siliniyor
		DELETE FROM dnc.Currency

		INSERT INTO dnc.Currency (Unit, Title, CurrencyCode, ForexBuying, ForexSelling)
		-- Veriler yeniden ekleniyor
		SELECT 
			Unit = T.c.value('(Unit)[1]', 'VARCHAR(50)'),
			Title = T.c.value('(Isim)[1]', 'VARCHAR(50)'),
			CurrencyCode = T.c.value('@Kod', 'VARCHAR(50)'),
			ForexBuying = T.c.value('(ForexBuying)[1]', 'FLOAT'),
			ForexSelling = T.c.value('(ForexSelling)[1]', 'FLOAT')
		FROM @XML.nodes('/Tarih_Date/Currency') AS T(c)

		INSERT INTO dnc.BankLog(LogDescription) VALUES ('Döviz Kurları çekimi Başarıyla Gerçekleşti.')
		PRINT 'Döviz Kurları çekimi Başarıyla Gerçekleşti.'

	END TRY
	BEGIN CATCH
			INSERT INTO dnc.BankLog(LogDescription) VALUES ('Döviz Kurları çekiminde Bir Hata Meydana Geldi. Hata Mesajı: ' + ERROR_MESSAGE())
			PRINT '! Döviz Kurları çekiminde Bir Hata Meydana Geldi. Hata Mesajı: ' + ERROR_MESSAGE()
	END CATCH
END

EXECUTE SP_GetCurrencyData





-------------------------- Account Stored Procedure -------------------------


-- ListAccounts Procedure
CREATE PROCEDURE ListAccounts
AS
BEGIN
    BEGIN TRY
        SELECT AccountID, AccountsTypeID, CustomerID, IsCorporate, IBAN, Balance
        FROM [XBankDB].[dnc].[Accounts]

        -- Başarılı işlem logu
        INSERT INTO dnc.BankLog(LogDescription) VALUES ('Hesap Listeleme İşlemi Başarılı')
        PRINT 'Hesap Listeleme İşlemleri Başarılı'
    END TRY
    BEGIN CATCH
        -- Hata durumunda yapılacak işlemler buraya yazılır
        INSERT INTO dnc.BankLog(LogDescription) VALUES ('! Hesapları Listelerken Hata Meydana Geldi. Hata: ' + ERROR_MESSAGE())
        PRINT '! Hesapları Listelerken Hata Meydana Geldi. Hata: ' + ERROR_MESSAGE()
    END CATCH
END



-- FilterAccounts Procedure
CREATE PROCEDURE FilterAccounts(
    @AccountsTypeID smallint = NULL,
    @CustomerID uniqueidentifier = NULL,
    @IsCorporate bit = NULL,
    @IBAN nvarchar(26) = NULL,
    @Balance money = NULL
)
AS
BEGIN
    BEGIN TRY
        SELECT AccountID, AccountsTypeID, CustomerID, IsCorporate, IBAN, Balance
        FROM [XBankDB].[dnc].[Accounts]
        WHERE
            (@AccountsTypeID IS NULL OR AccountsTypeID = @AccountsTypeID) AND
            (@CustomerID IS NULL OR CustomerID = @CustomerID) AND
            (@IsCorporate IS NULL OR IsCorporate = @IsCorporate) AND
            (@IBAN IS NULL OR IBAN = @IBAN) AND
            (@Balance IS NULL OR Balance = @Balance)

             INSERT INTO dnc.BankLog(LogDescription) VALUES ('Hesap Listeleme İşlemi Başarılı')
             PRINT 'Hesap Listeleme İşlemleri Başarılı'
    END TRY
    BEGIN CATCH
            INSERT INTO dnc.BankLog(LogDescription) VALUES ('! Hesapları Listelerken Hata Meydana Geldi. Hata: ' + ERROR_MESSAGE())
            PRINT '! Hesapları Listelerken Hata Meydana Geldi. Hata: ' + ERROR_MESSAGE()
    END CATCH
END



-- GetAccountByID Procedure
CREATE PROCEDURE GetAccountByID
    @AccountID uniqueidentifier
AS
BEGIN
    BEGIN TRY
        SELECT AccountID, AccountsTypeID, CustomerID, IsCorporate, IBAN, Balance
        FROM [XBankDB].[dnc].[Accounts]
        WHERE AccountID = @AccountID

             INSERT INTO dnc.BankLog(LogDescription) VALUES ('Hesap Listesindeki Hesap İşlemi Başarılı Bir Şekilde Geldi.')
             PRINT 'Hesap Listesindeki Hesap İşlemi Başarılı Bir Şekilde Geldi.'
    END TRY
    BEGIN CATCH
            INSERT INTO dnc.BankLog(LogDescription) VALUES (' Hesap Listesindeki Hesabı Getiriken Hata Meydana Geldi. Hata: ' + ERROR_MESSAGE())
            PRINT '! Hesap Listesindeki Hesabı Getiriken Hata Meydana Geldi. Hata: ' + ERROR_MESSAGE()
    END CATCH
END




-- AddAccount Procedure
CREATE PROCEDURE AddAccount
    @AccountsTypeID smallint,
    @CustomerID uniqueidentifier,
    @IsCorporate bit,
    @IBAN nvarchar(26),
    @Balance money
AS
BEGIN
    BEGIN TRY
        INSERT INTO [XBankDB].[dnc].[Accounts] (AccountsTypeID, CustomerID, IsCorporate, IBAN, Balance)
        VALUES (@AccountsTypeID, @CustomerID, @IsCorporate, @IBAN, @Balance)

        -- Başarılı işlem logu
        INSERT INTO dnc.BankLog(LogDescription) VALUES ('Hesap Ekleme İşlemi Başarılı')
        PRINT 'Hesap Ekleme İşlemleri Başarılı'
    END TRY
    BEGIN CATCH
        INSERT INTO dnc.BankLog(LogDescription) VALUES ('Hesap Ekleme İşlemi Başarısız. Hata: ' + ERROR_MESSAGE())
        PRINT '! Hesap Ekleme İşlemi Başarısız. Hata: ' + ERROR_MESSAGE()
    END CATCH
END




-- UpdateAccount Procedure
CREATE PROCEDURE UpdateAccount
    @AccountID uniqueidentifier,
    @AccountsTypeID smallint,
    @CustomerID uniqueidentifier,
    @IsCorporate bit,
    @IBAN nvarchar(26),
    @Balance money
AS
BEGIN
    BEGIN TRY
        UPDATE [XBankDB].[dnc].[Accounts]
        SET AccountsTypeID = @AccountsTypeID,
            CustomerID = @CustomerID,
            IsCorporate = @IsCorporate,
            IBAN = @IBAN,
            Balance = @Balance,
            ModifiedDate = GETDATE()
        WHERE AccountID = @AccountID

        -- Başarılı işlem logu
        INSERT INTO dnc.BankLog(LogDescription) VALUES ('Hesap Güncelleme İşlemi Başarılı')
        PRINT 'Hesap Güncelleme İşlemleri Başarılı'
    END TRY
    BEGIN CATCH
        INSERT INTO dnc.BankLog(LogDescription) VALUES ('Hesap Güncelleme İşlemi Başarısız. Hata: ' + ERROR_MESSAGE())
        PRINT '! Hesap Güncelleme İşlemi Başarısız. Hata: ' + ERROR_MESSAGE()
    END CATCH
END




-- SoftDeleteAccount Procedure
CREATE PROCEDURE SoftDeleteAccount
    @AccountID uniqueidentifier
AS
BEGIN
    BEGIN TRY
        -- Burada sadece IsActive değerini güncelliyoruz
        UPDATE [XBankDB].[dnc].[Accounts]
        SET IsActive = 0
        WHERE AccountID = @AccountID

        -- Başarılı işlem logu
        INSERT INTO dnc.BankLog(LogDescription) VALUES ('Hesap Silme İşlemi Başarılı')
        PRINT 'Hesap Silme İşlemleri Başarılı'
    END TRY
    BEGIN CATCH
         INSERT INTO dnc.BankLog(LogDescription) VALUES ('Hesap Silme İşlemi Başarısız. Hata: ' + ERROR_MESSAGE())
         PRINT '!  Hesap Silme İşlemi Başarısız. Hata: ' + ERROR_MESSAGE()
    END CATCH
END


-- HardDeleteAccount Procedure
CREATE PROCEDURE HardDeleteAccount
    @AccountID uniqueidentifier
AS
BEGIN
    BEGIN TRY
        DELETE FROM [XBankDB].[dnc].[Accounts]
        WHERE AccountID = @AccountID

        -- Başarılı işlem logu
        INSERT INTO dnc.BankLog(LogDescription) VALUES ('Hesap Kalıcı Silme İşlemi Başarılı')
        PRINT 'Hesap Kalıcı Silme İşlemleri Başarılı'
    END TRY
    BEGIN CATCH
        INSERT INTO dnc.BankLog(LogDescription) VALUES ('Hesap Silme İşlemi Başarısız. Hata: ' + ERROR_MESSAGE())
        PRINT '!  Hesap Silme İşlemi Başarısız. Hata: ' + ERROR_MESSAGE()
    END CATCH
END




--------------------------- AccountsTypes Stored Procedure ----------------------------


-- ListAccountsTypes Procedure
CREATE PROCEDURE ListAccountsTypes
AS
BEGIN
    BEGIN TRY
        SELECT ID, AccountTitle
        FROM [XBankDB].[dnc].[AccountsTypes]

        -- Başarılı işlem logu
        INSERT INTO dnc.BankLog(LogDescription) VALUES ('Hesap Türleri Listeleme İşlemi Başarılı')
        PRINT 'Hesap Türleri Listeleme İşlemleri Başarılı'
    END TRY
    BEGIN CATCH
        -- Hata durumunda yapılacak işlemler buraya yazılır
        INSERT INTO dnc.BankLog(LogDescription) VALUES ('! Hesap Türlerini Listelerken Hata Meydana Geldi. Hata: ' + ERROR_MESSAGE())
        PRINT '! Hesap Türlerini Listelerken Hata Meydana Geldi. Hata: ' + ERROR_MESSAGE()
    END CATCH
END

-- FilterAccountsTypes Procedure
CREATE PROCEDURE FilterAccountsTypes
    @AccountTitle nvarchar(400) = NULL
AS
BEGIN
    BEGIN TRY
        SELECT ID, AccountTitle
        FROM [XBankDB].[dnc].[AccountsTypes]
        WHERE
            (@AccountTitle IS NULL OR AccountTitle = @AccountTitle)

        INSERT INTO dnc.BankLog(LogDescription) VALUES ('Hesap Türleri Listeleme İşlemi Başarılı')
        PRINT 'Hesap Türleri Listeleme İşlemleri Başarılı'
    END TRY
    BEGIN CATCH
        INSERT INTO dnc.BankLog(LogDescription) VALUES ('! Hesap Türlerini Listelerken Hata Meydana Geldi. Hata: ' + ERROR_MESSAGE())
        PRINT '! Hesap Türlerini Listelerken Hata Meydana Geldi. Hata: ' + ERROR_MESSAGE()
    END CATCH
END


-- GetAccountTypeByID Procedure
CREATE PROCEDURE GetAccountTypeByID
    @ID smallint
AS
BEGIN
    BEGIN TRY
        SELECT ID, AccountTitle
        FROM [XBankDB].[dnc].[AccountsTypes]
        WHERE ID = @ID

        INSERT INTO dnc.BankLog(LogDescription) VALUES ('Hesap Türü Listeleme İşlemi Başarılı Bir Şekilde Geldi.')
        PRINT 'Hesap Türü Listeleme İşlemi Başarılı Bir Şekilde Geldi.'
    END TRY
    BEGIN CATCH
        INSERT INTO dnc.BankLog(LogDescription) VALUES (' Hesap Türü Listesindeki Hesabı Getiriken Hata Meydana Geldi. Hata: ' + ERROR_MESSAGE())
        PRINT '! Hesap Türü Listesindeki Hesabı Getiriken Hata Meydana Geldi. Hata: ' + ERROR_MESSAGE()
    END CATCH
END

-- AddAccountType Procedure
CREATE PROCEDURE AddAccountType
    @AccountTitle nvarchar(400)
AS
BEGIN
    BEGIN TRY
        INSERT INTO [XBankDB].[dnc].[AccountsTypes] (AccountTitle)
        VALUES (@AccountTitle)

        -- Başarılı işlem logu
        INSERT INTO dnc.BankLog(LogDescription) VALUES ('Hesap Türü Ekleme İşlemi Başarılı')
        PRINT 'Hesap Türü Ekleme İşlemleri Başarılı'
    END TRY
    BEGIN CATCH
        INSERT INTO dnc.BankLog(LogDescription) VALUES ('Hesap Türü Ekleme İşlemi Başarısız. Hata: ' + ERROR_MESSAGE())
        PRINT '! Hesap Türü Ekleme İşlemi Başarısız. Hata: ' + ERROR_MESSAGE()
    END CATCH
END

-- UpdateAccountType Procedure
CREATE PROCEDURE UpdateAccountType
    @ID smallint,
    @AccountTitle nvarchar(400)
AS
BEGIN
    BEGIN TRY
        UPDATE [XBankDB].[dnc].[AccountsTypes]
        SET AccountTitle = @AccountTitle
        WHERE ID = @ID

        -- Başarılı işlem logu
        INSERT INTO dnc.BankLog(LogDescription) VALUES ('Hesap Türü Güncelleme İşlemi Başarılı')
        PRINT 'Hesap Türü Güncelleme İşlemleri Başarılı'
    END TRY
    BEGIN CATCH
        INSERT INTO dnc.BankLog(LogDescription) VALUES ('Hesap Türü Güncelleme İşlemi Başarısız. Hata: ' + ERROR_MESSAGE())
        PRINT '! Hesap Türü Güncelleme İşlemi Başarısız. Hata: ' + ERROR_MESSAGE()
    END CATCH
END

 

-- HardDeleteAccountType Procedure
CREATE PROCEDURE HardDeleteAccountType
    @ID smallint
AS
BEGIN
    BEGIN TRY
        DELETE FROM [XBankDB].[dnc].[AccountsTypes]
        WHERE ID = @ID

        -- Başarılı işlem logu
        INSERT INTO dnc.BankLog(LogDescription) VALUES ('Hesap Türü Kalıcı Silme İşlemi Başarılı')
        PRINT 'Hesap Türü Kalıcı Silme İşlemleri Başarılı'
    END TRY
    BEGIN CATCH
        INSERT INTO dnc.BankLog(LogDescription) VALUES ('Hesap Türü Silme İşlemi Başarısız. Hata: ' + ERROR_MESSAGE())
        PRINT '!  Hesap Türü Silme İşlemi Başarısız. Hata: ' + ERROR_MESSAGE()
    END CATCH
END



--------------------------- Accounts Transaction Stored Procedure ----------------------------

-- ListAccountTransactions Procedure

CREATE PROCEDURE ListAccountTransactions
AS
BEGIN
    BEGIN TRY
        SELECT TransactionID, SenderAccount, RecipientAccount, OperationTypeID, Amount, OperationTime, CreatedDate, ModifiedDate, IsActive
        FROM [XBankDB].[dnc].[AccountTransaction]

        -- Başarılı işlem logu
        INSERT INTO dnc.BankLog(LogDescription) VALUES ('Hesap İşlemleri Listeleme İşlemi Başarılı')
        PRINT 'Hesap İşlemleri Listeleme İşlemleri Başarılı'
    END TRY
    BEGIN CATCH
        -- Hata durumunda yapılacak işlemler buraya yazılır
        INSERT INTO dnc.BankLog(LogDescription) VALUES ('! Hesap İşlemlerini Listelerken Hata Meydana Geldi. Hata: ' + ERROR_MESSAGE())
        PRINT '! Hesap İşlemlerini Listelerken Hata Meydana Geldi. Hata: ' + ERROR_MESSAGE()
    END CATCH
END


-- FilterAccountTransactions Procedure

CREATE PROCEDURE FilterAccountTransactions
    @SenderAccount nvarchar(26) = NULL,
    @RecipientAccount nvarchar(26) = NULL,
    @OperationTypeID smallint = NULL,
    @Amount money = NULL,
    @OperationTime datetime = NULL
AS
BEGIN
    BEGIN TRY
        SELECT TransactionID, SenderAccount, RecipientAccount, OperationTypeID, Amount, OperationTime, CreatedDate, ModifiedDate, IsActive
        FROM [XBankDB].[dnc].[AccountTransaction]
        WHERE
            (@SenderAccount IS NULL OR SenderAccount = @SenderAccount) AND
            (@RecipientAccount IS NULL OR RecipientAccount = @RecipientAccount) AND
            (@OperationTypeID IS NULL OR OperationTypeID = @OperationTypeID) AND
            (@Amount IS NULL OR Amount = @Amount) AND
            (@OperationTime IS NULL OR OperationTime = @OperationTime)

        INSERT INTO dnc.BankLog(LogDescription) VALUES ('Hesap İşlemleri Listeleme İşlemi Başarılı')
        PRINT 'Hesap İşlemleri Listeleme İşlemleri Başarılı'
    END TRY
    BEGIN CATCH
        INSERT INTO dnc.BankLog(LogDescription) VALUES ('! Hesap İşlemlerini Listelerken Hata Meydana Geldi. Hata: ' + ERROR_MESSAGE())
        PRINT '! Hesap İşlemlerini Listelerken Hata Meydana Geldi. Hata: ' + ERROR_MESSAGE()
    END CATCH
END

-- GetAccountTransactionByID Procedure

CREATE PROCEDURE GetAccountTransactionByID
    @TransactionID uniqueidentifier
AS
BEGIN
    BEGIN TRY
        SELECT TransactionID, SenderAccount, RecipientAccount, OperationTypeID, Amount, OperationTime, CreatedDate, ModifiedDate, IsActive
        FROM [XBankDB].[dnc].[AccountTransaction]
        WHERE TransactionID = @TransactionID

        INSERT INTO dnc.BankLog(LogDescription) VALUES ('Hesap İşlemleri Listesindeki İşlem İşlemi Başarılı Bir Şekilde Geldi.')
        PRINT 'Hesap İşlemleri Listesindeki İşlem İşlemi Başarılı Bir Şekilde Geldi.'
    END TRY
    BEGIN CATCH
        INSERT INTO dnc.BankLog(LogDescription) VALUES (' Hesap İşlemleri Listesindeki İşlemi Getiriken Hata Meydana Geldi. Hata: ' + ERROR_MESSAGE())
        PRINT '! Hesap İşlemleri Listesindeki İşlemi Getiriken Hata Meydana Geldi. Hata: ' + ERROR_MESSAGE()
    END CATCH
END

-- AddAccountTransaction Procedure

CREATE PROCEDURE AddAccountTransaction
    @SenderAccount nvarchar(26),
    @RecipientAccount nvarchar(26) = NULL,
    @OperationTypeID smallint,
    @Amount money,
    @OperationTime datetime
AS
BEGIN
    BEGIN TRY
        INSERT INTO [XBankDB].[dnc].[AccountTransaction] (SenderAccount, RecipientAccount, OperationTypeID, Amount, OperationTime, CreatedDate)
        VALUES (@SenderAccount, @RecipientAccount, @OperationTypeID, @Amount, @OperationTime, GETDATE())

        -- Başarılı işlem logu
        INSERT INTO dnc.BankLog(LogDescription) VALUES ('Hesap İşlemi Ekleme İşlemi Başarılı')
        PRINT 'Hesap İşlemi Ekleme İşlemleri Başarılı'
    END TRY
    BEGIN CATCH
        INSERT INTO dnc.BankLog(LogDescription) VALUES ('Hesap İşlemi Ekleme İşlemi Başarısız. Hata: ' + ERROR_MESSAGE())
        PRINT '! Hesap İşlemi Ekleme İşlemi Başarısız. Hata: ' + ERROR_MESSAGE()
    END CATCH
END

-- UpdateAccountTransaction Procedure
CREATE PROCEDURE UpdateAccountTransaction
    @TransactionID uniqueidentifier,
    @SenderAccount nvarchar(26),
    @RecipientAccount nvarchar(26) = NULL,
    @OperationTypeID smallint,
    @Amount money,
    @OperationTime datetime
AS
BEGIN
    BEGIN TRY
        UPDATE [XBankDB].[dnc].[AccountTransaction]
        SET SenderAccount = @SenderAccount,
            RecipientAccount = @RecipientAccount,
            OperationTypeID = @OperationTypeID,
            Amount = @Amount,
            OperationTime = @OperationTime,
            ModifiedDate = GETDATE()
        WHERE TransactionID = @TransactionID

        -- Başarılı işlem logu
        INSERT INTO dnc.BankLog(LogDescription) VALUES ('Hesap İşlemi Güncelleme İşlemi Başarılı')
        PRINT 'Hesap İşlemi Güncelleme İşlemleri Başarılı'
    END TRY
    BEGIN CATCH
        INSERT INTO dnc.BankLog(LogDescription) VALUES ('Hesap İşlemi Güncelleme İşlemi Başarısız. Hata: ' + ERROR_MESSAGE())
        PRINT '! Hesap İşlemi Güncelleme İşlemi Başarısız. Hata: ' + ERROR_MESSAGE()
    END CATCH
END

-- SoftDeleteAccountTransaction Procedure
CREATE PROCEDURE SoftDeleteAccountTransaction
    @TransactionID uniqueidentifier
AS
BEGIN
    BEGIN TRY
        -- Burada sadece IsActive değerini güncelliyoruz
        UPDATE [XBankDB].[dnc].[AccountTransaction]
        SET IsActive = 0
        WHERE TransactionID = @TransactionID

        -- Başarılı işlem logu
        INSERT INTO dnc.BankLog(LogDescription) VALUES ('Hesap İşlemi Silme İşlemi Başarılı')
        PRINT 'Hesap İşlemi Silme İşlemleri Başarılı'
    END TRY
    BEGIN CATCH
        INSERT INTO dnc.BankLog(LogDescription) VALUES ('Hesap İşlemi Silme İşlemi Başarısız. Hata: ' + ERROR_MESSAGE())
        PRINT '! Hesap İşlemi Silme İşlemi Başarısız. Hata: ' + ERROR_MESSAGE()
    END CATCH
END

-- HardDeleteAccountTransaction Procedure
CREATE PROCEDURE HardDeleteAccountTransaction
    @TransactionID uniqueidentifier
AS
BEGIN
    BEGIN TRY
        DELETE FROM [XBankDB].[dnc].[AccountTransaction]
        WHERE TransactionID = @TransactionID

        -- Başarılı işlem logu
        INSERT INTO dnc.BankLog(LogDescription) VALUES ('Hesap İşlemi Kalıcı Silme İşlemi Başarılı')
        PRINT 'Hesap İşlemi Kalıcı Silme İşlemleri Başarılı'
    END TRY
    BEGIN CATCH
        INSERT INTO dnc.BankLog(LogDescription) VALUES ('Hesap İşlemi Silme İşlemi Başarısız. Hata: ' + ERROR_MESSAGE())
        PRINT '!  Hesap İşlemi Silme İşlemi Başarısız. Hata: ' + ERROR_MESSAGE()
    END CATCH
END



--------------------------- Balances Stored Procedure ----------------------------


-- ListBalances Procedure
CREATE PROCEDURE ListBalances
AS
BEGIN
    BEGIN TRY
        SELECT ID, IBAN, Amount, BalancesTime, CreatedDate, ModifiedDate, IsActive
        FROM [XBankDB].[dnc].[Balances]

        -- Başarılı işlem logu
        INSERT INTO dnc.BankLog(LogDescription) VALUES ('Bakiyeleri Listeleme İşlemi Başarılı')
        PRINT 'Bakiyeleri Listeleme İşlemleri Başarılı'
    END TRY
    BEGIN CATCH
        -- Hata durumunda yapılacak işlemler buraya yazılır
        INSERT INTO dnc.BankLog(LogDescription) VALUES ('! Bakiyeleri Listelerken Hata Meydana Geldi. Hata: ' + ERROR_MESSAGE())
        PRINT '! Bakiyeleri Listelerken Hata Meydana Geldi. Hata: ' + ERROR_MESSAGE()
    END CATCH
END

-- FilterBalances Procedure
CREATE PROCEDURE FilterBalances
    @IBAN nvarchar(26) = NULL,
    @Amount money = NULL,
    @BalancesTime datetime = NULL
AS
BEGIN
    BEGIN TRY
        SELECT ID, IBAN, Amount, BalancesTime, CreatedDate, ModifiedDate, IsActive
        FROM [XBankDB].[dnc].[Balances]
        WHERE
            (@IBAN IS NULL OR IBAN = @IBAN) AND
            (@Amount IS NULL OR Amount = @Amount) AND
            (@BalancesTime IS NULL OR BalancesTime = @BalancesTime)

        INSERT INTO dnc.BankLog(LogDescription) VALUES ('Bakiyeleri Listeleme İşlemi Başarılı')
        PRINT 'Bakiyeleri Listeleme İşlemleri Başarılı'
    END TRY
    BEGIN CATCH
        INSERT INTO dnc.BankLog(LogDescription) VALUES ('! Bakiyeleri Listelerken Hata Meydana Geldi. Hata: ' + ERROR_MESSAGE())
        PRINT '! Bakiyeleri Listelerken Hata Meydana Geldi. Hata: ' + ERROR_MESSAGE()
    END CATCH
END

-- GetBalanceByID Procedure
CREATE PROCEDURE GetBalanceByID
    @ID uniqueidentifier
AS
BEGIN
    BEGIN TRY
        SELECT ID, IBAN, Amount, BalancesTime, CreatedDate, ModifiedDate, IsActive
        FROM [XBankDB].[dnc].[Balances]
        WHERE ID = @ID

        INSERT INTO dnc.BankLog(LogDescription) VALUES ('Bakiyeler Listesindeki Bakiye İşlemi Başarılı Bir Şekilde Geldi.')
        PRINT 'Bakiyeler Listesindeki Bakiye İşlemi Başarılı Bir Şekilde Geldi.'
    END TRY
    BEGIN CATCH
        INSERT INTO dnc.BankLog(LogDescription) VALUES (' Bakiyeler Listesindeki Bakiyeyi Getiriken Hata Meydana Geldi. Hata: ' + ERROR_MESSAGE())
        PRINT '! Bakiyeler Listesindeki Bakiyeyi Getiriken Hata Meydana Geldi. Hata: ' + ERROR_MESSAGE()
    END CATCH
END

-- AddBalance Procedure
CREATE PROCEDURE AddBalance
    @IBAN nvarchar(26),
    @Amount money,
    @BalancesTime datetime
AS
BEGIN
    BEGIN TRY
        INSERT INTO [XBankDB].[dnc].[Balances] (IBAN, Amount, BalancesTime, CreatedDate)
        VALUES (@IBAN, @Amount, @BalancesTime, GETDATE())

        -- Başarılı işlem logu
        INSERT INTO dnc.BankLog(LogDescription) VALUES ('Bakiye Ekleme İşlemi Başarılı')
        PRINT 'Bakiye Ekleme İşlemleri Başarılı'
    END TRY
    BEGIN CATCH
        INSERT INTO dnc.BankLog(LogDescription) VALUES ('Bakiye Ekleme İşlemi Başarısız. Hata: ' + ERROR_MESSAGE())
        PRINT '! Bakiye Ekleme İşlemi Başarısız. Hata: ' + ERROR_MESSAGE()
    END CATCH
END

-- UpdateBalance Procedure
CREATE PROCEDURE UpdateBalance
    @ID uniqueidentifier,
    @IBAN nvarchar(26),
    @Amount money,
    @BalancesTime datetime
AS
BEGIN
    BEGIN TRY
        UPDATE [XBankDB].[dnc].[Balances]
        SET IBAN = @IBAN,
            Amount = @Amount,
            BalancesTime = @BalancesTime,
            ModifiedDate = GETDATE()
        WHERE ID = @ID

        -- Başarılı işlem logu
        INSERT INTO dnc.BankLog(LogDescription) VALUES ('Bakiye Güncelleme İşlemi Başarılı')
        PRINT 'Bakiye Güncelleme İşlemleri Başarılı'
    END TRY
    BEGIN CATCH
        INSERT INTO dnc.BankLog(LogDescription) VALUES ('Bakiye Güncelleme İşlemi Başarısız. Hata: ' + ERROR_MESSAGE())
        PRINT '! Bakiye Güncelleme İşlemi Başarısız. Hata: ' + ERROR_MESSAGE()
    END CATCH
END

-- SoftDeleteBalance Procedure
CREATE PROCEDURE SoftDeleteBalance
    @ID uniqueidentifier
AS
BEGIN
    BEGIN TRY
        -- Burada sadece IsActive değerini güncelliyoruz
        UPDATE [XBankDB].[dnc].[Balances]
        SET IsActive = 0
        WHERE ID = @ID

        -- Başarılı işlem logu
        INSERT INTO dnc.BankLog(LogDescription) VALUES ('Bakiye Silme İşlemi Başarılı')
        PRINT 'Bakiye Silme İşlemleri Başarılı'
    END TRY
    BEGIN CATCH
        INSERT INTO dnc.BankLog(LogDescription) VALUES ('Bakiye Silme İşlemi Başarısız. Hata: ' + ERROR_MESSAGE())
        PRINT '! Bakiye Silme İşlemi Başarısız. Hata: ' + ERROR_MESSAGE()
    END CATCH
END

-- HardDeleteBalance Procedure
CREATE PROCEDURE HardDeleteBalance
    @ID uniqueidentifier
AS
BEGIN
    BEGIN TRY
        DELETE FROM [XBankDB].[dnc].[Balances]
        WHERE ID = @ID

        -- Başarılı işlem logu
        INSERT INTO dnc.BankLog(LogDescription) VALUES ('Bakiye Kalıcı Silme İşlemi Başarılı')
        PRINT 'Bakiye Kalıcı Silme İşlemleri Başarılı'
    END TRY
    BEGIN CATCH
        INSERT INTO dnc.BankLog(LogDescription) VALUES ('Bakiye Silme İşlemi Başarısız. Hata: ' + ERROR_MESSAGE())
        PRINT '!  Bakiye Silme İşlemi Başarısız. Hata: ' + ERROR_MESSAGE()
    END CATCH
END




--------------------------- BankCustomer Stored Procedure ----------------------------
-- ListBankCustomers Procedure
CREATE PROCEDURE ListBankCustomers
AS
BEGIN
    BEGIN TRY
        SELECT CustomerID, CredentialNo, FirstName, LastName, BirthOfDate, CreatedDate, ModifiedDate, IsActive
        FROM [XBankDB].[dnc].[BankCustomer]

        -- Başarılı işlem logu
        INSERT INTO dnc.BankLog(LogDescription) VALUES ('Müşterileri Listeleme İşlemi Başarılı')
        PRINT 'Müşterileri Listeleme İşlemleri Başarılı'
    END TRY
    BEGIN CATCH
        -- Hata durumunda yapılacak işlemler buraya yazılır
        INSERT INTO dnc.BankLog(LogDescription) VALUES ('! Müşterileri Listelerken Hata Meydana Geldi. Hata: ' + ERROR_MESSAGE())
        PRINT '! Müşterileri Listelerken Hata Meydana Geldi. Hata: ' + ERROR_MESSAGE()
    END CATCH
END

-- FilterBankCustomers Procedure
CREATE PROCEDURE FilterBankCustomers
    @CredentialNo nvarchar(11) = NULL,
    @FirstName nvarchar(50) = NULL,
    @LastName nvarchar(50) = NULL,
    @BirthOfDate date = NULL
AS
BEGIN
    BEGIN TRY
        SELECT CustomerID, CredentialNo, FirstName, LastName, BirthOfDate, CreatedDate, ModifiedDate, IsActive
        FROM [XBankDB].[dnc].[BankCustomer]
        WHERE
            (@CredentialNo IS NULL OR CredentialNo = @CredentialNo) AND
            (@FirstName IS NULL OR FirstName = @FirstName) AND
            (@LastName IS NULL OR LastName = @LastName) AND
            (@BirthOfDate IS NULL OR BirthOfDate = @BirthOfDate)

        INSERT INTO dnc.BankLog(LogDescription) VALUES ('Müşterileri Listeleme İşlemi Başarılı')
        PRINT 'Müşterileri Listeleme İşlemleri Başarılı'
    END TRY
    BEGIN CATCH
        INSERT INTO dnc.BankLog(LogDescription) VALUES ('! Müşterileri Listelerken Hata Meydana Geldi. Hata: ' + ERROR_MESSAGE())
        PRINT '! Müşterileri Listelerken Hata Meydana Geldi. Hata: ' + ERROR_MESSAGE()
    END CATCH
END

-- GetBankCustomerByID Procedure
CREATE PROCEDURE GetBankCustomerByID
    @CustomerID uniqueidentifier
AS
BEGIN
    BEGIN TRY
        SELECT CustomerID, CredentialNo, FirstName, LastName, BirthOfDate, CreatedDate, ModifiedDate, IsActive
        FROM [XBankDB].[dnc].[BankCustomer]
        WHERE CustomerID = @CustomerID

        INSERT INTO dnc.BankLog(LogDescription) VALUES ('Müşteriler Listesindeki Müşteri İşlemi Başarılı Bir Şekilde Geldi.')
        PRINT 'Müşteriler Listesindeki Müşteri İşlemi Başarılı Bir Şekilde Geldi.'
    END TRY
    BEGIN CATCH
        INSERT INTO dnc.BankLog(LogDescription) VALUES (' Müşteriler Listesindeki Müşteriyi Getiriken Hata Meydana Geldi. Hata: ' + ERROR_MESSAGE())
        PRINT '! Müşteriler Listesindeki Müşteriyi Getiriken Hata Meydana Geldi. Hata: ' + ERROR_MESSAGE()
    END CATCH
END

-- AddBankCustomer Procedure
CREATE PROCEDURE AddBankCustomer
    @CredentialNo nvarchar(11),
    @FirstName nvarchar(50),
    @LastName nvarchar(50),
    @BirthOfDate date
AS
BEGIN
    BEGIN TRY
        INSERT INTO [XBankDB].[dnc].[BankCustomer] (CredentialNo, FirstName, LastName, BirthOfDate, CreatedDate)
        VALUES (@CredentialNo, @FirstName, @LastName, @BirthOfDate, GETDATE())

        -- Başarılı işlem logu
        INSERT INTO dnc.BankLog(LogDescription) VALUES ('Müşteri Ekleme İşlemi Başarılı')
        PRINT 'Müşteri Ekleme İşlemleri Başarılı'
    END TRY
    BEGIN CATCH
        INSERT INTO dnc.BankLog(LogDescription) VALUES ('Müşteri Ekleme İşlemi Başarısız. Hata: ' + ERROR_MESSAGE())
        PRINT '! Müşteri Ekleme İşlemi Başarısız. Hata: ' + ERROR_MESSAGE()
    END CATCH
END

-- UpdateBankCustomer Procedure
CREATE PROCEDURE UpdateBankCustomer
    @CustomerID uniqueidentifier,
    @CredentialNo nvarchar(11),
    @FirstName nvarchar(50),
    @LastName nvarchar(50),
    @BirthOfDate date
AS
BEGIN
    BEGIN TRY
        UPDATE [XBankDB].[dnc].[BankCustomer]
        SET CredentialNo = @CredentialNo,
            FirstName = @FirstName,
            LastName = @LastName,
            BirthOfDate = @BirthOfDate,
            ModifiedDate = GETDATE()
        WHERE CustomerID = @CustomerID

        -- Başarılı işlem logu
        INSERT INTO dnc.BankLog(LogDescription) VALUES ('Müşteri Güncelleme İşlemi Başarılı')
        PRINT 'Müşteri Güncelleme İşlemleri Başarılı'
    END TRY
    BEGIN CATCH
        INSERT INTO dnc.BankLog(LogDescription) VALUES ('Müşteri Güncelleme İşlemi Başarısız. Hata: ' + ERROR_MESSAGE())
        PRINT '! Müşteri Güncelleme İşlemi Başarısız. Hata: ' + ERROR_MESSAGE()
    END CATCH
END

-- SoftDeleteBankCustomer Procedure
CREATE PROCEDURE SoftDeleteBankCustomer
    @CustomerID uniqueidentifier
AS
BEGIN
    BEGIN TRY
        -- Burada sadece IsActive değerini güncelliyoruz
        UPDATE [XBankDB].[dnc].[BankCustomer]
        SET IsActive = 0
        WHERE CustomerID = @CustomerID

        -- Başarılı işlem logu
        INSERT INTO dnc.BankLog(LogDescription) VALUES ('Müşteri Silme İşlemi Başarılı')
        PRINT 'Müşteri Silme İşlemleri Başarılı'
    END TRY
    BEGIN CATCH
        INSERT INTO dnc.BankLog(LogDescription) VALUES ('Müşteri Silme İşlemi Başarısız. Hata: ' + ERROR_MESSAGE())
        PRINT '! Müşteri Silme İşlemi Başarısız. Hata: ' + ERROR_MESSAGE()
    END CATCH
END

-- HardDeleteBankCustomer Procedure
CREATE PROCEDURE HardDeleteBankCustomer
    @CustomerID uniqueidentifier
AS
BEGIN
    BEGIN TRY
        DELETE FROM [XBankDB].[dnc].[BankCustomer]
        WHERE CustomerID = @CustomerID

        -- Başarılı işlem logu
        INSERT INTO dnc.BankLog(LogDescription) VALUES ('Müşteri Kalıcı Silme İşlemi Başarılı')
        PRINT 'Müşteri Kalıcı Silme İşlemleri Başarılı'
    END TRY
    BEGIN CATCH
        INSERT INTO dnc.BankLog(LogDescription) VALUES ('Müşteri Silme İşlemi Başarısız. Hata: ' + ERROR_MESSAGE())
        PRINT '!  Müşteri Silme İşlemi Başarısız. Hata: ' + ERROR_MESSAGE()
    END CATCH
END



--------------------------- BankCustomerContactInformation Stored Procedure ----------------------------


-- ListBankCustomerContactInformation Procedure
CREATE PROCEDURE ListBankCustomerContactInformation
AS
BEGIN
    BEGIN TRY
        SELECT ContactID, CustomerID, ContactTypeID, ContactInformation, CreatedDate, ModifiedDate, IsActive
        FROM [XBankDB].[dnc].[BankCustomerContactInformation]

        -- Başarılı işlem logu
        INSERT INTO dnc.BankLog(LogDescription) VALUES ('Müşteri İletişim Bilgilerini Listeleme İşlemi Başarılı')
        PRINT 'Müşteri İletişim Bilgilerini Listeleme İşlemleri Başarılı'
    END TRY
    BEGIN CATCH
        -- Hata durumunda yapılacak işlemler buraya yazılır
        INSERT INTO dnc.BankLog(LogDescription) VALUES ('! Müşteri İletişim Bilgilerini Listelerken Hata Meydana Geldi. Hata: ' + ERROR_MESSAGE())
        PRINT '! Müşteri İletişim Bilgilerini Listelerken Hata Meydana Geldi. Hata: ' + ERROR_MESSAGE()
    END CATCH
END

-- FilterBankCustomerContactInformation Procedure
CREATE PROCEDURE FilterBankCustomerContactInformation
    @CustomerID uniqueidentifier = NULL,
    @ContactTypeID smallint = NULL,
    @ContactInformation nvarchar(120) = NULL
AS
BEGIN
    BEGIN TRY
        SELECT ContactID, CustomerID, ContactTypeID, ContactInformation, CreatedDate, ModifiedDate, IsActive
        FROM [XBankDB].[dnc].[BankCustomerContactInformation]
        WHERE
            (@CustomerID IS NULL OR CustomerID = @CustomerID) AND
            (@ContactTypeID IS NULL OR ContactTypeID = @ContactTypeID) AND
            (@ContactInformation IS NULL OR ContactInformation = @ContactInformation)

        INSERT INTO dnc.BankLog(LogDescription) VALUES ('Müşteri İletişim Bilgilerini Listeleme İşlemi Başarılı')
        PRINT 'Müşteri İletişim Bilgilerini Listeleme İşlemleri Başarılı'
    END TRY
    BEGIN CATCH
        INSERT INTO dnc.BankLog(LogDescription) VALUES ('! Müşteri İletişim Bilgilerini Listelerken Hata Meydana Geldi. Hata: ' + ERROR_MESSAGE())
        PRINT '! Müşteri İletişim Bilgilerini Listelerken Hata Meydana Geldi. Hata: ' + ERROR_MESSAGE()
    END CATCH
END

-- GetBankCustomerContactInformationByID Procedure
CREATE PROCEDURE GetBankCustomerContactInformationByID
    @ContactID uniqueidentifier
AS
BEGIN
    BEGIN TRY
        SELECT ContactID, CustomerID, ContactTypeID, ContactInformation, CreatedDate, ModifiedDate, IsActive
        FROM [XBankDB].[dnc].[BankCustomerContactInformation]
        WHERE ContactID = @ContactID

        INSERT INTO dnc.BankLog(LogDescription) VALUES ('Müşteri İletişim Bilgilerindeki Bilgi İşlemi Başarılı Bir Şekilde Geldi.')
        PRINT 'Müşteri İletişim Bilgilerindeki Bilgi İşlemi Başarılı Bir Şekilde Geldi.'
    END TRY
    BEGIN CATCH
        INSERT INTO dnc.BankLog(LogDescription) VALUES (' Müşteri İletişim Bilgilerindeki Bilgiyi Getiriken Hata Meydana Geldi. Hata: ' + ERROR_MESSAGE())
        PRINT '! Müşteri İletişim Bilgilerindeki Bilgiyi Getiriken Hata Meydana Geldi. Hata: ' + ERROR_MESSAGE()
    END CATCH
END

-- AddBankCustomerContactInformation Procedure
CREATE PROCEDURE AddBankCustomerContactInformation
    @CustomerID uniqueidentifier,
    @ContactTypeID smallint,
    @ContactInformation nvarchar(120)
AS
BEGIN
    BEGIN TRY
        INSERT INTO [XBankDB].[dnc].[BankCustomerContactInformation] (CustomerID, ContactTypeID, ContactInformation, CreatedDate)
        VALUES (@CustomerID, @ContactTypeID, @ContactInformation, GETDATE())

        -- Başarılı işlem logu
        INSERT INTO dnc.BankLog(LogDescription) VALUES ('Müşteri İletişim Bilgisi Ekleme İşlemi Başarılı')
        PRINT 'Müşteri İletişim Bilgisi Ekleme İşlemleri Başarılı'
    END TRY
    BEGIN CATCH
        INSERT INTO dnc.BankLog(LogDescription) VALUES ('Müşteri İletişim Bilgisi Ekleme İşlemi Başarısız. Hata: ' + ERROR_MESSAGE())
        PRINT '! Müşteri İletişim Bilgisi Ekleme İşlemi Başarısız. Hata: ' + ERROR_MESSAGE()
    END CATCH
END

-- UpdateBankCustomerContactInformation Procedure
CREATE PROCEDURE UpdateBankCustomerContactInformation
    @ContactID uniqueidentifier,
    @CustomerID uniqueidentifier,
    @ContactTypeID smallint,
    @ContactInformation nvarchar(120)
AS
BEGIN
    BEGIN TRY
        UPDATE [XBankDB].[dnc].[BankCustomerContactInformation]
        SET CustomerID = @CustomerID,
            ContactTypeID = @ContactTypeID,
            ContactInformation = @ContactInformation,
            ModifiedDate = GETDATE()
        WHERE ContactID = @ContactID

        -- Başarılı işlem logu
        INSERT INTO dnc.BankLog(LogDescription) VALUES ('Müşteri İletişim Bilgisi Güncelleme İşlemi Başarılı')
        PRINT 'Müşteri İletişim Bilgisi Güncelleme İşlemleri Başarılı'
    END TRY
    BEGIN CATCH
        INSERT INTO dnc.BankLog(LogDescription) VALUES ('Müşteri İletişim Bilgisi Güncelleme İşlemi Başarısız. Hata: ' + ERROR_MESSAGE())
        PRINT '! Müşteri İletişim Bilgisi Güncelleme İşlemi Başarısız. Hata: ' + ERROR_MESSAGE()
    END CATCH
END

-- SoftDeleteBankCustomerContactInformation Procedure
CREATE PROCEDURE SoftDeleteBankCustomerContactInformation
    @ContactID uniqueidentifier
AS
BEGIN
    BEGIN TRY
        -- Burada sadece IsActive değerini güncelliyoruz
        UPDATE [XBankDB].[dnc].[BankCustomerContactInformation]
        SET IsActive = 0
        WHERE ContactID = @ContactID

        -- Başarılı işlem logu
        INSERT INTO dnc.BankLog(LogDescription) VALUES ('Müşteri İletişim Bilgisi Silme İşlemi Başarılı')
        PRINT 'Müşteri İletişim Bilgisi Silme İşlemleri Başarılı'
    END TRY
    BEGIN CATCH
        INSERT INTO dnc.BankLog(LogDescription) VALUES ('Müşteri İletişim Bilgisi Silme İşlemi Başarısız. Hata: ' + ERROR_MESSAGE())
        PRINT '! Müşteri İletişim Bilgisi Silme İşlemi Başarısız. Hata: ' + ERROR_MESSAGE()
    END CATCH
END

-- HardDeleteBankCustomerContactInformation Procedure
CREATE PROCEDURE HardDeleteBankCustomerContactInformation
    @ContactID uniqueidentifier
AS
BEGIN
    BEGIN TRY
        DELETE FROM [XBankDB].[dnc].[BankCustomerContactInformation]
        WHERE ContactID = @ContactID

        -- Başarılı işlem logu
        INSERT INTO dnc.BankLog(LogDescription) VALUES ('Müşteri İletişim Bilgisi Kalıcı Silme İşlemi Başarılı')
        PRINT 'Müşteri İletişim Bilgisi Kalıcı Silme İşlemleri Başarılı'
    END TRY
    BEGIN CATCH
        INSERT INTO dnc.BankLog(LogDescription) VALUES ('Müşteri İletişim Bilgisi Silme İşlemi Başarısız. Hata: ' + ERROR_MESSAGE())
        PRINT '!  Müşteri İletişim Bilgisi Silme İşlemi Başarısız. Hata: ' + ERROR_MESSAGE()
    END CATCH
END




--------------------------- BankCustomerCustomerLogin Stored Procedure ----------------------------


-- ListBankCustomerLogin Procedure
CREATE PROCEDURE ListBankCustomerLogin
AS
BEGIN
    BEGIN TRY
        SELECT LoginID, CustomerID, UserPassword, PasswordSalt, CreatedDate, ModifiedDate, IsActive
        FROM [XBankDB].[dnc].[BankCustomerLogin]

        -- Başarılı işlem logu
        INSERT INTO dnc.BankLog(LogDescription) VALUES ('Müşteri Giriş Bilgilerini Listeleme İşlemi Başarılı')
        PRINT 'Müşteri Giriş Bilgilerini Listeleme İşlemleri Başarılı'
    END TRY
    BEGIN CATCH
        -- Hata durumunda yapılacak işlemler buraya yazılır
        INSERT INTO dnc.BankLog(LogDescription) VALUES ('! Müşteri Giriş Bilgilerini Listelerken Hata Meydana Geldi. Hata: ' + ERROR_MESSAGE())
        PRINT '! Müşteri Giriş Bilgilerini Listelerken Hata Meydana Geldi. Hata: ' + ERROR_MESSAGE()
    END CATCH
END

-- FilterBankCustomerLogin Procedure
CREATE PROCEDURE FilterBankCustomerLogin
    @CustomerID uniqueidentifier = NULL
AS
BEGIN
    BEGIN TRY
        SELECT LoginID, CustomerID, UserPassword, PasswordSalt, CreatedDate, ModifiedDate, IsActive
        FROM [XBankDB].[dnc].[BankCustomerLogin]
        WHERE
            (@CustomerID IS NULL OR CustomerID = @CustomerID)

        INSERT INTO dnc.BankLog(LogDescription) VALUES ('Müşteri Giriş Bilgilerini Listeleme İşlemi Başarılı')
        PRINT 'Müşteri Giriş Bilgilerini Listeleme İşlemleri Başarılı'
    END TRY
    BEGIN CATCH
        INSERT INTO dnc.BankLog(LogDescription) VALUES ('! Müşteri Giriş Bilgilerini Listelerken Hata Meydana Geldi. Hata: ' + ERROR_MESSAGE())
        PRINT '! Müşteri Giriş Bilgilerini Listelerken Hata Meydana Geldi. Hata: ' + ERROR_MESSAGE()
    END CATCH
END

-- GetBankCustomerLoginByID Procedure
CREATE PROCEDURE GetBankCustomerLoginByID
    @LoginID uniqueidentifier
AS
BEGIN
    BEGIN TRY
        SELECT LoginID, CustomerID, UserPassword, PasswordSalt, CreatedDate, ModifiedDate, IsActive
        FROM [XBankDB].[dnc].[BankCustomerLogin]
        WHERE LoginID = @LoginID

        INSERT INTO dnc.BankLog(LogDescription) VALUES ('Müşteri Giriş Bilgilerindeki Bilgi İşlemi Başarılı Bir Şekilde Geldi.')
        PRINT 'Müşteri Giriş Bilgilerindeki Bilgi İşlemi Başarılı Bir Şekilde Geldi.'
    END TRY
    BEGIN CATCH
        INSERT INTO dnc.BankLog(LogDescription) VALUES (' Müşteri Giriş Bilgilerindeki Bilgiyi Getiriken Hata Meydana Geldi. Hata: ' + ERROR_MESSAGE())
        PRINT '! Müşteri Giriş Bilgilerindeki Bilgiyi Getiriken Hata Meydana Geldi. Hata: ' + ERROR_MESSAGE()
    END CATCH
END

-- AddBankCustomerLogin Procedure
CREATE PROCEDURE AddBankCustomerLogin
    @CustomerID uniqueidentifier,
    @UserPassword varbinary(max),
    @PasswordSalt varbinary(max)
AS
BEGIN
    BEGIN TRY
        INSERT INTO [XBankDB].[dnc].[BankCustomerLogin] (CustomerID, UserPassword, PasswordSalt, CreatedDate)
        VALUES (@CustomerID, @UserPassword, @PasswordSalt, GETDATE())

        -- Başarılı işlem logu
        INSERT INTO dnc.BankLog(LogDescription) VALUES ('Müşteri Giriş Bilgisi Ekleme İşlemi Başarılı')
        PRINT 'Müşteri Giriş Bilgisi Ekleme İşlemleri Başarılı'
    END TRY
    BEGIN CATCH
        INSERT INTO dnc.BankLog(LogDescription) VALUES ('Müşteri Giriş Bilgisi Ekleme İşlemi Başarısız. Hata: ' + ERROR_MESSAGE())
        PRINT '! Müşteri Giriş Bilgisi Ekleme İşlemi Başarısız. Hata: ' + ERROR_MESSAGE()
    END CATCH
END

-- UpdateBankCustomerLogin Procedure
CREATE PROCEDURE UpdateBankCustomerLogin
    @LoginID uniqueidentifier,
    @CustomerID uniqueidentifier,
    @UserPassword varbinary(max),
    @PasswordSalt varbinary(max)
AS
BEGIN
    BEGIN TRY
        UPDATE [XBankDB].[dnc].[BankCustomerLogin]
        SET CustomerID = @CustomerID,
            UserPassword = @UserPassword,
            PasswordSalt = @PasswordSalt,
            ModifiedDate = GETDATE()
        WHERE LoginID = @LoginID

        -- Başarılı işlem logu
        INSERT INTO dnc.BankLog(LogDescription) VALUES ('Müşteri Giriş Bilgisi Güncelleme İşlemi Başarılı')
        PRINT 'Müşteri Giriş Bilgisi Güncelleme İşlemleri Başarılı'
    END TRY
    BEGIN CATCH
        INSERT INTO dnc.BankLog(LogDescription) VALUES ('Müşteri Giriş Bilgisi Güncelleme İşlemi Başarısız. Hata: ' + ERROR_MESSAGE())
        PRINT '! Müşteri Giriş Bilgisi Güncelleme İşlemi Başarısız. Hata: ' + ERROR_MESSAGE()
    END CATCH
END

-- SoftDeleteBankCustomerLogin Procedure
CREATE PROCEDURE SoftDeleteBankCustomerLogin
    @LoginID uniqueidentifier
AS
BEGIN
    BEGIN TRY
        -- Burada sadece IsActive değerini güncelliyoruz
        UPDATE [XBankDB].[dnc].[BankCustomerLogin]
        SET IsActive = 0
        WHERE LoginID = @LoginID

        -- Başarılı işlem logu
        INSERT INTO dnc.BankLog(LogDescription) VALUES ('Müşteri Giriş Bilgisi Silme İşlemi Başarılı')
        PRINT 'Müşteri Giriş Bilgisi Silme İşlemleri Başarılı'
    END TRY
    BEGIN CATCH
        INSERT INTO dnc.BankLog(LogDescription) VALUES ('Müşteri Giriş Bilgisi Silme İşlemi Başarısız. Hata: ' + ERROR_MESSAGE())
        PRINT '! Müşteri Giriş Bilgisi Silme İşlemi Başarısız. Hata: ' + ERROR_MESSAGE()
    END CATCH
END

-- HardDeleteBankCustomerLogin Procedure
CREATE PROCEDURE HardDeleteBankCustomerLogin
    @LoginID uniqueidentifier
AS
BEGIN
    BEGIN TRY
        DELETE FROM [XBankDB].[dnc].[BankCustomerLogin]
        WHERE LoginID = @LoginID

        -- Başarılı işlem logu
        INSERT INTO dnc.BankLog(LogDescription) VALUES ('Müşteri Giriş Bilgisi Kalıcı Silme İşlemi Başarılı')
        PRINT 'Müşteri Giriş Bilgisi Kalıcı Silme İşlemleri Başarılı'
    END TRY
    BEGIN CATCH
        INSERT INTO dnc.BankLog(LogDescription) VALUES ('Müşteri Giriş Bilgisi Silme İşlemi Başarısız. Hata: ' + ERROR_MESSAGE())
        PRINT '!  Müşteri Giriş Bilgisi Silme İşlemi Başarısız. Hata: ' + ERROR_MESSAGE()
    END CATCH
END



--------------------------- Bill Stored Procedure ----------------------------

-- ListBills Procedure
CREATE PROCEDURE ListBills
AS
BEGIN
    BEGIN TRY
        SELECT ID, InstituteID, AccountID, Amount, PaymentStatus, PreviousBillID, CreatedDate, ModifiedDate, IsActive
        FROM [XBankDB].[dnc].[Bills]

        -- Başarılı işlem logu
        INSERT INTO dnc.BankLog(LogDescription) VALUES ('Fatura Listeleme İşlemi Başarılı')
        PRINT 'Fatura Listeleme İşlemleri Başarılı'
    END TRY
    BEGIN CATCH
        -- Hata durumunda yapılacak işlemler buraya yazılır
        INSERT INTO dnc.BankLog(LogDescription) VALUES ('! Faturaları Listelerken Hata Meydana Geldi. Hata: ' + ERROR_MESSAGE())
        PRINT '! Faturaları Listelerken Hata Meydana Geldi. Hata: ' + ERROR_MESSAGE()
    END CATCH
END

-- FilterBills Procedure
CREATE PROCEDURE FilterBills
    @InstituteID int = NULL,
    @AccountID uniqueidentifier = NULL,
    @PaymentStatus bit = NULL
AS
BEGIN
    BEGIN TRY
        SELECT ID, InstituteID, AccountID, Amount, PaymentStatus, PreviousBillID, CreatedDate, ModifiedDate, IsActive
        FROM [XBankDB].[dnc].[Bills]
        WHERE
            (@InstituteID IS NULL OR InstituteID = @InstituteID) AND
            (@AccountID IS NULL OR AccountID = @AccountID) AND
            (@PaymentStatus IS NULL OR PaymentStatus = @PaymentStatus)

        INSERT INTO dnc.BankLog(LogDescription) VALUES ('Fatura Listeleme İşlemi Başarılı')
        PRINT 'Fatura Listeleme İşlemleri Başarılı'
    END TRY
    BEGIN CATCH
        INSERT INTO dnc.BankLog(LogDescription) VALUES ('! Faturaları Listelerken Hata Meydana Geldi. Hata: ' + ERROR_MESSAGE())
        PRINT '! Faturaları Listelerken Hata Meydana Geldi. Hata: ' + ERROR_MESSAGE()
    END CATCH
END

-- GetBillByID Procedure
CREATE PROCEDURE GetBillByID
    @BillID uniqueidentifier
AS
BEGIN
    BEGIN TRY
        SELECT ID, InstituteID, AccountID, Amount, PaymentStatus, PreviousBillID, CreatedDate, ModifiedDate, IsActive
        FROM [XBankDB].[dnc].[Bills]
        WHERE ID = @BillID

        INSERT INTO dnc.BankLog(LogDescription) VALUES ('Fatura Listesindeki Fatura İşlemi Başarılı Bir Şekilde Geldi.')
        PRINT 'Fatura Listesindeki Fatura İşlemi Başarılı Bir Şekilde Geldi.'
    END TRY
    BEGIN CATCH
        INSERT INTO dnc.BankLog(LogDescription) VALUES (' Fatura Listesindeki Faturayı Getiriken Hata Meydana Geldi. Hata: ' + ERROR_MESSAGE())
        PRINT '! Fatura Listesindeki Faturayı Getiriken Hata Meydana Geldi. Hata: ' + ERROR_MESSAGE()
    END CATCH
END

-- AddBill Procedure
CREATE PROCEDURE AddBill
    @InstituteID int,
    @AccountID uniqueidentifier,
    @Amount money,
    @PaymentStatus bit,
    @PreviousBillID uniqueidentifier = NULL
AS
BEGIN
    BEGIN TRY
        INSERT INTO [XBankDB].[dnc].[Bills] (InstituteID, AccountID, Amount, PaymentStatus, PreviousBillID, CreatedDate)
        VALUES (@InstituteID, @AccountID, @Amount, @PaymentStatus, @PreviousBillID, GETDATE())

        -- Başarılı işlem logu
        INSERT INTO dnc.BankLog(LogDescription) VALUES ('Fatura Ekleme İşlemi Başarılı')
        PRINT 'Fatura Ekleme İşlemleri Başarılı'
    END TRY
    BEGIN CATCH
        INSERT INTO dnc.BankLog(LogDescription) VALUES ('Fatura Ekleme İşlemi Başarısız. Hata: ' + ERROR_MESSAGE())
        PRINT '! Fatura Ekleme İşlemi Başarısız. Hata: ' + ERROR_MESSAGE()
    END CATCH
END

-- UpdateBill Procedure
CREATE PROCEDURE UpdateBill
    @BillID uniqueidentifier,
    @InstituteID int,
    @AccountID uniqueidentifier,
    @Amount money,
    @PaymentStatus bit,
    @PreviousBillID uniqueidentifier = NULL
AS
BEGIN
    BEGIN TRY
        UPDATE [XBankDB].[dnc].[Bills]
        SET InstituteID = @InstituteID,
            AccountID = @AccountID,
            Amount = @Amount,
            PaymentStatus = @PaymentStatus,
            PreviousBillID = @PreviousBillID,
            ModifiedDate = GETDATE()
        WHERE ID = @BillID

        -- Başarılı işlem logu
        INSERT INTO dnc.BankLog(LogDescription) VALUES ('Fatura Güncelleme İşlemi Başarılı')
        PRINT 'Fatura Güncelleme İşlemleri Başarılı'
    END TRY
    BEGIN CATCH
        INSERT INTO dnc.BankLog(LogDescription) VALUES ('Fatura Güncelleme İşlemi Başarısız. Hata: ' + ERROR_MESSAGE())
        PRINT '! Fatura Güncelleme İşlemi Başarısız. Hata: ' + ERROR_MESSAGE()
    END CATCH
END

-- SoftDeleteBill Procedure
CREATE PROCEDURE SoftDeleteBill
    @BillID uniqueidentifier
AS
BEGIN
    BEGIN TRY
        -- Burada sadece IsActive değerini güncelliyoruz
        UPDATE [XBankDB].[dnc].[Bills]
        SET IsActive = 0
        WHERE ID = @BillID

        -- Başarılı işlem logu
        INSERT INTO dnc.BankLog(LogDescription) VALUES ('Fatura Silme İşlemi Başarılı')
        PRINT 'Fatura Silme İşlemleri Başarılı'
    END TRY
    BEGIN CATCH
         INSERT INTO dnc.BankLog(LogDescription) VALUES ('Fatura Silme İşlemi Başarısız. Hata: ' + ERROR_MESSAGE())
         PRINT '! Fatura Silme İşlemi Başarısız. Hata: ' + ERROR_MESSAGE()
    END CATCH
END

-- HardDeleteBill Procedure
CREATE PROCEDURE HardDeleteBill
    @BillID uniqueidentifier
AS
BEGIN
    BEGIN TRY
        DELETE FROM [XBankDB].[dnc].[Bills]
        WHERE ID = @BillID

        -- Başarılı işlem logu
        INSERT INTO dnc.BankLog(LogDescription) VALUES ('Fatura Kalıcı Silme İşlemi Başarılı')
        PRINT 'Fatura Kalıcı Silme İşlemleri Başarılı'
    END TRY
    BEGIN CATCH
        INSERT INTO dnc.BankLog(LogDescription) VALUES ('Fatura Silme İşlemi Başarısız. Hata: ' + ERROR_MESSAGE())
        PRINT '! Fatura Silme İşlemi Başarısız. Hata: ' + ERROR_MESSAGE()
    END CATCH
END




--------------------------- Currency Stored Procedure ----------------------------

-- ListCurrencies Procedure
CREATE PROCEDURE ListCurrencies
AS
BEGIN
    BEGIN TRY
        SELECT CurrencyID, Unit, Title, CurrencyCode, ForexBuying, ForexSelling, CreatedDate, ModifiedDate, IsActive
        FROM [XBankDB].[dnc].[Currency]

        -- Başarılı işlem logu
        INSERT INTO dnc.BankLog(LogDescription) VALUES ('Para Birimi Listeleme İşlemi Başarılı')
        PRINT 'Para Birimi Listeleme İşlemleri Başarılı'
    END TRY
    BEGIN CATCH
        -- Hata durumunda yapılacak işlemler buraya yazılır
        INSERT INTO dnc.BankLog(LogDescription) VALUES ('! Para Birimlerini Listelerken Hata Meydana Geldi. Hata: ' + ERROR_MESSAGE())
        PRINT '! Para Birimlerini Listelerken Hata Meydana Geldi. Hata: ' + ERROR_MESSAGE()
    END CATCH
END

-- FilterCurrencies Procedure
CREATE PROCEDURE FilterCurrencies
    @CurrencyID int = NULL,
    @Unit smallint = NULL,
    @Title nvarchar(100) = NULL,
    @CurrencyCode nvarchar(5) = NULL
AS
BEGIN
    BEGIN TRY
        SELECT CurrencyID, Unit, Title, CurrencyCode, ForexBuying, ForexSelling, CreatedDate, ModifiedDate, IsActive
        FROM [XBankDB].[dnc].[Currency]
        WHERE
            (@CurrencyID IS NULL OR CurrencyID = @CurrencyID) AND
            (@Unit IS NULL OR Unit = @Unit) AND
            (@Title IS NULL OR Title = @Title) AND
            (@CurrencyCode IS NULL OR CurrencyCode = @CurrencyCode)

        INSERT INTO dnc.BankLog(LogDescription) VALUES ('Para Birimi Listeleme İşlemi Başarılı')
        PRINT 'Para Birimi Listeleme İşlemleri Başarılı'
    END TRY
    BEGIN CATCH
        INSERT INTO dnc.BankLog(LogDescription) VALUES ('! Para Birimlerini Listelerken Hata Meydana Geldi. Hata: ' + ERROR_MESSAGE())
        PRINT '! Para Birimlerini Listelerken Hata Meydana Geldi. Hata: ' + ERROR_MESSAGE()
    END CATCH
END

-- GetCurrencyByID Procedure
CREATE PROCEDURE GetCurrencyByID
    @CurrencyID int
AS
BEGIN
    BEGIN TRY
        SELECT CurrencyID, Unit, Title, CurrencyCode, ForexBuying, ForexSelling, CreatedDate, ModifiedDate, IsActive
        FROM [XBankDB].[dnc].[Currency]
        WHERE CurrencyID = @CurrencyID

        INSERT INTO dnc.BankLog(LogDescription) VALUES ('Para Birimi Listesindeki Para Birimi İşlemi Başarılı Bir Şekilde Geldi.')
        PRINT 'Para Birimi Listesindeki Para Birimi İşlemi Başarılı Bir Şekilde Geldi.'
    END TRY
    BEGIN CATCH
        INSERT INTO dnc.BankLog(LogDescription) VALUES (' Para Birimi Listesindeki Para Birimini Getiriken Hata Meydana Geldi. Hata: ' + ERROR_MESSAGE())
        PRINT '! Para Birimi Listesindeki Para Birimini Getiriken Hata Meydana Geldi. Hata: ' + ERROR_MESSAGE()
    END CATCH
END

-- AddCurrency Procedure
CREATE PROCEDURE AddCurrency
    @Unit smallint,
    @Title nvarchar(100),
    @CurrencyCode nvarchar(5),
    @ForexBuying money,
    @ForexSelling money
AS
BEGIN
    BEGIN TRY
        INSERT INTO [XBankDB].[dnc].[Currency] (Unit, Title, CurrencyCode, ForexBuying, ForexSelling, CreatedDate)
        VALUES (@Unit, @Title, @CurrencyCode, @ForexBuying, @ForexSelling, GETDATE())

        -- Başarılı işlem logu
        INSERT INTO dnc.BankLog(LogDescription) VALUES ('Para Birimi Ekleme İşlemi Başarılı')
        PRINT 'Para Birimi Ekleme İşlemleri Başarılı'
    END TRY
    BEGIN CATCH
        INSERT INTO dnc.BankLog(LogDescription) VALUES ('Para Birimi Ekleme İşlemi Başarısız. Hata: ' + ERROR_MESSAGE())
        PRINT '! Para Birimi Ekleme İşlemi Başarısız. Hata: ' + ERROR_MESSAGE()
    END CATCH
END

-- UpdateCurrency Procedure
CREATE PROCEDURE UpdateCurrency
    @CurrencyID int,
    @Unit smallint,
    @Title nvarchar(100),
    @CurrencyCode nvarchar(5),
    @ForexBuying money,
    @ForexSelling money
AS
BEGIN
    BEGIN TRY
        UPDATE [XBankDB].[dnc].[Currency]
        SET Unit = @Unit,
            Title = @Title,
            CurrencyCode = @CurrencyCode,
            ForexBuying = @ForexBuying,
            ForexSelling = @ForexSelling,
            ModifiedDate = GETDATE()
        WHERE CurrencyID = @CurrencyID

        -- Başarılı işlem logu
        INSERT INTO dnc.BankLog(LogDescription) VALUES ('Para Birimi Güncelleme İşlemi Başarılı')
        PRINT 'Para Birimi Güncelleme İşlemleri Başarılı'
    END TRY
    BEGIN CATCH
        INSERT INTO dnc.BankLog(LogDescription) VALUES ('Para Birimi Güncelleme İşlemi Başarısız. Hata: ' + ERROR_MESSAGE())
        PRINT '! Para Birimi Güncelleme İşlemi Başarısız. Hata: ' + ERROR_MESSAGE()
    END CATCH
END

-- SoftDeleteCurrency Procedure
CREATE PROCEDURE SoftDeleteCurrency
    @CurrencyID int
AS
BEGIN
    BEGIN TRY
        -- Burada sadece IsActive değerini güncelliyoruz
        UPDATE [XBankDB].[dnc].[Currency]
        SET IsActive = 0
        WHERE CurrencyID = @CurrencyID

        -- Başarılı işlem logu
        INSERT INTO dnc.BankLog(LogDescription) VALUES ('Para Birimi Silme İşlemi Başarılı')
        PRINT 'Para Birimi Silme İşlemleri Başarılı'
    END TRY
    BEGIN CATCH
         INSERT INTO dnc.BankLog(LogDescription) VALUES ('Para Birimi Silme İşlemi Başarısız. Hata: ' + ERROR_MESSAGE())
         PRINT '! Para Birimi Silme İşlemi Başarısız. Hata: ' + ERROR_MESSAGE()
    END CATCH
END

-- HardDeleteCurrency Procedure
CREATE PROCEDURE HardDeleteCurrency
    @CurrencyID int
AS
BEGIN
    BEGIN TRY
        DELETE FROM [XBankDB].[dnc].[Currency]
        WHERE CurrencyID = @CurrencyID

        -- Başarılı işlem logu
        INSERT INTO dnc.BankLog(LogDescription) VALUES ('Para Birimi Kalıcı Silme İşlemi Başarılı')
        PRINT 'Para Birimi Kalıcı Silme İşlemleri Başarılı'
    END TRY
    BEGIN CATCH
        INSERT INTO dnc.BankLog(LogDescription) VALUES ('Para Birimi Silme İşlemi Başarısız. Hata: ' + ERROR_MESSAGE())
        PRINT '! Para Birimi Silme İşlemi Başarısız. Hata: ' + ERROR_MESSAGE()
    END CATCH
END




--------------------------- Customer Contact Type Stored Procedure ----------------------------

-- ListCustomerContactTypes Procedure
CREATE PROCEDURE ListCustomerContactTypes
AS
BEGIN
    BEGIN TRY
        SELECT ID, ContactTitle
        FROM [XBankDB].[dnc].[CustomerContactType]

        -- Başarılı işlem logu
        INSERT INTO dnc.BankLog(LogDescription) VALUES ('Müşteri İletişim Türleri Listeleme İşlemi Başarılı')
        PRINT 'Müşteri İletişim Türleri Listeleme İşlemleri Başarılı'
    END TRY
    BEGIN CATCH
        -- Hata durumunda yapılacak işlemler buraya yazılır
        INSERT INTO dnc.BankLog(LogDescription) VALUES ('! Müşteri İletişim Türlerini Listelerken Hata Meydana Geldi. Hata: ' + ERROR_MESSAGE())
        PRINT '! Müşteri İletişim Türlerini Listelerken Hata Meydana Geldi. Hata: ' + ERROR_MESSAGE()
    END CATCH
END

-- FilterCustomerContactTypes Procedure
CREATE PROCEDURE FilterCustomerContactTypes
    @ID smallint = NULL,
    @ContactTitle nvarchar(30) = NULL
AS
BEGIN
    BEGIN TRY
        SELECT ID, ContactTitle
        FROM [XBankDB].[dnc].[CustomerContactType]
        WHERE
            (@ID IS NULL OR ID = @ID) AND
            (@ContactTitle IS NULL OR ContactTitle = @ContactTitle)

        INSERT INTO dnc.BankLog(LogDescription) VALUES ('Müşteri İletişim Türleri Listeleme İşlemi Başarılı')
        PRINT 'Müşteri İletişim Türleri Listeleme İşlemleri Başarılı'
    END TRY
    BEGIN CATCH
        INSERT INTO dnc.BankLog(LogDescription) VALUES ('! Müşteri İletişim Türlerini Listelerken Hata Meydana Geldi. Hata: ' + ERROR_MESSAGE())
        PRINT '! Müşteri İletişim Türlerini Listelerken Hata Meydana Geldi. Hata: ' + ERROR_MESSAGE()
    END CATCH
END

-- GetCustomerContactTypeByID Procedure
CREATE PROCEDURE GetCustomerContactTypeByID
    @ID smallint
AS
BEGIN
    BEGIN TRY
        SELECT ID, ContactTitle
        FROM [XBankDB].[dnc].[CustomerContactType]
        WHERE ID = @ID

        INSERT INTO dnc.BankLog(LogDescription) VALUES ('Müşteri İletişim Türleri Listesindeki Tür İşlemi Başarılı Bir Şekilde Geldi.')
        PRINT 'Müşteri İletişim Türleri Listesindeki Tür İşlemi Başarılı Bir Şekilde Geldi.'
    END TRY
    BEGIN CATCH
        INSERT INTO dnc.BankLog(LogDescription) VALUES (' Müşteri İletişim Türleri Listesindeki Türü Getiriken Hata Meydana Geldi. Hata: ' + ERROR_MESSAGE())
        PRINT '! Müşteri İletişim Türleri Listesindeki Türü Getiriken Hata Meydana Geldi. Hata: ' + ERROR_MESSAGE()
    END CATCH
END

-- AddCustomerContactType Procedure
CREATE PROCEDURE AddCustomerContactType
    @ContactTitle nvarchar(30)
AS
BEGIN
    BEGIN TRY
        INSERT INTO [XBankDB].[dnc].[CustomerContactType] (ContactTitle)
        VALUES (@ContactTitle)

        -- Başarılı işlem logu
        INSERT INTO dnc.BankLog(LogDescription) VALUES ('Müşteri İletişim Türü Ekleme İşlemi Başarılı')
        PRINT 'Müşteri İletişim Türü Ekleme İşlemleri Başarılı'
    END TRY
    BEGIN CATCH
        INSERT INTO dnc.BankLog(LogDescription) VALUES ('Müşteri İletişim Türü Ekleme İşlemi Başarısız. Hata: ' + ERROR_MESSAGE())
        PRINT '! Müşteri İletişim Türü Ekleme İşlemi Başarısız. Hata: ' + ERROR_MESSAGE()
    END CATCH
END

-- UpdateCustomerContactType Procedure
CREATE PROCEDURE UpdateCustomerContactType
    @ID smallint,
    @ContactTitle nvarchar(30)
AS
BEGIN
    BEGIN TRY
        UPDATE [XBankDB].[dnc].[CustomerContactType]
        SET ContactTitle = @ContactTitle
        WHERE ID = @ID

        -- Başarılı işlem logu
        INSERT INTO dnc.BankLog(LogDescription) VALUES ('Müşteri İletişim Türü Güncelleme İşlemi Başarılı')
        PRINT 'Müşteri İletişim Türü Güncelleme İşlemleri Başarılı'
    END TRY
    BEGIN CATCH
        INSERT INTO dnc.BankLog(LogDescription) VALUES ('Müşteri İletişim Türü Güncelleme İşlemi Başarısız. Hata: ' + ERROR_MESSAGE())
        PRINT '! Müşteri İletişim Türü Güncelleme İşlemi Başarısız. Hata: ' + ERROR_MESSAGE()
    END CATCH
END

-- HardDeleteCustomerContactType Procedure
CREATE PROCEDURE HardDeleteCustomerContactType
    @ID smallint
AS
BEGIN
    BEGIN TRY
        DELETE FROM [XBankDB].[dnc].[CustomerContactType]
        WHERE ID = @ID

        -- Başarılı işlem logu
        INSERT INTO dnc.BankLog(LogDescription) VALUES ('Müşteri İletişim Türü Kalıcı Silme İşlemi Başarılı')
        PRINT 'Müşteri İletişim Türü Kalıcı Silme İşlemleri Başarılı'
    END TRY
    BEGIN CATCH
        INSERT INTO dnc.BankLog(LogDescription) VALUES ('Müşteri İletişim Türü Silme İşlemi Başarısız. Hata: ' + ERROR_MESSAGE())
        PRINT '! Müşteri İletişim Türü Silme İşlemi Başarısız. Hata: ' + ERROR_MESSAGE()
    END CATCH
END


--------------------------- Department Stored Procedure ----------------------------

-- ListDepartments Procedure
CREATE PROCEDURE ListDepartments
AS
BEGIN
    BEGIN TRY
        SELECT DepartmentID, Title, CreatedDate, ModifiedDate, IsActive
        FROM [XBankDB].[dnc].[Departments]

        -- Başarılı işlem logu
        INSERT INTO dnc.BankLog(LogDescription) VALUES ('Departmanları Listeleme İşlemi Başarılı')
        PRINT 'Departmanları Listeleme İşlemleri Başarılı'
    END TRY
    BEGIN CATCH
        -- Hata durumunda yapılacak işlemler buraya yazılır
        INSERT INTO dnc.BankLog(LogDescription) VALUES ('! Departmanları Listelerken Hata Meydana Geldi. Hata: ' + ERROR_MESSAGE())
        PRINT '! Departmanları Listelerken Hata Meydana Geldi. Hata: ' + ERROR_MESSAGE()
    END CATCH
END

-- FilterDepartments Procedure
CREATE PROCEDURE FilterDepartments
    @DepartmentID int = NULL,
    @Title nvarchar(50) = NULL
AS
BEGIN
    BEGIN TRY
        SELECT DepartmentID, Title, CreatedDate, ModifiedDate, IsActive
        FROM [XBankDB].[dnc].[Departments]
        WHERE
            (@DepartmentID IS NULL OR DepartmentID = @DepartmentID) AND
            (@Title IS NULL OR Title = @Title)

        INSERT INTO dnc.BankLog(LogDescription) VALUES ('Departmanları Listeleme İşlemi Başarılı')
        PRINT 'Departmanları Listeleme İşlemleri Başarılı'
    END TRY
    BEGIN CATCH
        INSERT INTO dnc.BankLog(LogDescription) VALUES ('! Departmanları Listelerken Hata Meydana Geldi. Hata: ' + ERROR_MESSAGE())
        PRINT '! Departmanları Listelerken Hata Meydana Geldi. Hata: ' + ERROR_MESSAGE()
    END CATCH
END

-- GetDepartmentByID Procedure
CREATE PROCEDURE GetDepartmentByID
    @DepartmentID int
AS
BEGIN
    BEGIN TRY
        SELECT DepartmentID, Title, CreatedDate, ModifiedDate, IsActive
        FROM [XBankDB].[dnc].[Departments]
        WHERE DepartmentID = @DepartmentID

        INSERT INTO dnc.BankLog(LogDescription) VALUES ('Departman Listesindeki Departman İşlemi Başarılı Bir Şekilde Geldi.')
        PRINT 'Departman Listesindeki Departman İşlemi Başarılı Bir Şekilde Geldi.'
    END TRY
    BEGIN CATCH
        INSERT INTO dnc.BankLog(LogDescription) VALUES ('Departman Listesindeki Departmanı Getiriken Hata Meydana Geldi. Hata: ' + ERROR_MESSAGE())
        PRINT '! Departman Listesindeki Departmanı Getiriken Hata Meydana Geldi. Hata: ' + ERROR_MESSAGE()
    END CATCH
END

-- AddDepartment Procedure
CREATE PROCEDURE AddDepartment
    @Title nvarchar(50)
AS
BEGIN
    BEGIN TRY
        INSERT INTO [XBankDB].[dnc].[Departments] (Title)
        VALUES (@Title)

        -- Başarılı işlem logu
        INSERT INTO dnc.BankLog(LogDescription) VALUES ('Departman Ekleme İşlemi Başarılı')
        PRINT 'Departman Ekleme İşlemleri Başarılı'
    END TRY
    BEGIN CATCH
        INSERT INTO dnc.BankLog(LogDescription) VALUES ('Departman Ekleme İşlemi Başarısız. Hata: ' + ERROR_MESSAGE())
        PRINT '! Departman Ekleme İşlemi Başarısız. Hata: ' + ERROR_MESSAGE()
    END CATCH
END

-- UpdateDepartment Procedure
CREATE PROCEDURE UpdateDepartment
    @DepartmentID int,
    @Title nvarchar(50)
AS
BEGIN
    BEGIN TRY
        UPDATE [XBankDB].[dnc].[Departments]
        SET Title = @Title,
            ModifiedDate = GETDATE()
        WHERE DepartmentID = @DepartmentID

        -- Başarılı işlem logu
        INSERT INTO dnc.BankLog(LogDescription) VALUES ('Departman Güncelleme İşlemi Başarılı')
        PRINT 'Departman Güncelleme İşlemleri Başarılı'
    END TRY
    BEGIN CATCH
        INSERT INTO dnc.BankLog(LogDescription) VALUES ('Departman Güncelleme İşlemi Başarısız. Hata: ' + ERROR_MESSAGE())
        PRINT '! Departman Güncelleme İşlemi Başarısız. Hata: ' + ERROR_MESSAGE()
    END CATCH
END

-- SoftDeleteDepartment Procedure
CREATE PROCEDURE SoftDeleteDepartment
    @DepartmentID int
AS
BEGIN
    BEGIN TRY
        -- Burada sadece IsActive değerini güncelliyoruz
        UPDATE [XBankDB].[dnc].[Departments]
        SET IsActive = 0
        WHERE DepartmentID = @DepartmentID

        -- Başarılı işlem logu
        INSERT INTO dnc.BankLog(LogDescription) VALUES ('Departman Silme İşlemi Başarılı')
        PRINT 'Departman Silme İşlemleri Başarılı'
    END TRY
    BEGIN CATCH
         INSERT INTO dnc.BankLog(LogDescription) VALUES ('Departman Silme İşlemi Başarısız. Hata: ' + ERROR_MESSAGE())
         PRINT '! Departman Silme İşlemi Başarısız. Hata: ' + ERROR_MESSAGE()
    END CATCH
END

-- HardDeleteDepartment Procedure
CREATE PROCEDURE HardDeleteDepartment
    @DepartmentID int
AS
BEGIN
    BEGIN TRY
        DELETE FROM [XBankDB].[dnc].[Departments]
        WHERE DepartmentID = @DepartmentID

        -- Başarılı işlem logu
        INSERT INTO dnc.BankLog(LogDescription) VALUES ('Departman Kalıcı Silme İşlemi Başarılı')
        PRINT 'Departman Kalıcı Silme İşlemleri Başarılı'
    END TRY
    BEGIN CATCH
        INSERT INTO dnc.BankLog(LogDescription) VALUES ('Departman Silme İşlemi Başarısız. Hata: ' + ERROR_MESSAGE())
        PRINT '! Departman Silme İşlemi Başarısız. Hata: ' + ERROR_MESSAGE()
    END CATCH
END




--------------------------- EmployeeAuthorization Stored Procedure ----------------------------
-- ListEmployeeAuthorizations Procedure
CREATE PROCEDURE ListEmployeeAuthorizations
AS
BEGIN
    BEGIN TRY
        SELECT AuthorizationID, RoleID, ObjectName, ObjectType, PermissionType, CreatedDate, ModifiedDate, IsActive
        FROM [XBankDB].[dnc].[EmployeeAuthorization]

        -- Başarılı işlem logu
        INSERT INTO dnc.BankLog(LogDescription) VALUES ('Çalışan Yetkilerini Listeleme İşlemi Başarılı')
        PRINT 'Çalışan Yetkilerini Listeleme İşlemleri Başarılı'
    END TRY
    BEGIN CATCH
        -- Hata durumunda yapılacak işlemler buraya yazılır
        INSERT INTO dnc.BankLog(LogDescription) VALUES ('! Çalışan Yetkilerini Listelerken Hata Meydana Geldi. Hata: ' + ERROR_MESSAGE())
        PRINT '! Çalışan Yetkilerini Listelerken Hata Meydana Geldi. Hata: ' + ERROR_MESSAGE()
    END CATCH
END

-- FilterEmployeeAuthorizations Procedure
CREATE PROCEDURE FilterEmployeeAuthorizations
    @AuthorizationID uniqueidentifier = NULL,
    @RoleID int = NULL,
    @ObjectName nvarchar(50) = NULL,
    @ObjectType nvarchar(50) = NULL,
    @PermissionType nvarchar(50) = NULL
AS
BEGIN
    BEGIN TRY
        SELECT AuthorizationID, RoleID, ObjectName, ObjectType, PermissionType, CreatedDate, ModifiedDate, IsActive
        FROM [XBankDB].[dnc].[EmployeeAuthorization]
        WHERE
            (@AuthorizationID IS NULL OR AuthorizationID = @AuthorizationID) AND
            (@RoleID IS NULL OR RoleID = @RoleID) AND
            (@ObjectName IS NULL OR ObjectName = @ObjectName) AND
            (@ObjectType IS NULL OR ObjectType = @ObjectType) AND
            (@PermissionType IS NULL OR PermissionType = @PermissionType)

        INSERT INTO dnc.BankLog(LogDescription) VALUES ('Çalışan Yetkilerini Listeleme İşlemi Başarılı')
        PRINT 'Çalışan Yetkilerini Listeleme İşlemleri Başarılı'
    END TRY
    BEGIN CATCH
        INSERT INTO dnc.BankLog(LogDescription) VALUES ('! Çalışan Yetkilerini Listelerken Hata Meydana Geldi. Hata: ' + ERROR_MESSAGE())
        PRINT '! Çalışan Yetkilerini Listelerken Hata Meydana Geldi. Hata: ' + ERROR_MESSAGE()
    END CATCH
END

-- GetEmployeeAuthorizationByID Procedure
CREATE PROCEDURE GetEmployeeAuthorizationByID
    @AuthorizationID uniqueidentifier
AS
BEGIN
    BEGIN TRY
        SELECT AuthorizationID, RoleID, ObjectName, ObjectType, PermissionType, CreatedDate, ModifiedDate, IsActive
        FROM [XBankDB].[dnc].[EmployeeAuthorization]
        WHERE AuthorizationID = @AuthorizationID

        INSERT INTO dnc.BankLog(LogDescription) VALUES ('Çalışan Yetkileri Listesindeki Yetki İşlemi Başarılı Bir Şekilde Geldi.')
        PRINT 'Çalışan Yetkileri Listesindeki Yetki İşlemi Başarılı Bir Şekilde Geldi.'
    END TRY
    BEGIN CATCH
        INSERT INTO dnc.BankLog(LogDescription) VALUES ('! Çalışan Yetkileri Listesindeki Yetkiyi Getiriken Hata Meydana Geldi. Hata: ' + ERROR_MESSAGE())
        PRINT '! Çalışan Yetkileri Listesindeki Yetkiyi Getiriken Hata Meydana Geldi. Hata: ' + ERROR_MESSAGE()
    END CATCH
END

-- AddEmployeeAuthorization Procedure
CREATE PROCEDURE AddEmployeeAuthorization
    @RoleID int,
    @ObjectName nvarchar(50),
    @ObjectType nvarchar(50),
    @PermissionType nvarchar(50)
AS
BEGIN
    BEGIN TRY
        INSERT INTO [XBankDB].[dnc].[EmployeeAuthorization] (RoleID, ObjectName, ObjectType, PermissionType)
        VALUES (@RoleID, @ObjectName, @ObjectType, @PermissionType)

        -- Başarılı işlem logu
        INSERT INTO dnc.BankLog(LogDescription) VALUES ('Çalışan Yetkisi Ekleme İşlemi Başarılı')
        PRINT 'Çalışan Yetkisi Ekleme İşlemleri Başarılı'
    END TRY
    BEGIN CATCH
        INSERT INTO dnc.BankLog(LogDescription) VALUES ('Çalışan Yetkisi Ekleme İşlemi Başarısız. Hata: ' + ERROR_MESSAGE())
        PRINT '! Çalışan Yetkisi Ekleme İşlemi Başarısız. Hata: ' + ERROR_MESSAGE()
    END CATCH
END

-- UpdateEmployeeAuthorization Procedure
CREATE PROCEDURE UpdateEmployeeAuthorization
    @AuthorizationID uniqueidentifier,
    @RoleID int,
    @ObjectName nvarchar(50),
    @ObjectType nvarchar(50),
    @PermissionType nvarchar(50)
AS
BEGIN
    BEGIN TRY
        UPDATE [XBankDB].[dnc].[EmployeeAuthorization]
        SET RoleID = @RoleID,
            ObjectName = @ObjectName,
            ObjectType = @ObjectType,
            PermissionType = @PermissionType,
            ModifiedDate = GETDATE()
        WHERE AuthorizationID = @AuthorizationID

        -- Başarılı işlem logu
        INSERT INTO dnc.BankLog(LogDescription) VALUES ('Çalışan Yetkisi Güncelleme İşlemi Başarılı')
        PRINT 'Çalışan Yetkisi Güncelleme İşlemleri Başarılı'
    END TRY
    BEGIN CATCH
        INSERT INTO dnc.BankLog(LogDescription) VALUES ('Çalışan Yetkisi Güncelleme İşlemi Başarısız. Hata: ' + ERROR_MESSAGE())
        PRINT '! Çalışan Yetkisi Güncelleme İşlemi Başarısız. Hata: ' + ERROR_MESSAGE()
    END CATCH
END

-- SoftDeleteEmployeeAuthorization Procedure
CREATE PROCEDURE SoftDeleteEmployeeAuthorization
    @AuthorizationID uniqueidentifier
AS
BEGIN
    BEGIN TRY
        -- Burada sadece IsActive değerini güncelliyoruz
        UPDATE [XBankDB].[dnc].[EmployeeAuthorization]
        SET IsActive = 0
        WHERE AuthorizationID = @AuthorizationID

        -- Başarılı işlem logu
        INSERT INTO dnc.BankLog(LogDescription) VALUES ('Çalışan Yetkisi Silme İşlemi Başarılı')
        PRINT 'Çalışan Yetkisi Silme İşlemleri Başarılı'
    END TRY
    BEGIN CATCH
         INSERT INTO dnc.BankLog(LogDescription) VALUES ('Çalışan Yetkisi Silme İşlemi Başarısız. Hata: ' + ERROR_MESSAGE())
         PRINT '! Çalışan Yetkisi Silme İşlemi Başarısız. Hata: ' + ERROR_MESSAGE()
    END CATCH
END

-- HardDeleteEmployeeAuthorization Procedure
CREATE PROCEDURE HardDeleteEmployeeAuthorization
    @AuthorizationID uniqueidentifier
AS
BEGIN
    BEGIN TRY
        DELETE FROM [XBankDB].[dnc].[EmployeeAuthorization]
        WHERE AuthorizationID = @AuthorizationID

        -- Başarılı işlem logu
        INSERT INTO dnc.BankLog(LogDescription) VALUES ('Çalışan Yetkisi Kalıcı Silme İşlemi Başarılı')
        PRINT 'Çalışan Yetkisi Kalıcı Silme İşlemleri Başarılı'
    END TRY
    BEGIN CATCH
        INSERT INTO dnc.BankLog(LogDescription) VALUES ('Çalışan Yetkisi Silme İşlemi Başarısız. Hata: ' + ERROR_MESSAGE())
        PRINT '! Çalışan Yetkisi Silme İşlemi Başarısız. Hata: ' + ERROR_MESSAGE()
    END CATCH
END




--------------------------- Employee Roles Stored Procedure ----------------------------


-- ListEmployeeRoles Procedure
CREATE PROCEDURE ListEmployeeRoles
AS
BEGIN
    BEGIN TRY
        SELECT RoleID, Title, CreatedDate, ModifiedDate, IsActive
        FROM [XBankDB].[dnc].[EmployeeRoles]

        -- Başarılı işlem logu
        INSERT INTO dnc.BankLog(LogDescription) VALUES ('Çalışan Rollerini Listeleme İşlemi Başarılı')
        PRINT 'Çalışan Rollerini Listeleme İşlemleri Başarılı'
    END TRY
    BEGIN CATCH
        -- Hata durumunda yapılacak işlemler buraya yazılır
        INSERT INTO dnc.BankLog(LogDescription) VALUES ('! Çalışan Rollerini Listelerken Hata Meydana Geldi. Hata: ' + ERROR_MESSAGE())
        PRINT '! Çalışan Rollerini Listelerken Hata Meydana Geldi. Hata: ' + ERROR_MESSAGE()
    END CATCH
END

-- FilterEmployeeRoles Procedure
CREATE PROCEDURE FilterEmployeeRoles
    @RoleID int = NULL,
    @Title nvarchar(30) = NULL
AS
BEGIN
    BEGIN TRY
        SELECT RoleID, Title, CreatedDate, ModifiedDate, IsActive
        FROM [XBankDB].[dnc].[EmployeeRoles]
        WHERE
            (@RoleID IS NULL OR RoleID = @RoleID) AND
            (@Title IS NULL OR Title = @Title)

        INSERT INTO dnc.BankLog(LogDescription) VALUES ('Çalışan Rollerini Listeleme İşlemi Başarılı')
        PRINT 'Çalışan Rollerini Listeleme İşlemleri Başarılı'
    END TRY
    BEGIN CATCH
        INSERT INTO dnc.BankLog(LogDescription) VALUES ('! Çalışan Rollerini Listelerken Hata Meydana Geldi. Hata: ' + ERROR_MESSAGE())
        PRINT '! Çalışan Rollerini Listelerken Hata Meydana Geldi. Hata: ' + ERROR_MESSAGE()
    END CATCH
END

-- GetEmployeeRoleByID Procedure
CREATE PROCEDURE GetEmployeeRoleByID
    @RoleID int
AS
BEGIN
    BEGIN TRY
        SELECT RoleID, Title, CreatedDate, ModifiedDate, IsActive
        FROM [XBankDB].[dnc].[EmployeeRoles]
        WHERE RoleID = @RoleID

        INSERT INTO dnc.BankLog(LogDescription) VALUES ('Çalışan Rollerindeki Rol İşlemi Başarılı Bir Şekilde Geldi.')
        PRINT 'Çalışan Rollerindeki Rol İşlemi Başarılı Bir Şekilde Geldi.'
    END TRY
    BEGIN CATCH
        INSERT INTO dnc.BankLog(LogDescription) VALUES ('! Çalışan Rollerindeki Rolü Getiriken Hata Meydana Geldi. Hata: ' + ERROR_MESSAGE())
        PRINT '! Çalışan Rollerindeki Rolü Getiriken Hata Meydana Geldi. Hata: ' + ERROR_MESSAGE()
    END CATCH
END

-- AddEmployeeRole Procedure
CREATE PROCEDURE AddEmployeeRole
    @Title nvarchar(30)
AS
BEGIN
    BEGIN TRY
        INSERT INTO [XBankDB].[dnc].[EmployeeRoles] (Title)
        VALUES (@Title)

        -- Başarılı işlem logu
        INSERT INTO dnc.BankLog(LogDescription) VALUES ('Çalışan Rolü Ekleme İşlemi Başarılı')
        PRINT 'Çalışan Rolü Ekleme İşlemleri Başarılı'
    END TRY
    BEGIN CATCH
        INSERT INTO dnc.BankLog(LogDescription) VALUES ('Çalışan Rolü Ekleme İşlemi Başarısız. Hata: ' + ERROR_MESSAGE())
        PRINT '! Çalışan Rolü Ekleme İşlemi Başarısız. Hata: ' + ERROR_MESSAGE()
    END CATCH
END

-- UpdateEmployeeRole Procedure
CREATE PROCEDURE UpdateEmployeeRole
    @RoleID int,
    @Title nvarchar(30)
AS
BEGIN
    BEGIN TRY
        UPDATE [XBankDB].[dnc].[EmployeeRoles]
        SET Title = @Title,
            ModifiedDate = GETDATE()
        WHERE RoleID = @RoleID

        -- Başarılı işlem logu
        INSERT INTO dnc.BankLog(LogDescription) VALUES ('Çalışan Rolü Güncelleme İşlemi Başarılı')
        PRINT 'Çalışan Rolü Güncelleme İşlemleri Başarılı'
    END TRY
    BEGIN CATCH
        INSERT INTO dnc.BankLog(LogDescription) VALUES ('Çalışan Rolü Güncelleme İşlemi Başarısız. Hata: ' + ERROR_MESSAGE())
        PRINT '! Çalışan Rolü Güncelleme İşlemi Başarısız. Hata: ' + ERROR_MESSAGE()
    END CATCH
END

-- SoftDeleteEmployeeRole Procedure
CREATE PROCEDURE SoftDeleteEmployeeRole
    @RoleID int
AS
BEGIN
    BEGIN TRY
        -- Burada sadece IsActive değerini güncelliyoruz
        UPDATE [XBankDB].[dnc].[EmployeeRoles]
        SET IsActive = 0
        WHERE RoleID = @RoleID

        -- Başarılı işlem logu
        INSERT INTO dnc.BankLog(LogDescription) VALUES ('Çalışan Rolü Silme İşlemi Başarılı')
        PRINT 'Çalışan Rolü Silme İşlemleri Başarılı'
    END TRY
    BEGIN CATCH
         INSERT INTO dnc.BankLog(LogDescription) VALUES ('Çalışan Rolü Silme İşlemi Başarısız. Hata: ' + ERROR_MESSAGE())
         PRINT '! Çalışan Rolü Silme İşlemi Başarısız. Hata: ' + ERROR_MESSAGE()
    END CATCH
END

-- HardDeleteEmployeeRole Procedure
CREATE PROCEDURE HardDeleteEmployeeRole
    @RoleID int
AS
BEGIN
    BEGIN TRY
        DELETE FROM [XBankDB].[dnc].[EmployeeRoles]
        WHERE RoleID = @RoleID

        -- Başarılı işlem logu
        INSERT INTO dnc.BankLog(LogDescription) VALUES ('Çalışan Rolü Kalıcı Silme İşlemi Başarılı')
        PRINT 'Çalışan Rolü Kalıcı Silme İşlemleri Başarılı'
    END TRY
    BEGIN CATCH
        INSERT INTO dnc.BankLog(LogDescription) VALUES ('Çalışan Rolü Silme İşlemi Başarısız. Hata: ' + ERROR_MESSAGE())
        PRINT '! Çalışan Rolü Silme İşlemi Başarısız. Hata: ' + ERROR_MESSAGE()
    END CATCH
END




--------------------------- Employees Stored Procedure ----------------------------

-- ListEmployees Procedure
CREATE PROCEDURE ListEmployees
AS
BEGIN
    BEGIN TRY
        SELECT EmployeeID, FirstName, LastName, RoleID, DepartmentID, CreatedDate, ModifiedDate, IsActive
        FROM [XBankDB].[dnc].[Employees]

        -- Başarılı işlem logu
        INSERT INTO dnc.BankLog(LogDescription) VALUES ('Çalışanları Listeleme İşlemi Başarılı')
        PRINT 'Çalışanları Listeleme İşlemleri Başarılı'
    END TRY
    BEGIN CATCH
        -- Hata durumunda yapılacak işlemler buraya yazılır
        INSERT INTO dnc.BankLog(LogDescription) VALUES ('! Çalışanları Listelerken Hata Meydana Geldi. Hata: ' + ERROR_MESSAGE())
        PRINT '! Çalışanları Listelerken Hata Meydana Geldi. Hata: ' + ERROR_MESSAGE()
    END CATCH
END

-- FilterEmployees Procedure
CREATE PROCEDURE FilterEmployees
    @EmployeeID uniqueidentifier = NULL,
    @FirstName nvarchar(50) = NULL,
    @LastName nvarchar(50) = NULL,
    @RoleID int = NULL,
    @DepartmentID int = NULL
AS
BEGIN
    BEGIN TRY
        SELECT EmployeeID, FirstName, LastName, RoleID, DepartmentID, CreatedDate, ModifiedDate, IsActive
        FROM [XBankDB].[dnc].[Employees]
        WHERE
            (@EmployeeID IS NULL OR EmployeeID = @EmployeeID) AND
            (@FirstName IS NULL OR FirstName = @FirstName) AND
            (@LastName IS NULL OR LastName = @LastName) AND
            (@RoleID IS NULL OR RoleID = @RoleID) AND
            (@DepartmentID IS NULL OR DepartmentID = @DepartmentID)

        INSERT INTO dnc.BankLog(LogDescription) VALUES ('Çalışanları Listeleme İşlemi Başarılı')
        PRINT 'Çalışanları Listeleme İşlemleri Başarılı'
    END TRY
    BEGIN CATCH
        INSERT INTO dnc.BankLog(LogDescription) VALUES ('! Çalışanları Listelerken Hata Meydana Geldi. Hata: ' + ERROR_MESSAGE())
        PRINT '! Çalışanları Listelerken Hata Meydana Geldi. Hata: ' + ERROR_MESSAGE()
    END CATCH
END

-- GetEmployeeByID Procedure
CREATE PROCEDURE GetEmployeeByID
    @EmployeeID uniqueidentifier
AS
BEGIN
    BEGIN TRY
        SELECT EmployeeID, FirstName, LastName, RoleID, DepartmentID, CreatedDate, ModifiedDate, IsActive
        FROM [XBankDB].[dnc].[Employees]
        WHERE EmployeeID = @EmployeeID

        INSERT INTO dnc.BankLog(LogDescription) VALUES ('Çalışan Listesindeki Çalışan İşlemi Başarılı Bir Şekilde Geldi.')
        PRINT 'Çalışan Listesindeki Çalışan İşlemi Başarılı Bir Şekilde Geldi.'
    END TRY
    BEGIN CATCH
        INSERT INTO dnc.BankLog(LogDescription) VALUES ('! Çalışan Listesindeki Çalışanı Getiriken Hata Meydana Geldi. Hata: ' + ERROR_MESSAGE())
        PRINT '! Çalışan Listesindeki Çalışanı Getiriken Hata Meydana Geldi. Hata: ' + ERROR_MESSAGE()
    END CATCH
END

-- AddEmployee Procedure
CREATE PROCEDURE AddEmployee
    @FirstName nvarchar(50),
    @LastName nvarchar(50),
    @RoleID int,
    @DepartmentID int
AS
BEGIN
    BEGIN TRY
        INSERT INTO [XBankDB].[dnc].[Employees] (FirstName, LastName, RoleID, DepartmentID)
        VALUES (@FirstName, @LastName, @RoleID, @DepartmentID)

        -- Başarılı işlem logu
        INSERT INTO dnc.BankLog(LogDescription) VALUES ('Çalışan Ekleme İşlemi Başarılı')
        PRINT 'Çalışan Ekleme İşlemleri Başarılı'
    END TRY
    BEGIN CATCH
        INSERT INTO dnc.BankLog(LogDescription) VALUES ('Çalışan Ekleme İşlemi Başarısız. Hata: ' + ERROR_MESSAGE())
        PRINT '! Çalışan Ekleme İşlemi Başarısız. Hata: ' + ERROR_MESSAGE()
    END CATCH
END

-- UpdateEmployee Procedure
CREATE PROCEDURE UpdateEmployee
    @EmployeeID uniqueidentifier,
    @FirstName nvarchar(50),
    @LastName nvarchar(50),
    @RoleID int,
    @DepartmentID int
AS
BEGIN
    BEGIN TRY
        UPDATE [XBankDB].[dnc].[Employees]
        SET FirstName = @FirstName,
            LastName = @LastName,
            RoleID = @RoleID,
            DepartmentID = @DepartmentID,
            ModifiedDate = GETDATE()
        WHERE EmployeeID = @EmployeeID

        -- Başarılı işlem logu
        INSERT INTO dnc.BankLog(LogDescription) VALUES ('Çalışan Güncelleme İşlemi Başarılı')
        PRINT 'Çalışan Güncelleme İşlemleri Başarılı'
    END TRY
    BEGIN CATCH
        INSERT INTO dnc.BankLog(LogDescription) VALUES ('Çalışan Güncelleme İşlemi Başarısız. Hata: ' + ERROR_MESSAGE())
        PRINT '! Çalışan Güncelleme İşlemi Başarısız. Hata: ' + ERROR_MESSAGE()
    END CATCH
END

-- SoftDeleteEmployee Procedure
CREATE PROCEDURE SoftDeleteEmployee
    @EmployeeID uniqueidentifier
AS
BEGIN
    BEGIN TRY
        -- Burada sadece IsActive değerini güncelliyoruz
        UPDATE [XBankDB].[dnc].[Employees]
        SET IsActive = 0
        WHERE EmployeeID = @EmployeeID

        -- Başarılı işlem logu
        INSERT INTO dnc.BankLog(LogDescription) VALUES ('Çalışan Silme İşlemi Başarılı')
        PRINT 'Çalışan Silme İşlemleri Başarılı'
    END TRY
    BEGIN CATCH
         INSERT INTO dnc.BankLog(LogDescription) VALUES ('Çalışan Silme İşlemi Başarısız. Hata: ' + ERROR_MESSAGE())
         PRINT '! Çalışan Silme İşlemi Başarısız. Hata: ' + ERROR_MESSAGE()
    END CATCH
END

-- HardDeleteEmployee Procedure
CREATE PROCEDURE HardDeleteEmployee
    @EmployeeID uniqueidentifier
AS
BEGIN
    BEGIN TRY
        DELETE FROM [XBankDB].[dnc].[Employees]
        WHERE EmployeeID = @EmployeeID

        -- Başarılı işlem logu
        INSERT INTO dnc.BankLog(LogDescription) VALUES ('Çalışan Kalıcı Silme İşlemi Başarılı')
        PRINT 'Çalışan Kalıcı Silme İşlemleri Başarılı'
    END TRY
    BEGIN CATCH
        INSERT INTO dnc.BankLog(LogDescription) VALUES ('Çalışan Silme İşlemi Başarısız. Hata: ' + ERROR_MESSAGE())
        PRINT '! Çalışan Silme İşlemi Başarısız. Hata: ' + ERROR_MESSAGE()
    END CATCH
END




--------------------------- EmployeeLogin Stored Procedure ----------------------------


-- ListEmployeeLogins Procedure
CREATE PROCEDURE ListEmployeeLogins
AS
BEGIN
    BEGIN TRY
        SELECT LoginID, EmployeeID, UserPassword, PasswordSalt, CreatedDate, ModifiedDate, IsActive
        FROM [XBankDB].[dnc].[EmployeesLogin]

        -- Başarılı işlem logu
        INSERT INTO dnc.BankLog(LogDescription) VALUES ('Çalışan Giriş Bilgilerini Listeleme İşlemi Başarılı')
        PRINT 'Çalışan Giriş Bilgilerini Listeleme İşlemleri Başarılı'
    END TRY
    BEGIN CATCH
        -- Hata durumunda yapılacak işlemler buraya yazılır
        INSERT INTO dnc.BankLog(LogDescription) VALUES ('! Çalışan Giriş Bilgilerini Listelerken Hata Meydana Geldi. Hata: ' + ERROR_MESSAGE())
        PRINT '! Çalışan Giriş Bilgilerini Listelerken Hata Meydana Geldi. Hata: ' + ERROR_MESSAGE()
    END CATCH
END

-- GetEmployeeLoginByID Procedure
CREATE PROCEDURE GetEmployeeLoginByID
    @LoginID uniqueidentifier
AS
BEGIN
    BEGIN TRY
        SELECT LoginID, EmployeeID, UserPassword, PasswordSalt, CreatedDate, ModifiedDate, IsActive
        FROM [XBankDB].[dnc].[EmployeesLogin]
        WHERE LoginID = @LoginID

        INSERT INTO dnc.BankLog(LogDescription) VALUES ('Çalışan Giriş Bilgisi Listesindeki Giriş Bilgisi İşlemi Başarılı Bir Şekilde Geldi.')
        PRINT 'Çalışan Giriş Bilgisi Listesindeki Giriş Bilgisi İşlemi Başarılı Bir Şekilde Geldi.'
    END TRY
    BEGIN CATCH
        INSERT INTO dnc.BankLog(LogDescription) VALUES ('! Çalışan Giriş Bilgisi Listesindeki Giriş Bilgisini Getiriken Hata Meydana Geldi. Hata: ' + ERROR_MESSAGE())
        PRINT '! Çalışan Giriş Bilgisi Listesindeki Giriş Bilgisini Getiriken Hata Meydana Geldi. Hata: ' + ERROR_MESSAGE()
    END CATCH
END

-- AddEmployeeLogin Procedure
CREATE PROCEDURE AddEmployeeLogin
    @EmployeeID uniqueidentifier,
    @UserPassword varbinary(max),
    @PasswordSalt varbinary(max)
AS
BEGIN
    BEGIN TRY
        INSERT INTO [XBankDB].[dnc].[EmployeesLogin] (EmployeeID, UserPassword, PasswordSalt)
        VALUES (@EmployeeID, @UserPassword, @PasswordSalt)

        -- Başarılı işlem logu
        INSERT INTO dnc.BankLog(LogDescription) VALUES ('Çalışan Giriş Bilgisi Ekleme İşlemi Başarılı')
        PRINT 'Çalışan Giriş Bilgisi Ekleme İşlemleri Başarılı'
    END TRY
    BEGIN CATCH
        INSERT INTO dnc.BankLog(LogDescription) VALUES ('Çalışan Giriş Bilgisi Ekleme İşlemi Başarısız. Hata: ' + ERROR_MESSAGE())
        PRINT '! Çalışan Giriş Bilgisi Ekleme İşlemi Başarısız. Hata: ' + ERROR_MESSAGE()
    END CATCH
END

-- UpdateEmployeeLogin Procedure
CREATE PROCEDURE UpdateEmployeeLogin
    @LoginID uniqueidentifier,
    @UserPassword varbinary(max),
    @PasswordSalt varbinary(max)
AS
BEGIN
    BEGIN TRY
        UPDATE [XBankDB].[dnc].[EmployeesLogin]
        SET UserPassword = @UserPassword,
            PasswordSalt = @PasswordSalt,
            ModifiedDate = GETDATE()
        WHERE LoginID = @LoginID

        -- Başarılı işlem logu
        INSERT INTO dnc.BankLog(LogDescription) VALUES ('Çalışan Giriş Bilgisi Güncelleme İşlemi Başarılı')
        PRINT 'Çalışan Giriş Bilgisi Güncelleme İşlemleri Başarılı'
    END TRY
    BEGIN CATCH
        INSERT INTO dnc.BankLog(LogDescription) VALUES ('Çalışan Giriş Bilgisi Güncelleme İşlemi Başarısız. Hata: ' + ERROR_MESSAGE())
        PRINT '! Çalışan Giriş Bilgisi Güncelleme İşlemi Başarısız. Hata: ' + ERROR_MESSAGE()
    END CATCH
END

-- SoftDeleteEmployeeLogin Procedure
CREATE PROCEDURE SoftDeleteEmployeeLogin
    @LoginID uniqueidentifier
AS
BEGIN
    BEGIN TRY
        -- Burada sadece IsActive değerini güncelliyoruz
        UPDATE [XBankDB].[dnc].[EmployeesLogin]
        SET IsActive = 0
        WHERE LoginID = @LoginID

        -- Başarılı işlem logu
        INSERT INTO dnc.BankLog(LogDescription) VALUES ('Çalışan Giriş Bilgisi Silme İşlemi Başarılı')
        PRINT 'Çalışan Giriş Bilgisi Silme İşlemleri Başarılı'
    END TRY
    BEGIN CATCH
         INSERT INTO dnc.BankLog(LogDescription) VALUES ('Çalışan Giriş Bilgisi Silme İşlemi Başarısız. Hata: ' + ERROR_MESSAGE())
         PRINT '! Çalışan Giriş Bilgisi Silme İşlemi Başarısız. Hata: ' + ERROR_MESSAGE()
    END CATCH
END

-- HardDeleteEmployeeLogin Procedure
CREATE PROCEDURE HardDeleteEmployeeLogin
    @LoginID uniqueidentifier
AS
BEGIN
    BEGIN TRY
        DELETE FROM [XBankDB].[dnc].[EmployeesLogin]
        WHERE LoginID = @LoginID

        -- Başarılı işlem logu
        INSERT INTO dnc.BankLog(LogDescription) VALUES ('Çalışan Giriş Bilgisi Kalıcı Silme İşlemi Başarılı')
        PRINT 'Çalışan Giriş Bilgisi Kalıcı Silme İşlemleri Başarılı'
    END TRY
    BEGIN CATCH
        INSERT INTO dnc.BankLog(LogDescription) VALUES ('Çalışan Giriş Bilgisi Silme İşlemi Başarısız. Hata: ' + ERROR_MESSAGE())
        PRINT '! Çalışan Giriş Bilgisi Silme İşlemi Başarısız. Hata: ' + ERROR_MESSAGE()
    END CATCH
END




--------------------------- Institues Stored Procedure ----------------------------

-- ListInstitutes Procedure
CREATE PROCEDURE ListInstitutes
AS
BEGIN
    BEGIN TRY
        SELECT InstituteID, InstituteTitle, CreatedDate, ModifiedDate, IsActive
        FROM [XBankDB].[dnc].[Institute]

        -- Başarılı işlem logu
        INSERT INTO dnc.BankLog(LogDescription) VALUES ('Kurumları Listeleme İşlemi Başarılı')
        PRINT 'Kurumları Listeleme İşlemleri Başarılı'
    END TRY
    BEGIN CATCH
        -- Hata durumunda yapılacak işlemler buraya yazılır
        INSERT INTO dnc.BankLog(LogDescription) VALUES ('! Kurumları Listelerken Hata Meydana Geldi. Hata: ' + ERROR_MESSAGE())
        PRINT '! Kurumları Listelerken Hata Meydana Geldi. Hata: ' + ERROR_MESSAGE()
    END CATCH
END

-- GetInstituteByID Procedure
CREATE PROCEDURE GetInstituteByID
    @InstituteID int
AS
BEGIN
    BEGIN TRY
        SELECT InstituteID, InstituteTitle, CreatedDate, ModifiedDate, IsActive
        FROM [XBankDB].[dnc].[Institute]
        WHERE InstituteID = @InstituteID

        INSERT INTO dnc.BankLog(LogDescription) VALUES ('Kurum Listesindeki Kurum İşlemi Başarılı Bir Şekilde Geldi.')
        PRINT 'Kurum Listesindeki Kurum İşlemi Başarılı Bir Şekilde Geldi.'
    END TRY
    BEGIN CATCH
        INSERT INTO dnc.BankLog(LogDescription) VALUES ('! Kurum Listesindeki Kurumu Getiriken Hata Meydana Geldi. Hata: ' + ERROR_MESSAGE())
        PRINT '! Kurum Listesindeki Kurumu Getiriken Hata Meydana Geldi. Hata: ' + ERROR_MESSAGE()
    END CATCH
END

-- AddInstitute Procedure
CREATE PROCEDURE AddInstitute
    @InstituteTitle nvarchar(250)
AS
BEGIN
    BEGIN TRY
        INSERT INTO [XBankDB].[dnc].[Institute] (InstituteTitle)
        VALUES (@InstituteTitle)

        -- Başarılı işlem logu
        INSERT INTO dnc.BankLog(LogDescription) VALUES ('Kurum Ekleme İşlemi Başarılı')
        PRINT 'Kurum Ekleme İşlemleri Başarılı'
    END TRY
    BEGIN CATCH
        INSERT INTO dnc.BankLog(LogDescription) VALUES ('Kurum Ekleme İşlemi Başarısız. Hata: ' + ERROR_MESSAGE())
        PRINT '! Kurum Ekleme İşlemi Başarısız. Hata: ' + ERROR_MESSAGE()
    END CATCH
END

-- UpdateInstitute Procedure
CREATE PROCEDURE UpdateInstitute
    @InstituteID int,
    @InstituteTitle nvarchar(250)
AS
BEGIN
    BEGIN TRY
        UPDATE [XBankDB].[dnc].[Institute]
        SET InstituteTitle = @InstituteTitle,
            ModifiedDate = GETDATE()
        WHERE InstituteID = @InstituteID

        -- Başarılı işlem logu
        INSERT INTO dnc.BankLog(LogDescription) VALUES ('Kurum Güncelleme İşlemi Başarılı')
        PRINT 'Kurum Güncelleme İşlemleri Başarılı'
    END TRY
    BEGIN CATCH
        INSERT INTO dnc.BankLog(LogDescription) VALUES ('Kurum Güncelleme İşlemi Başarısız. Hata: ' + ERROR_MESSAGE())
        PRINT '! Kurum Güncelleme İşlemi Başarısız. Hata: ' + ERROR_MESSAGE()
    END CATCH
END

-- SoftDeleteInstitute Procedure
CREATE PROCEDURE SoftDeleteInstitute
    @InstituteID int
AS
BEGIN
    BEGIN TRY
        -- Burada sadece IsActive değerini güncelliyoruz
        UPDATE [XBankDB].[dnc].[Institute]
        SET IsActive = 0
        WHERE InstituteID = @InstituteID

        -- Başarılı işlem logu
        INSERT INTO dnc.BankLog(LogDescription) VALUES ('Kurum Silme İşlemi Başarılı')
        PRINT 'Kurum Silme İşlemleri Başarılı'
    END TRY
    BEGIN CATCH
         INSERT INTO dnc.BankLog(LogDescription) VALUES ('Kurum Silme İşlemi Başarısız. Hata: ' + ERROR_MESSAGE())
         PRINT '! Kurum Silme İşlemi Başarısız. Hata: ' + ERROR_MESSAGE()
    END CATCH
END

-- HardDeleteInstitute Procedure
CREATE PROCEDURE HardDeleteInstitute
    @InstituteID int
AS
BEGIN
    BEGIN TRY
        DELETE FROM [XBankDB].[dnc].[Institute]
        WHERE InstituteID = @InstituteID

        -- Başarılı işlem logu
        INSERT INTO dnc.BankLog(LogDescription) VALUES ('Kurum Kalıcı Silme İşlemi Başarılı')
        PRINT 'Kurum Kalıcı Silme İşlemleri Başarılı'
    END TRY
    BEGIN CATCH
        INSERT INTO dnc.BankLog(LogDescription) VALUES ('Kurum Silme İşlemi Başarısız. Hata: ' + ERROR_MESSAGE())
        PRINT '! Kurum Silme İşlemi Başarısız. Hata: ' + ERROR_MESSAGE()
    END CATCH
END




--------------------------- Opearation Type Stored Procedure ----------------------------

-- ListOperationTypes Procedure
CREATE PROCEDURE ListOperationTypes
AS
BEGIN
    BEGIN TRY
        SELECT ID, OperationTitle
        FROM [XBankDB].[dnc].[OperationType]

        -- Başarılı işlem logu
        INSERT INTO dnc.BankLog(LogDescription) VALUES ('İşlem Tiplerini Listeleme İşlemi Başarılı')
        PRINT 'İşlem Tiplerini Listeleme İşlemleri Başarılı'
    END TRY
    BEGIN CATCH
        -- Hata durumunda yapılacak işlemler buraya yazılır
        INSERT INTO dnc.BankLog(LogDescription) VALUES ('! İşlem Tiplerini Listelerken Hata Meydana Geldi. Hata: ' + ERROR_MESSAGE())
        PRINT '! İşlem Tiplerini Listelerken Hata Meydana Geldi. Hata: ' + ERROR_MESSAGE()
    END CATCH
END

-- GetOperationTypeByID Procedure
CREATE PROCEDURE GetOperationTypeByID
    @OperationTypeID smallint
AS
BEGIN
    BEGIN TRY
        SELECT ID, OperationTitle
        FROM [XBankDB].[dnc].[OperationType]
        WHERE ID = @OperationTypeID

        INSERT INTO dnc.BankLog(LogDescription) VALUES ('İşlem Tipi Listesindeki İşlem Tipi İşlemi Başarılı Bir Şekilde Geldi.')
        PRINT 'İşlem Tipi Listesindeki İşlem Tipi İşlemi Başarılı Bir Şekilde Geldi.'
    END TRY
    BEGIN CATCH
        INSERT INTO dnc.BankLog(LogDescription) VALUES ('! İşlem Tipi Listesindeki İşlem Tipini Getiriken Hata Meydana Geldi. Hata: ' + ERROR_MESSAGE())
        PRINT '! İşlem Tipi Listesindeki İşlem Tipini Getiriken Hata Meydana Geldi. Hata: ' + ERROR_MESSAGE()
    END CATCH
END

-- AddOperationType Procedure
CREATE PROCEDURE AddOperationType
    @OperationTitle nvarchar(300)
AS
BEGIN
    BEGIN TRY
        INSERT INTO [XBankDB].[dnc].[OperationType] (OperationTitle)
        VALUES (@OperationTitle)

        -- Başarılı işlem logu
        INSERT INTO dnc.BankLog(LogDescription) VALUES ('İşlem Tipi Ekleme İşlemi Başarılı')
        PRINT 'İşlem Tipi Ekleme İşlemleri Başarılı'
    END TRY
    BEGIN CATCH
        INSERT INTO dnc.BankLog(LogDescription) VALUES ('İşlem Tipi Ekleme İşlemi Başarısız. Hata: ' + ERROR_MESSAGE())
        PRINT '! İşlem Tipi Ekleme İşlemi Başarısız. Hata: ' + ERROR_MESSAGE()
    END CATCH
END

-- UpdateOperationType Procedure
CREATE PROCEDURE UpdateOperationType
    @OperationTypeID smallint,
    @OperationTitle nvarchar(300)
AS
BEGIN
    BEGIN TRY
        UPDATE [XBankDB].[dnc].[OperationType]
        SET OperationTitle = @OperationTitle
        WHERE ID = @OperationTypeID

        -- Başarılı işlem logu
        INSERT INTO dnc.BankLog(LogDescription) VALUES ('İşlem Tipi Güncelleme İşlemi Başarılı')
        PRINT 'İşlem Tipi Güncelleme İşlemleri Başarılı'
    END TRY
    BEGIN CATCH
        INSERT INTO dnc.BankLog(LogDescription) VALUES ('İşlem Tipi Güncelleme İşlemi Başarısız. Hata: ' + ERROR_MESSAGE())
        PRINT '! İşlem Tipi Güncelleme İşlemi Başarısız. Hata: ' + ERROR_MESSAGE()
    END CATCH
END

-- HardDeleteOperationType Procedure
CREATE PROCEDURE HardDeleteOperationType
    @OperationTypeID smallint
AS
BEGIN
    BEGIN TRY
        DELETE FROM [XBankDB].[dnc].[OperationType]
        WHERE ID = @OperationTypeID

        -- Başarılı işlem logu
        INSERT INTO dnc.BankLog(LogDescription) VALUES ('İşlem Tipi Kalıcı Silme İşlemi Başarılı')
        PRINT 'İşlem Tipi Kalıcı Silme İşlemleri Başarılı'
    END TRY
    BEGIN CATCH
        INSERT INTO dnc.BankLog(LogDescription) VALUES ('İşlem Tipi Silme İşlemi Başarısız. Hata: ' + ERROR_MESSAGE())
        PRINT '! İşlem Tipi Silme İşlemi Başarısız. Hata: ' + ERROR_MESSAGE()
    END CATCH
END



--------------------------- User Bank Cards Stored Procedure ----------------------------

-- ListUserBankCards Procedure
CREATE PROCEDURE ListUserBankCards
    @AccountID uniqueidentifier
AS
BEGIN
    BEGIN TRY
        SELECT CardID, CardNo, ExpirationDate, CvcCode, AccountID, CreatedDate, ModifiedDate, IsActive
        FROM [XBankDB].[dnc].[UserBankCards]
        WHERE AccountID = @AccountID

        -- Başarılı işlem logu
        INSERT INTO dnc.BankLog(LogDescription) VALUES ('Kullanıcı Banka Kartlarını Listeleme İşlemi Başarılı')
        PRINT 'Kullanıcı Banka Kartlarını Listeleme İşlemleri Başarılı'
    END TRY
    BEGIN CATCH
        -- Hata durumunda yapılacak işlemler buraya yazılır
        INSERT INTO dnc.BankLog(LogDescription) VALUES ('! Kullanıcı Banka Kartlarını Listelerken Hata Meydana Geldi. Hata: ' + ERROR_MESSAGE())
        PRINT '! Kullanıcı Banka Kartlarını Listelerken Hata Meydana Geldi. Hata: ' + ERROR_MESSAGE()
    END CATCH
END

-- GetUserBankCardByID Procedure
CREATE PROCEDURE GetUserBankCardByID
    @CardID uniqueidentifier
AS
BEGIN
    BEGIN TRY
        SELECT CardID, CardNo, ExpirationDate, CvcCode, AccountID, CreatedDate, ModifiedDate, IsActive
        FROM [XBankDB].[dnc].[UserBankCards]
        WHERE CardID = @CardID

        INSERT INTO dnc.BankLog(LogDescription) VALUES ('Kullanıcı Banka Kartı Listesindeki Kart İşlemi Başarılı Bir Şekilde Geldi.')
        PRINT 'Kullanıcı Banka Kartı Listesindeki Kart İşlemi Başarılı Bir Şekilde Geldi.'
    END TRY
    BEGIN CATCH
        INSERT INTO dnc.BankLog(LogDescription) VALUES ('! Kullanıcı Banka Kartı Listesindeki Kartı Getiriken Hata Meydana Geldi. Hata: ' + ERROR_MESSAGE())
        PRINT '! Kullanıcı Banka Kartı Listesindeki Kartı Getiriken Hata Meydana Geldi. Hata: ' + ERROR_MESSAGE()
    END CATCH
END

-- AddUserBankCard Procedure
CREATE PROCEDURE AddUserBankCard
    @CardNo nvarchar(16),
    @ExpirationDate date,
    @CvcCode smallint,
    @AccountID uniqueidentifier
AS
BEGIN
    BEGIN TRY
        INSERT INTO [XBankDB].[dnc].[UserBankCards] (CardNo, ExpirationDate, CvcCode, AccountID, CreatedDate)
        VALUES (@CardNo, @ExpirationDate, @CvcCode, @AccountID, GETDATE())

        -- Başarılı işlem logu
        INSERT INTO dnc.BankLog(LogDescription) VALUES ('Kullanıcı Banka Kartı Ekleme İşlemi Başarılı')
        PRINT 'Kullanıcı Banka Kartı Ekleme İşlemleri Başarılı'
    END TRY
    BEGIN CATCH
        INSERT INTO dnc.BankLog(LogDescription) VALUES ('Kullanıcı Banka Kartı Ekleme İşlemi Başarısız. Hata: ' + ERROR_MESSAGE())
        PRINT '! Kullanıcı Banka Kartı Ekleme İşlemi Başarısız. Hata: ' + ERROR_MESSAGE()
    END CATCH
END

-- UpdateUserBankCard Procedure
CREATE PROCEDURE UpdateUserBankCard
    @CardID uniqueidentifier,
    @CardNo nvarchar(16),
    @ExpirationDate date,
    @CvcCode smallint
AS
BEGIN
    BEGIN TRY
        UPDATE [XBankDB].[dnc].[UserBankCards]
        SET CardNo = @CardNo,
            ExpirationDate = @ExpirationDate,
            CvcCode = @CvcCode,
            ModifiedDate = GETDATE()
        WHERE CardID = @CardID

        -- Başarılı işlem logu
        INSERT INTO dnc.BankLog(LogDescription) VALUES ('Kullanıcı Banka Kartı Güncelleme İşlemi Başarılı')
        PRINT 'Kullanıcı Banka Kartı Güncelleme İşlemleri Başarılı'
    END TRY
    BEGIN CATCH
        INSERT INTO dnc.BankLog(LogDescription) VALUES ('Kullanıcı Banka Kartı Güncelleme İşlemi Başarısız. Hata: ' + ERROR_MESSAGE())
        PRINT '! Kullanıcı Banka Kartı Güncelleme İşlemi Başarısız. Hata: ' + ERROR_MESSAGE()
    END CATCH
END

-- SoftDeleteUserBankCard Procedure
CREATE PROCEDURE SoftDeleteUserBankCard
    @CardID uniqueidentifier
AS
BEGIN
    BEGIN TRY
        -- Burada sadece IsActive değerini güncelliyoruz
        UPDATE [XBankDB].[dnc].[UserBankCards]
        SET IsActive = 0
        WHERE CardID = @CardID

        -- Başarılı işlem logu
        INSERT INTO dnc.BankLog(LogDescription) VALUES ('Kullanıcı Banka Kartı Silme İşlemi Başarılı')
        PRINT 'Kullanıcı Banka Kartı Silme İşlemleri Başarılı'
    END TRY
    BEGIN CATCH
         INSERT INTO dnc.BankLog(LogDescription) VALUES ('Kullanıcı Banka Kartı Silme İşlemi Başarısız. Hata: ' + ERROR_MESSAGE())
         PRINT '! Kullanıcı Banka Kartı Silme İşlemi Başarısız. Hata: ' + ERROR_MESSAGE()
    END CATCH
END

-- HardDeleteUserBankCard Procedure
CREATE PROCEDURE HardDeleteUserBankCard
    @CardID uniqueidentifier
AS
BEGIN
    BEGIN TRY
        DELETE FROM [XBankDB].[dnc].[UserBankCards]
        WHERE CardID = @CardID

        -- Başarılı işlem logu
        INSERT INTO dnc.BankLog(LogDescription) VALUES ('Kullanıcı Banka Kartı Kalıcı Silme İşlemi Başarılı')
        PRINT 'Kullanıcı Banka Kartı Kalıcı Silme İşlemleri Başarılı'
    END TRY
    BEGIN CATCH
        INSERT INTO dnc.BankLog(LogDescription) VALUES ('Kullanıcı Banka Kartı Silme İşlemi Başarısız. Hata: ' + ERROR_MESSAGE())
        PRINT '! Kullanıcı Banka Kartı Silme İşlemi Başarısız. Hata: ' + ERROR_MESSAGE()
    END CATCH
END





--------------------------- User Notification Stored Procedure ----------------------------


-- ListUserNotifications Procedure
CREATE PROCEDURE ListUserNotifications
    @CustomerID uniqueidentifier
AS
BEGIN
    BEGIN TRY
        SELECT NotificationID, Title, Explanation, CustomerID, CreatedDate, ModifiedDate, IsActive
        FROM [XBankDB].[dnc].[UserNotification]
        WHERE CustomerID = @CustomerID

        -- Başarılı işlem logu
        INSERT INTO dnc.BankLog(LogDescription) VALUES ('Kullanıcı Bildirimlerini Listeleme İşlemi Başarılı')
        PRINT 'Kullanıcı Bildirimlerini Listeleme İşlemleri Başarılı'
    END TRY
    BEGIN CATCH
        -- Hata durumunda yapılacak işlemler buraya yazılır
        INSERT INTO dnc.BankLog(LogDescription) VALUES ('! Kullanıcı Bildirimlerini Listelerken Hata Meydana Geldi. Hata: ' + ERROR_MESSAGE())
        PRINT '! Kullanıcı Bildirimlerini Listelerken Hata Meydana Geldi. Hata: ' + ERROR_MESSAGE()
    END CATCH
END

-- GetUserNotificationByID Procedure
CREATE PROCEDURE GetUserNotificationByID
    @NotificationID uniqueidentifier
AS
BEGIN
    BEGIN TRY
        SELECT NotificationID, Title, Explanation, CustomerID, CreatedDate, ModifiedDate, IsActive
        FROM [XBankDB].[dnc].[UserNotification]
        WHERE NotificationID = @NotificationID

        INSERT INTO dnc.BankLog(LogDescription) VALUES ('Kullanıcı Bildirim Listesindeki Bildirim İşlemi Başarılı Bir Şekilde Geldi.')
        PRINT 'Kullanıcı Bildirim Listesindeki Bildirim İşlemi Başarılı Bir Şekilde Geldi.'
    END TRY
    BEGIN CATCH
        INSERT INTO dnc.BankLog(LogDescription) VALUES ('! Kullanıcı Bildirim Listesindeki Bildirimi Getiriken Hata Meydana Geldi. Hata: ' + ERROR_MESSAGE())
        PRINT '! Kullanıcı Bildirim Listesindeki Bildirimi Getiriken Hata Meydana Geldi. Hata: ' + ERROR_MESSAGE()
    END CATCH
END

-- AddUserNotification Procedure
CREATE PROCEDURE AddUserNotification
    @Title nvarchar(1000),
    @Explanation nvarchar(max),
    @CustomerID uniqueidentifier
AS
BEGIN
    BEGIN TRY
        INSERT INTO [XBankDB].[dnc].[UserNotification] (Title, Explanation, CustomerID, CreatedDate)
        VALUES (@Title, @Explanation, @CustomerID, GETDATE())

        -- Başarılı işlem logu
        INSERT INTO dnc.BankLog(LogDescription) VALUES ('Kullanıcı Bildirim Ekleme İşlemi Başarılı')
        PRINT 'Kullanıcı Bildirim Ekleme İşlemleri Başarılı'
    END TRY
    BEGIN CATCH
        INSERT INTO dnc.BankLog(LogDescription) VALUES ('Kullanıcı Bildirim Ekleme İşlemi Başarısız. Hata: ' + ERROR_MESSAGE())
        PRINT '! Kullanıcı Bildirim Ekleme İşlemi Başarısız. Hata: ' + ERROR_MESSAGE()
    END CATCH
END

-- UpdateUserNotification Procedure
CREATE PROCEDURE UpdateUserNotification
    @NotificationID uniqueidentifier,
    @Title nvarchar(1000),
    @Explanation nvarchar(max)
AS
BEGIN
    BEGIN TRY
        UPDATE [XBankDB].[dnc].[UserNotification]
        SET Title = @Title,
            Explanation = @Explanation,
            ModifiedDate = GETDATE()
        WHERE NotificationID = @NotificationID

        -- Başarılı işlem logu
        INSERT INTO dnc.BankLog(LogDescription) VALUES ('Kullanıcı Bildirim Güncelleme İşlemi Başarılı')
        PRINT 'Kullanıcı Bildirim Güncelleme İşlemleri Başarılı'
    END TRY
    BEGIN CATCH
        INSERT INTO dnc.BankLog(LogDescription) VALUES ('Kullanıcı Bildirim Güncelleme İşlemi Başarısız. Hata: ' + ERROR_MESSAGE())
        PRINT '! Kullanıcı Bildirim Güncelleme İşlemi Başarısız. Hata: ' + ERROR_MESSAGE()
    END CATCH
END

-- SoftDeleteUserNotification Procedure
CREATE PROCEDURE SoftDeleteUserNotification
    @NotificationID uniqueidentifier
AS
BEGIN
    BEGIN TRY
        -- Burada sadece IsActive değerini güncelliyoruz
        UPDATE [XBankDB].[dnc].[UserNotification]
        SET IsActive = 0
        WHERE NotificationID = @NotificationID

        -- Başarılı işlem logu
        INSERT INTO dnc.BankLog(LogDescription) VALUES ('Kullanıcı Bildirim Silme İşlemi Başarılı')
        PRINT 'Kullanıcı Bildirim Silme İşlemleri Başarılı'
    END TRY
    BEGIN CATCH
         INSERT INTO dnc.BankLog(LogDescription) VALUES ('Kullanıcı Bildirim Silme İşlemi Başarısız. Hata: ' + ERROR_MESSAGE())
         PRINT '! Kullanıcı Bildirim Silme İşlemi Başarısız. Hata: ' + ERROR_MESSAGE()
    END CATCH
END

-- HardDeleteUserNotification Procedure
CREATE PROCEDURE HardDeleteUserNotification
    @NotificationID uniqueidentifier
AS
BEGIN
    BEGIN TRY
        DELETE FROM [XBankDB].[dnc].[UserNotification]
        WHERE NotificationID = @NotificationID

        -- Başarılı işlem logu
        INSERT INTO dnc.BankLog(LogDescription) VALUES ('Kullanıcı Bildirim Kalıcı Silme İşlemi Başarılı')
        PRINT 'Kullanıcı Bildirim Kalıcı Silme İşlemleri Başarılı'
    END TRY
    BEGIN CATCH
        INSERT INTO dnc.BankLog(LogDescription) VALUES ('Kullanıcı Bildirim Silme İşlemi Başarısız. Hata: ' + ERROR_MESSAGE())
        PRINT '! Kullanıcı Bildirim Silme İşlemi Başarısız. Hata: ' + ERROR_MESSAGE()
    END CATCH
END


/*************************************************** CRUD STORED PROCEDURE FINISH *************************************/

/******************************************** Trading by Application ***************************************************/


-- Withdraw Money Procedure
CREATE PROCEDURE SP_WithdrawMoney
    @AccountID uniqueidentifier,
    @Amount money
AS
BEGIN
    BEGIN TRY
        UPDATE [XBankDB].[dnc].[Accounts]
        SET Balance = Balance - @Amount,
            ModifiedDate = GETDATE()
        WHERE AccountID = @AccountID AND IsActive = 1 AND Balance >= @Amount;

        IF @@ROWCOUNT > 0
        BEGIN
            -- Successful withdrawal
            INSERT INTO dnc.BankLog(LogDescription) VALUES ('Withdrawal Successful');
            PRINT 'Withdrawal Successful';
        END
        ELSE
        BEGIN
            -- Insufficient balance or inactive account
            INSERT INTO dnc.BankLog(LogDescription) VALUES ('! Withdrawal Failed. Account inactive or insufficient balance.');
            PRINT '! Withdrawal Failed. Account inactive or insufficient balance.';
        END
    END TRY
    BEGIN CATCH
        -- Error handling
        INSERT INTO dnc.BankLog(LogDescription) VALUES ('! Error During Withdrawal. Error: ' + ERROR_MESSAGE());
        PRINT '! Error During Withdrawal. Error: ' + ERROR_MESSAGE();
    END CATCH
END

-- Deposit Money Procedure
CREATE PROCEDURE SP_DepositMoney
    @AccountID uniqueidentifier,
    @Amount money
AS
BEGIN
    BEGIN TRY
        UPDATE [XBankDB].[dnc].[Accounts]
        SET Balance = Balance + @Amount,
            ModifiedDate = GETDATE()
        WHERE AccountID = @AccountID AND IsActive = 1;

        IF @@ROWCOUNT > 0
        BEGIN
            -- Successful deposit
            INSERT INTO dnc.BankLog(LogDescription) VALUES ('Deposit Successful');
            PRINT 'Deposit Successful';
        END
        ELSE
        BEGIN
            -- Inactive account
            INSERT INTO dnc.BankLog(LogDescription) VALUES ('! Deposit Failed. Account inactive.');
            PRINT '! Deposit Failed. Account inactive.';
        END
    END TRY
    BEGIN CATCH
        -- Error handling
        INSERT INTO dnc.BankLog(LogDescription) VALUES ('! Error During Deposit. Error: ' + ERROR_MESSAGE());
        PRINT '! Error During Deposit. Error: ' + ERROR_MESSAGE();
    END CATCH
END

-- Transfer Money Procedure
CREATE PROCEDURE SP_TransferMoney
    @SenderAccountID uniqueidentifier,
    @RecipientAccountID uniqueidentifier,
    @Amount money
AS
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION;

        -- Withdraw from sender account
        EXEC SP_WithdrawMoney @AccountID = @SenderAccountID, @Amount = @Amount;

        IF @@ROWCOUNT > 0
        BEGIN
            -- Deposit to recipient account
            EXEC SP_DepositMoney @AccountID = @RecipientAccountID, @Amount = @Amount;

            -- Commit the transaction if both withdrawal and deposit are successful
            COMMIT;
            INSERT INTO dnc.BankLog(LogDescription) VALUES ('Transfer Successful');
            PRINT 'Transfer Successful';
        END
        ELSE
        BEGIN
            -- Rollback the transaction if the withdrawal is unsuccessful
            ROLLBACK;
            INSERT INTO dnc.BankLog(LogDescription) VALUES ('! Transfer Failed. Insufficient balance or inactive sender account.');
            PRINT '! Transfer Failed. Insufficient balance or inactive sender account.';
        END
    END TRY
    BEGIN CATCH
        -- Rollback the transaction in case of an error
        ROLLBACK;
        INSERT INTO dnc.BankLog(LogDescription) VALUES ('! Error During Transfer. Error: ' + ERROR_MESSAGE());
        PRINT '! Error During Transfer. Error: ' + ERROR_MESSAGE();
    END CATCH
END

-- Pay Bill Procedure
CREATE PROCEDURE SP_PayBill
    @AccountID uniqueidentifier,
    @BillID uniqueidentifier
AS
BEGIN
    BEGIN TRY
        DECLARE @BillAmount money;

        -- Get the bill amount
        SELECT @BillAmount = Amount
        FROM [XBankDB].[dnc].[Bills]
        WHERE ID = @BillID AND IsActive = 1;

        IF @BillAmount IS NOT NULL
        BEGIN
            BEGIN TRANSACTION;

            -- Withdraw money equal to the bill amount
            EXEC SP_WithdrawMoney @AccountID = @AccountID, @Amount = @BillAmount;

            IF @@ROWCOUNT > 0
            BEGIN
                -- Mark the bill as paid
                UPDATE [XBankDB].[dnc].[Bills]
                SET PaymentStatus = 1,  -- Mark as paid
                    ModifiedDate = GETDATE()
                WHERE ID = @BillID;

                -- Commit the transaction if both withdrawal and bill update are successful
                COMMIT;
                INSERT INTO dnc.BankLog(LogDescription) VALUES ('Bill Payment Successful');
                PRINT 'Bill Payment Successful';
            END
            ELSE
            BEGIN
                -- Rollback the transaction if the withdrawal is unsuccessful
                ROLLBACK;
                INSERT INTO dnc.BankLog(LogDescription) VALUES ('! Bill Payment Failed. Insufficient balance or inactive account.');
                PRINT '! Bill Payment Failed. Insufficient balance or inactive account.';
            END
        END
        ELSE
        BEGIN
            -- Bill not found or inactive
            INSERT INTO dnc.BankLog(LogDescription) VALUES ('! Bill Payment Failed. Bill not found or inactive.');
            PRINT '! Bill Payment Failed. Bill not found or inactive.';
        END
    END TRY
    BEGIN CATCH
        -- Rollback the transaction in case of an error
        ROLLBACK;
        INSERT INTO dnc.BankLog(LogDescription) VALUES ('! Error During Bill Payment. Error: ' + ERROR_MESSAGE());
        PRINT '! Error During Bill Payment. Error: ' + ERROR_MESSAGE();
    END CATCH
END
