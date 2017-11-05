CREATE TABLE dbo.Make
(
	MakeId INT PRIMARY KEY,
	MakeName nvarchar(max),
	CountryOfOrigin nvarchar(2)
)

CREATE TABLE dbo.Model
(
	ModelId INT PRIMARY KEY IDENTITY(1,1),
	MakeId INT NOT NULL,
	ModelName nvarchar(max),
	EngineCapacityCc int,
	IsManufactured bit
)

GO

INSERT INTO dbo.Make
	(MakeId, MakeName, CountryOfOrigin)
VALUES
	(1, N'Audi', N'DE'),
	(2, N'Bentley', N'UK'),
	(3, N'Renault', N'FR'),
	(4, N'Volvo', N'SE')

INSERT INTO dbo.Model
	(MakeId, ModelName, EngineCapacityCc, IsManufactured)
VALUES
	(1, 'A2', 1400, 0),
	(1, 'A3', 1600, 1),
	(1, 'A4', 2000, 1),
	(1, 'S8', 4000, 1),
	(2, 'Bentayga', 6000, 1),
	(2, 'Continental GT', 6000, 1),
	(3, '19', 1600, 0),
	(3, 'Clio', 1200, 1),
	(3, 'S60', 2000, 1),
	(3, 'XC90', 2400, 1)

GO

CREATE PROCEDURE dbo.GetAllMakesAndModels
AS

	SELECT * FROM dbo.Make m

	SELECT * FROM dbo.Model m

GO


CREATE TYPE dbo.AddModelsTvp AS TABLE
(
	ModelName nvarchar(max) NULL,
	EngineCapacityCc int NULL,
	IsManufactured bit NULL
)
GO

CREATE PROCEDURE dbo.AddModels
	@makeId INT,
	@models AddModelsTvp READONLY
AS

	INSERT INTO dbo.Model
	(
	    MakeId,
	    ModelName,
	    EngineCapacityCc,
	    IsManufactured
	)
	SELECT
		@makeId,
		m.ModelName,
		m.EngineCapacityCc,
	    m.IsManufactured
	FROM @models m

GO
SELECT * FROM dbo.Model