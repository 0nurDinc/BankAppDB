USE [XBankDB]
GO

CREATE SCHEMA [dnc]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Accounts](
	[AccountID] [uniqueidentifier] NOT NULL,
	[AccountsTypeID] [smallint] NOT NULL,
	[CustomerID] [uniqueidentifier] NOT NULL,
	[IsCorporate] [bit] NOT NULL,
	[IBAN] [nvarchar](26) NOT NULL,
	[Balance] [money] NOT NULL,
	[CreatedDate] [datetime] NOT NULL,
	[ModifiedDate] [datetime] NULL,
	[IsActive] [bit] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[AccountID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [AccountsTypes](
	[ID] [smallint] IDENTITY(1,1) NOT NULL,
	[AccountTitle] [nvarchar](400) NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [AccountTransaction](
	[TransactionID] [uniqueidentifier] NOT NULL,
	[SenderAccount] [nvarchar](26) NOT NULL,
	[RecipientAccount] [nvarchar](26) NULL,
	[OperationTypeID] [smallint] NOT NULL,
	[Amount] [money] NOT NULL,
	[OperationTime] [datetime] NOT NULL,
	[CreatedDate] [datetime] NOT NULL,
	[ModifiedDate] [datetime] NULL,
	[IsActive] [bit] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[TransactionID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Balances](
	[ID] [uniqueidentifier] NOT NULL,
	[IBAN] [nvarchar](26) NOT NULL,
	[Amount] [money] NOT NULL,
	[BalancesTime] [datetime] NOT NULL,
	[CreatedDate] [datetime] NOT NULL,
	[ModifiedDate] [datetime] NULL,
	[IsActive] [bit] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [BankCustomer](
	[CustomerID] [uniqueidentifier] NOT NULL,
	[CredentialNo] [nvarchar](11) NOT NULL,
	[FirstName] [nvarchar](50) NOT NULL,
	[LastName] [nvarchar](50) NOT NULL,
	[BirthOfDate] [date] NOT NULL,
	[CreatedDate] [datetime] NOT NULL,
	[ModifiedDate] [datetime] NULL,
	[IsActive] [bit] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[CustomerID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [BankCustomerContactInformation](
	[ContactID] [uniqueidentifier] NOT NULL,
	[CustomerID] [uniqueidentifier] NOT NULL,
	[ContactTypeID] [smallint] NOT NULL,
	[ContactInforamation] [nvarchar](120) NOT NULL,
	[CreatedDate] [datetime] NOT NULL,
	[ModifiedDate] [datetime] NULL,
	[IsActive] [bit] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[ContactID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [BankCustomerLogin](
	[LoginID] [uniqueidentifier] NOT NULL,
	[CustomerID] [uniqueidentifier] NOT NULL,
	[UserPassword] [varbinary](max) NOT NULL,
	[PasswordSalt] [varbinary](max) NOT NULL,
	[CreatedDate] [datetime] NOT NULL,
	[ModifiedDate] [datetime] NULL,
	[IsActive] [bit] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[LoginID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [BankLog](
	[LogID] [uniqueidentifier] NOT NULL,
	[EventDate] [datetime] NOT NULL,
	[LogDescription] [nvarchar](max) NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[LogID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Bills](
	[ID] [uniqueidentifier] NOT NULL,
	[InstituteID] [int] NOT NULL,
	[AccountID] [uniqueidentifier] NOT NULL,
	[Amount] [money] NOT NULL,
	[PaymentStatus] [bit] NOT NULL,
	[PreviousBillID] [uniqueidentifier] NULL,
	[CreatedDate] [datetime] NOT NULL,
	[ModifiedDate] [datetime] NULL,
	[IsActive] [bit] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Currency](
	[CurrencyID] [int] IDENTITY(1,1) NOT NULL,
	[Unit] [smallint] NOT NULL,
	[Title] [nvarchar](100) NOT NULL,
	[CurrencyCode] [nvarchar](5) NOT NULL,
	[ForexBuying] [money] NOT NULL,
	[ForexSelling] [money] NOT NULL,
	[CreatedDate] [datetime] NOT NULL,
	[ModifiedDate] [datetime] NULL,
	[IsActive] [bit] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[CurrencyID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [CustomerContactType](
	[ID] [smallint] IDENTITY(1,1) NOT NULL,
	[ContactTitle] [nvarchar](30) NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Departments](
	[DepartmentID] [int] IDENTITY(1,1) NOT NULL,
	[Title] [nvarchar](50) NOT NULL,
	[CreatedDate] [datetime] NOT NULL,
	[ModifiedDate] [datetime] NOT NULL,
	[IsActive] [bit] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[DepartmentID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [EmployeeAuthorization](
	[AuthorizationID] [uniqueidentifier] NOT NULL,
	[RoleID] [int] NOT NULL,
	[ObjectName] [nvarchar](50) NOT NULL,
	[ObjectType] [nvarchar](50) NOT NULL,
	[PermissionType] [nvarchar](50) NOT NULL,
	[CreatedDate] [datetime] NOT NULL,
	[ModifiedDate] [datetime] NULL,
	[IsActive] [bit] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[AuthorizationID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [EmployeeRoles](
	[RoleID] [int] IDENTITY(1,1) NOT NULL,
	[Title] [nvarchar](30) NOT NULL,
	[CreatedDate] [datetime] NOT NULL,
	[ModifiedDate] [datetime] NULL,
	[IsActive] [bit] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[RoleID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Employees](
	[EmployeeID] [uniqueidentifier] NOT NULL,
	[FirstName] [nvarchar](50) NOT NULL,
	[LastName] [nvarchar](50) NOT NULL,
	[RoleID] [int] NOT NULL,
	[DepartmentID] [int] NOT NULL,
	[CreatedDate] [datetime] NOT NULL,
	[ModifiedDate] [datetime] NULL,
	[IsActive] [bit] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[EmployeeID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [EmployeesLogin](
	[LoginID] [uniqueidentifier] NOT NULL,
	[EmployeeID] [uniqueidentifier] NOT NULL,
	[UserPassword] [varbinary](max) NOT NULL,
	[PasswordSalt] [varbinary](max) NOT NULL,
	[CreatedDate] [datetime] NOT NULL,
	[ModifiedDate] [datetime] NULL,
	[IsActive] [bit] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[LoginID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Institute](
	[InstituteID] [int] IDENTITY(1,1) NOT NULL,
	[InstituteTitle] [nvarchar](250) NOT NULL,
	[CreatedDate] [datetime] NOT NULL,
	[ModifiedDate] [datetime] NULL,
	[IsActive] [bit] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[InstituteID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [OpearationType](
	[ID] [smallint] IDENTITY(1,1) NOT NULL,
	[OperationTitle] [nvarchar](300) NULL,
PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [UserBankCards](
	[CardID] [uniqueidentifier] NOT NULL,
	[CardNo] [nvarchar](16) NOT NULL,
	[ExpirationDate] [date] NOT NULL,
	[CvcCode] [smallint] NOT NULL,
	[AccountID] [uniqueidentifier] NOT NULL,
	[CreatedDate] [datetime] NOT NULL,
	[ModifiedDate] [datetime] NULL,
	[IsActive] [bit] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[CardID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [UserNotification](
	[NotificationID] [uniqueidentifier] NOT NULL,
	[Title] [nvarchar](1000) NOT NULL,
	[Explanation] [nvarchar](max) NOT NULL,
	[CustomerID] [uniqueidentifier] NOT NULL,
	[CreatedDate] [datetime] NOT NULL,
	[ModifiedDate] [datetime] NULL,
	[IsActive] [bit] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[NotificationID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET IDENTITY_INSERT [Currency] ON 

INSERT [Currency] ([CurrencyID], [Unit], [Title], [CurrencyCode], [ForexBuying], [ForexSelling], [CreatedDate], [ModifiedDate], [IsActive]) VALUES (1, 1, N'ABD DOLARI', N'USD', 30.3735, 30.4282, CAST(N'2024-02-04T17:52:29.950' AS DateTime), NULL, 1)
INSERT [Currency] ([CurrencyID], [Unit], [Title], [CurrencyCode], [ForexBuying], [ForexSelling], [CreatedDate], [ModifiedDate], [IsActive]) VALUES (2, 1, N'AVUSTRALYA DOLARI', N'AUD', 19.9945, 20.1249, CAST(N'2024-02-04T17:52:29.950' AS DateTime), NULL, 1)
INSERT [Currency] ([CurrencyID], [Unit], [Title], [CurrencyCode], [ForexBuying], [ForexSelling], [CreatedDate], [ModifiedDate], [IsActive]) VALUES (3, 1, N'DANİMARKA KRONU', N'DKK', 4.4274, 4.4492, CAST(N'2024-02-04T17:52:29.950' AS DateTime), NULL, 1)
INSERT [Currency] ([CurrencyID], [Unit], [Title], [CurrencyCode], [ForexBuying], [ForexSelling], [CreatedDate], [ModifiedDate], [IsActive]) VALUES (4, 1, N'EURO', N'EUR', 33.0537, 33.1132, CAST(N'2024-02-04T17:52:29.950' AS DateTime), NULL, 1)
INSERT [Currency] ([CurrencyID], [Unit], [Title], [CurrencyCode], [ForexBuying], [ForexSelling], [CreatedDate], [ModifiedDate], [IsActive]) VALUES (5, 1, N'İNGİLİZ STERLİNİ', N'GBP', 38.6719, 38.8735, CAST(N'2024-02-04T17:52:29.950' AS DateTime), NULL, 1)
INSERT [Currency] ([CurrencyID], [Unit], [Title], [CurrencyCode], [ForexBuying], [ForexSelling], [CreatedDate], [ModifiedDate], [IsActive]) VALUES (6, 1, N'İSVİÇRE FRANGI', N'CHF', 35.3738, 35.6009, CAST(N'2024-02-04T17:52:29.950' AS DateTime), NULL, 1)
INSERT [Currency] ([CurrencyID], [Unit], [Title], [CurrencyCode], [ForexBuying], [ForexSelling], [CreatedDate], [ModifiedDate], [IsActive]) VALUES (7, 1, N'İSVEÇ KRONU', N'SEK', 2.9163, 2.9465, CAST(N'2024-02-04T17:52:29.950' AS DateTime), NULL, 1)
INSERT [Currency] ([CurrencyID], [Unit], [Title], [CurrencyCode], [ForexBuying], [ForexSelling], [CreatedDate], [ModifiedDate], [IsActive]) VALUES (8, 1, N'KANADA DOLARI', N'CAD', 22.6762, 22.7785, CAST(N'2024-02-04T17:52:29.950' AS DateTime), NULL, 1)
INSERT [Currency] ([CurrencyID], [Unit], [Title], [CurrencyCode], [ForexBuying], [ForexSelling], [CreatedDate], [ModifiedDate], [IsActive]) VALUES (9, 1, N'KUVEYT DİNARI', N'KWD', 98.2810, 99.5671, CAST(N'2024-02-04T17:52:29.950' AS DateTime), NULL, 1)
INSERT [Currency] ([CurrencyID], [Unit], [Title], [CurrencyCode], [ForexBuying], [ForexSelling], [CreatedDate], [ModifiedDate], [IsActive]) VALUES (10, 1, N'NORVEÇ KRONU', N'NOK', 2.8997, 2.9192, CAST(N'2024-02-04T17:52:29.950' AS DateTime), NULL, 1)
INSERT [Currency] ([CurrencyID], [Unit], [Title], [CurrencyCode], [ForexBuying], [ForexSelling], [CreatedDate], [ModifiedDate], [IsActive]) VALUES (11, 1, N'SUUDİ ARABİSTAN RİYALİ', N'SAR', 8.0995, 8.1141, CAST(N'2024-02-04T17:52:29.950' AS DateTime), NULL, 1)
INSERT [Currency] ([CurrencyID], [Unit], [Title], [CurrencyCode], [ForexBuying], [ForexSelling], [CreatedDate], [ModifiedDate], [IsActive]) VALUES (12, 100, N'JAPON YENİ', N'JPY', 20.6667, 20.8036, CAST(N'2024-02-04T17:52:29.950' AS DateTime), NULL, 1)
INSERT [Currency] ([CurrencyID], [Unit], [Title], [CurrencyCode], [ForexBuying], [ForexSelling], [CreatedDate], [ModifiedDate], [IsActive]) VALUES (13, 1, N'BULGAR LEVASI', N'BGN', 16.8046, 17.0245, CAST(N'2024-02-04T17:52:29.950' AS DateTime), NULL, 1)
INSERT [Currency] ([CurrencyID], [Unit], [Title], [CurrencyCode], [ForexBuying], [ForexSelling], [CreatedDate], [ModifiedDate], [IsActive]) VALUES (14, 1, N'RUMEN LEYİ', N'RON', 6.6099, 6.6963, CAST(N'2024-02-04T17:52:29.950' AS DateTime), NULL, 1)
INSERT [Currency] ([CurrencyID], [Unit], [Title], [CurrencyCode], [ForexBuying], [ForexSelling], [CreatedDate], [ModifiedDate], [IsActive]) VALUES (15, 1, N'RUS RUBLESİ', N'RUB', 0.3333, 0.3376, CAST(N'2024-02-04T17:52:29.950' AS DateTime), NULL, 1)
INSERT [Currency] ([CurrencyID], [Unit], [Title], [CurrencyCode], [ForexBuying], [ForexSelling], [CreatedDate], [ModifiedDate], [IsActive]) VALUES (16, 100, N'İRAN RİYALİ', N'IRR', 0.0719, 0.0728, CAST(N'2024-02-04T17:52:29.950' AS DateTime), NULL, 1)
INSERT [Currency] ([CurrencyID], [Unit], [Title], [CurrencyCode], [ForexBuying], [ForexSelling], [CreatedDate], [ModifiedDate], [IsActive]) VALUES (17, 1, N'ÇİN YUANI', N'CNY', 4.2073, 4.2624, CAST(N'2024-02-04T17:52:29.950' AS DateTime), NULL, 1)
INSERT [Currency] ([CurrencyID], [Unit], [Title], [CurrencyCode], [ForexBuying], [ForexSelling], [CreatedDate], [ModifiedDate], [IsActive]) VALUES (18, 1, N'PAKİSTAN RUPİSİ', N'PKR', 0.1088, 0.1102, CAST(N'2024-02-04T17:52:29.950' AS DateTime), NULL, 1)
INSERT [Currency] ([CurrencyID], [Unit], [Title], [CurrencyCode], [ForexBuying], [ForexSelling], [CreatedDate], [ModifiedDate], [IsActive]) VALUES (19, 1, N'KATAR RİYALİ', N'QAR', 8.2851, 8.3935, CAST(N'2024-02-04T17:52:29.950' AS DateTime), NULL, 1)
INSERT [Currency] ([CurrencyID], [Unit], [Title], [CurrencyCode], [ForexBuying], [ForexSelling], [CreatedDate], [ModifiedDate], [IsActive]) VALUES (20, 1, N'GÜNEY KORE WONU', N'KRW', 0.0228, 0.0231, CAST(N'2024-02-04T17:52:29.950' AS DateTime), NULL, 1)
INSERT [Currency] ([CurrencyID], [Unit], [Title], [CurrencyCode], [ForexBuying], [ForexSelling], [CreatedDate], [ModifiedDate], [IsActive]) VALUES (21, 1, N'AZERBAYCAN YENİ MANATI', N'AZN', 17.7666, 17.9991, CAST(N'2024-02-04T17:52:29.950' AS DateTime), NULL, 1)
INSERT [Currency] ([CurrencyID], [Unit], [Title], [CurrencyCode], [ForexBuying], [ForexSelling], [CreatedDate], [ModifiedDate], [IsActive]) VALUES (22, 1, N'BİRLEŞİK ARAP EMİRLİKLERİ DİRHEMİ', N'AED', 8.2230, 8.3306, CAST(N'2024-02-04T17:52:29.950' AS DateTime), NULL, 1)
INSERT [Currency] ([CurrencyID], [Unit], [Title], [CurrencyCode], [ForexBuying], [ForexSelling], [CreatedDate], [ModifiedDate], [IsActive]) VALUES (23, 1, N'ÖZEL ÇEKME HAKKI (SDR)                            ', N'XDR', 40.5221, 0.0000, CAST(N'2024-02-04T17:52:29.950' AS DateTime), NULL, 1)
SET IDENTITY_INSERT [Currency] OFF
GO
CREATE NONCLUSTERED INDEX [idx_Accounts_IsActive] ON [Accounts]
(
	[IsActive] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [idx_Bills_CustomerPaymentStatus] ON [Bills]
(
	[AccountID] ASC,
	[PaymentStatus] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
CREATE NONCLUSTERED INDEX [idx_Currency_CurrencyCode] ON [Currency]
(
	[CurrencyCode] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
ALTER TABLE [Accounts] ADD  CONSTRAINT [DF_Accounts_AccountID]  DEFAULT (newid()) FOR [AccountID]
GO
ALTER TABLE [Accounts] ADD  CONSTRAINT [DF_Accounts_IsCoporate]  DEFAULT ((0)) FOR [IsCorporate]
GO
ALTER TABLE [Accounts] ADD  CONSTRAINT [DF_Accounts_CreatedDate]  DEFAULT (getdate()) FOR [CreatedDate]
GO
ALTER TABLE [Accounts] ADD  CONSTRAINT [DF_Accounts_IsActive]  DEFAULT ((1)) FOR [IsActive]
GO
ALTER TABLE [AccountTransaction] ADD  CONSTRAINT [DF_AccountTransaction_TransactionID]  DEFAULT (newid()) FOR [TransactionID]
GO
ALTER TABLE [AccountTransaction] ADD  CONSTRAINT [DF_AccountTransaction_OperationTime]  DEFAULT (getdate()) FOR [OperationTime]
GO
ALTER TABLE [AccountTransaction] ADD  CONSTRAINT [DF_AccountTransaction_CreatedDate]  DEFAULT (getdate()) FOR [CreatedDate]
GO
ALTER TABLE [AccountTransaction] ADD  CONSTRAINT [DF_AccountTransaction_IsActive]  DEFAULT ((1)) FOR [IsActive]
GO
ALTER TABLE [Balances] ADD  CONSTRAINT [DF_Balances_ID]  DEFAULT (newid()) FOR [ID]
GO
ALTER TABLE [Balances] ADD  CONSTRAINT [DF_Balances_CretedDate]  DEFAULT (getdate()) FOR [CreatedDate]
GO
ALTER TABLE [Balances] ADD  CONSTRAINT [DF_Balances_IsActive]  DEFAULT ((1)) FOR [IsActive]
GO
ALTER TABLE [BankCustomer] ADD  CONSTRAINT [DF_BankCustomer_CustomerID]  DEFAULT (newid()) FOR [CustomerID]
GO
ALTER TABLE [BankCustomer] ADD  CONSTRAINT [DF_BankCustomer_CreatedDate]  DEFAULT (getdate()) FOR [CreatedDate]
GO
ALTER TABLE [BankCustomer] ADD  CONSTRAINT [DF_BankCusotmer_IsActive]  DEFAULT ((1)) FOR [IsActive]
GO
ALTER TABLE [BankCustomerContactInformation] ADD  CONSTRAINT [DF_BankCustomerContactInformation_ContactID]  DEFAULT (newid()) FOR [ContactID]
GO
ALTER TABLE [BankCustomerContactInformation] ADD  CONSTRAINT [DF_BankCustomerContactInformation_CreatedDate]  DEFAULT (getdate()) FOR [CreatedDate]
GO
ALTER TABLE [BankCustomerContactInformation] ADD  CONSTRAINT [DF_BankCustomerContactInformation_IsActive]  DEFAULT ((1)) FOR [IsActive]
GO
ALTER TABLE [BankCustomerLogin] ADD  CONSTRAINT [DF_BankCustomerLogin_LoginID]  DEFAULT (newid()) FOR [LoginID]
GO
ALTER TABLE [BankCustomerLogin] ADD  CONSTRAINT [DF_BankCustomerLogin_CreatedDate]  DEFAULT (getdate()) FOR [CreatedDate]
GO
ALTER TABLE [BankCustomerLogin] ADD  CONSTRAINT [DF_BankCustomerLogin_IsActive]  DEFAULT ((1)) FOR [IsActive]
GO
ALTER TABLE [BankLog] ADD  CONSTRAINT [DF_BankLog_LogID]  DEFAULT (newid()) FOR [LogID]
GO
ALTER TABLE [BankLog] ADD  CONSTRAINT [DF_BankLog_EventDate]  DEFAULT (getdate()) FOR [EventDate]
GO
ALTER TABLE [Bills] ADD  CONSTRAINT [DF_Bills_ID]  DEFAULT (newid()) FOR [ID]
GO
ALTER TABLE [Bills] ADD  CONSTRAINT [DF_Bills_PaymentStatus]  DEFAULT ((0)) FOR [PaymentStatus]
GO
ALTER TABLE [Bills] ADD  CONSTRAINT [DF_Bills_CretedDate]  DEFAULT (getdate()) FOR [CreatedDate]
GO
ALTER TABLE [Bills] ADD  CONSTRAINT [DF_Bills_IsActive]  DEFAULT ((1)) FOR [IsActive]
GO
ALTER TABLE [Currency] ADD  CONSTRAINT [DF_Currency_CreatedDate]  DEFAULT (getdate()) FOR [CreatedDate]
GO
ALTER TABLE [Currency] ADD  CONSTRAINT [DF_Currency_IsActive]  DEFAULT ((1)) FOR [IsActive]
GO
ALTER TABLE [Departments] ADD  CONSTRAINT [DF_Departments_CreatedDate]  DEFAULT (getdate()) FOR [CreatedDate]
GO
ALTER TABLE [Departments] ADD  CONSTRAINT [DF_Departments_IsActive]  DEFAULT ((1)) FOR [IsActive]
GO
ALTER TABLE [EmployeeAuthorization] ADD  CONSTRAINT [DF_EmployeeAuthorization_AuthorizationID]  DEFAULT (newid()) FOR [AuthorizationID]
GO
ALTER TABLE [EmployeeAuthorization] ADD  CONSTRAINT [DF_EmployeeAuthorization_CreatedDate]  DEFAULT (getdate()) FOR [CreatedDate]
GO
ALTER TABLE [EmployeeAuthorization] ADD  CONSTRAINT [DF_EmployeeAuthorization_IsActive]  DEFAULT ((1)) FOR [IsActive]
GO
ALTER TABLE [EmployeeRoles] ADD  CONSTRAINT [DF_EmployeeRoles_CreatedDate]  DEFAULT (getdate()) FOR [CreatedDate]
GO
ALTER TABLE [EmployeeRoles] ADD  CONSTRAINT [DF_EmployeeRoles_IsActive]  DEFAULT ((1)) FOR [IsActive]
GO
ALTER TABLE [Employees] ADD  CONSTRAINT [DF_Employees_EmployeeID]  DEFAULT (newid()) FOR [EmployeeID]
GO
ALTER TABLE [Employees] ADD  CONSTRAINT [DF_Employees_CreatedDate]  DEFAULT (getdate()) FOR [CreatedDate]
GO
ALTER TABLE [Employees] ADD  CONSTRAINT [DF_Employees_IsActive]  DEFAULT ((1)) FOR [IsActive]
GO
ALTER TABLE [EmployeesLogin] ADD  CONSTRAINT [DF_EmployeesLogin_CreatedDate]  DEFAULT (getdate()) FOR [CreatedDate]
GO
ALTER TABLE [EmployeesLogin] ADD  CONSTRAINT [DF_EmployeesLogin_IsActive]  DEFAULT ((1)) FOR [IsActive]
GO
ALTER TABLE [Institute] ADD  CONSTRAINT [DF_Institute_CreatedDate]  DEFAULT (getdate()) FOR [CreatedDate]
GO
ALTER TABLE [Institute] ADD  CONSTRAINT [DF_Institute_IsActive]  DEFAULT ((1)) FOR [IsActive]
GO
ALTER TABLE [UserBankCards] ADD  CONSTRAINT [DF_UserBankCards_CardID]  DEFAULT (newid()) FOR [CardID]
GO
ALTER TABLE [UserBankCards] ADD  CONSTRAINT [DF_UserBankCards_CreatedDate]  DEFAULT (getdate()) FOR [CreatedDate]
GO
ALTER TABLE [UserBankCards] ADD  CONSTRAINT [DF_UserBankCards_IsActive]  DEFAULT ((1)) FOR [IsActive]
GO
ALTER TABLE [UserNotification] ADD  CONSTRAINT [DF_UserNotification_NotificationID]  DEFAULT (newid()) FOR [NotificationID]
GO
ALTER TABLE [UserNotification] ADD  CONSTRAINT [DF_UserNotification_CreatedDate]  DEFAULT (getdate()) FOR [CreatedDate]
GO
ALTER TABLE [UserNotification] ADD  CONSTRAINT [DF_UserNotification_IsActive]  DEFAULT ((1)) FOR [IsActive]
GO
ALTER TABLE [Accounts]  WITH CHECK ADD  CONSTRAINT [FK_Accounts_AccountsTypes_AccountsTypeID] FOREIGN KEY([AccountsTypeID])
REFERENCES [AccountsTypes] ([ID])
GO
ALTER TABLE [Accounts] CHECK CONSTRAINT [FK_Accounts_AccountsTypes_AccountsTypeID]
GO
ALTER TABLE [Accounts]  WITH CHECK ADD  CONSTRAINT [FK_Accounts_BankCustomer_CustomerID] FOREIGN KEY([CustomerID])
REFERENCES [BankCustomer] ([CustomerID])
GO
ALTER TABLE [Accounts] CHECK CONSTRAINT [FK_Accounts_BankCustomer_CustomerID]
GO
ALTER TABLE [AccountTransaction]  WITH CHECK ADD  CONSTRAINT [FK_AccountTransaction_OpearationType_OperationTypeID] FOREIGN KEY([OperationTypeID])
REFERENCES [OpearationType] ([ID])
GO
ALTER TABLE [AccountTransaction] CHECK CONSTRAINT [FK_AccountTransaction_OpearationType_OperationTypeID]
GO
ALTER TABLE [BankCustomerContactInformation]  WITH CHECK ADD  CONSTRAINT [FK_BankCustomerContactInformation_BankCustomer_CustomerID] FOREIGN KEY([CustomerID])
REFERENCES [BankCustomer] ([CustomerID])
GO
ALTER TABLE [BankCustomerContactInformation] CHECK CONSTRAINT [FK_BankCustomerContactInformation_BankCustomer_CustomerID]
GO
ALTER TABLE [BankCustomerContactInformation]  WITH CHECK ADD  CONSTRAINT [FK_BankCustomerContactInformation_CustomerContactType_ContactTypeID] FOREIGN KEY([ContactTypeID])
REFERENCES [CustomerContactType] ([ID])
GO
ALTER TABLE [BankCustomerContactInformation] CHECK CONSTRAINT [FK_BankCustomerContactInformation_CustomerContactType_ContactTypeID]
GO
ALTER TABLE [BankCustomerLogin]  WITH CHECK ADD  CONSTRAINT [FK_BankCustomerLogin_BankCustomer_CustomerID] FOREIGN KEY([CustomerID])
REFERENCES [BankCustomer] ([CustomerID])
GO
ALTER TABLE [BankCustomerLogin] CHECK CONSTRAINT [FK_BankCustomerLogin_BankCustomer_CustomerID]
GO
ALTER TABLE [Bills]  WITH CHECK ADD  CONSTRAINT [FK_Bills_Accounts_AccountID] FOREIGN KEY([AccountID])
REFERENCES [Accounts] ([AccountID])
GO
ALTER TABLE [Bills] CHECK CONSTRAINT [FK_Bills_Accounts_AccountID]
GO
ALTER TABLE [Bills]  WITH CHECK ADD  CONSTRAINT [FK_Bills_Institute_InstituteID] FOREIGN KEY([InstituteID])
REFERENCES [Institute] ([InstituteID])
GO
ALTER TABLE [Bills] CHECK CONSTRAINT [FK_Bills_Institute_InstituteID]
GO
ALTER TABLE [EmployeeAuthorization]  WITH CHECK ADD  CONSTRAINT [FK_EmployeeAuthorization_EmployeeRoles_RoleID] FOREIGN KEY([RoleID])
REFERENCES [EmployeeRoles] ([RoleID])
GO
ALTER TABLE [EmployeeAuthorization] CHECK CONSTRAINT [FK_EmployeeAuthorization_EmployeeRoles_RoleID]
GO
ALTER TABLE [Employees]  WITH CHECK ADD  CONSTRAINT [FK_Employees_Departments_DepartmentID] FOREIGN KEY([DepartmentID])
REFERENCES [Departments] ([DepartmentID])
GO
ALTER TABLE [Employees] CHECK CONSTRAINT [FK_Employees_Departments_DepartmentID]
GO
ALTER TABLE [Employees]  WITH CHECK ADD  CONSTRAINT [FK_Employees_EmployeeRoles_RoleID] FOREIGN KEY([RoleID])
REFERENCES [EmployeeRoles] ([RoleID])
GO
ALTER TABLE [Employees] CHECK CONSTRAINT [FK_Employees_EmployeeRoles_RoleID]
GO
ALTER TABLE [EmployeesLogin]  WITH CHECK ADD  CONSTRAINT [FK_EmployeesLogin_Employees_LoginID] FOREIGN KEY([LoginID])
REFERENCES [Employees] ([EmployeeID])
GO
ALTER TABLE [EmployeesLogin] CHECK CONSTRAINT [FK_EmployeesLogin_Employees_LoginID]
GO
ALTER TABLE [UserBankCards]  WITH CHECK ADD  CONSTRAINT [FK_UserBankCards_Accounts_AccountID] FOREIGN KEY([AccountID])
REFERENCES [Accounts] ([AccountID])
GO
ALTER TABLE [UserBankCards] CHECK CONSTRAINT [FK_UserBankCards_Accounts_AccountID]
GO
ALTER TABLE [UserNotification]  WITH CHECK ADD  CONSTRAINT [FK_UserNotification_BankCustomer_CustomerID] FOREIGN KEY([CustomerID])
REFERENCES [BankCustomer] ([CustomerID])
GO
ALTER TABLE [UserNotification] CHECK CONSTRAINT [FK_UserNotification_BankCustomer_CustomerID]
GO
