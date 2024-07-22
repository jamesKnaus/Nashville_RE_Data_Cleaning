USE NashvilleHousing;
GO

-- Create the main table
CREATE TABLE NashvilleHousingData (
    UniqueID INT,
    ParcelID NVARCHAR(50),
    LandUse NVARCHAR(50),
    PropertyAddress NVARCHAR(255),
    SaleDate NVARCHAR(50),
    SalePrice INT,
    LegalReference NVARCHAR(50),
    SoldAsVacant NVARCHAR(5),
    OwnerName NVARCHAR(100),
    OwnerAddress NVARCHAR(255),
    Acreage FLOAT,
    TaxDistrict NVARCHAR(100),
    LandValue INT,
    BuildingValue INT,
    TotalValue INT,
    YearBuilt INT,
    Bedrooms INT,
    FullBath INT,
    HalfBath INT
);
GO

-- Create the staging table
CREATE TABLE NashvilleHousingStaging (
    UniqueID NVARCHAR(50),
    ParcelID NVARCHAR(50),
    LandUse NVARCHAR(50),
    PropertyAddress NVARCHAR(255),
    SaleDate NVARCHAR(50),
    SalePrice NVARCHAR(50),
    LegalReference NVARCHAR(50),
    SoldAsVacant NVARCHAR(5),
    OwnerName NVARCHAR(100),
    OwnerAddress NVARCHAR(255),
    Acreage NVARCHAR(50),
    TaxDistrict NVARCHAR(100),
    LandValue NVARCHAR(50),
    BuildingValue NVARCHAR(50),
    TotalValue NVARCHAR(50),
    YearBuilt NVARCHAR(50),
    Bedrooms NVARCHAR(10),
    FullBath NVARCHAR(10),
    HalfBath NVARCHAR(10)
);
GO

-- Bulk insert data into staging table
BULK INSERT NashvilleHousingStaging
FROM '/var/opt/mssql/data/NashvilleHousingData.csv'
WITH (
    FORMAT = 'CSV',
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n',
    TABLOCK
);
GO

-- Insert data from staging table to main table with conversions
INSERT INTO NashvilleHousingData (
    UniqueID, ParcelID, LandUse, PropertyAddress, SaleDate, SalePrice, 
    LegalReference, SoldAsVacant, OwnerName, OwnerAddress, Acreage, 
    TaxDistrict, LandValue, BuildingValue, TotalValue, YearBuilt, 
    Bedrooms, FullBath, HalfBath
)
SELECT 
    CAST(UniqueID AS INT),
    ParcelID,
    LandUse,
    PropertyAddress,
    SaleDate,  -- Keep as string for now
    CAST(SalePrice AS INT),
    LegalReference,
    SoldAsVacant,
    OwnerName,
    OwnerAddress,
    CAST(Acreage AS FLOAT),
    TaxDistrict,
    CAST(LandValue AS INT),
    CAST(BuildingValue AS INT),
    CAST(TotalValue AS INT),
    CAST(YearBuilt AS INT),
    CAST(Bedrooms AS INT),
    CAST(FullBath AS INT),
    CAST(HalfBath AS INT)
FROM NashvilleHousingStaging;
GO

SELECT TOP 100 * FROM NashvilleHousingStaging
WHERE TRY_CAST(UniqueID AS INT) IS NULL
   OR TRY_CAST(SalePrice AS INT) IS NULL
   OR TRY_CAST(LandValue AS INT) IS NULL
   OR TRY_CAST(BuildingValue AS INT) IS NULL
   OR TRY_CAST(TotalValue AS INT) IS NULL
   OR TRY_CAST(YearBuilt AS INT) IS NULL
   OR TRY_CAST(Bedrooms AS INT) IS NULL
   OR TRY_CAST(FullBath AS INT) IS NULL
   OR TRY_CAST(HalfBath AS INT) IS NULL;

-- Modify insert statement to handle potential conversion issues
INSERT INTO NashvilleHousingData (
    UniqueID, ParcelID, LandUse, PropertyAddress, SaleDate, SalePrice, 
    LegalReference, SoldAsVacant, OwnerName, OwnerAddress, Acreage, 
    TaxDistrict, LandValue, BuildingValue, TotalValue, YearBuilt, 
    Bedrooms, FullBath, HalfBath
)
SELECT 
    TRY_CAST(UniqueID AS INT),
    ParcelID,
    LandUse,
    PropertyAddress,
    SaleDate,
    TRY_CAST(REPLACE(SalePrice, ',', '') AS INT),
    LegalReference,
    SoldAsVacant,
    OwnerName,
    OwnerAddress,
    TRY_CAST(Acreage AS FLOAT),
    TaxDistrict,
    TRY_CAST(REPLACE(LandValue, ',', '') AS INT),
    TRY_CAST(REPLACE(BuildingValue, ',', '') AS INT),
    TRY_CAST(REPLACE(TotalValue, ',', '') AS INT),
    TRY_CAST(YearBuilt AS INT),
    TRY_CAST(Bedrooms AS INT),
    TRY_CAST(FullBath AS INT),
    TRY_CAST(HalfBath AS INT)
FROM NashvilleHousingStaging;

-- Check for any rows that weren't inserted due to conversion issues
SELECT *
FROM NashvilleHousingStaging s
WHERE NOT EXISTS (
    SELECT 1 
    FROM NashvilleHousingData d 
    WHERE d.UniqueID = TRY_CAST(s.UniqueID AS INT)
);

-- Verify the data
SELECT TOP 100 * FROM NashvilleHousingData;

-- 

