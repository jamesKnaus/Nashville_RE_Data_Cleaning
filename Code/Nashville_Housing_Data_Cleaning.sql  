/*

Nashville Housing Data Cleaning Project

Purpose: This script demonstrates various data cleaning techniques on a real estate dataset.
Database: NashvilleHousing
Table: NashvilleHousingData

Operations performed:
1. Standardize Date Format
2. Populate Property Address data for NULL values
3. Break out Address into Individual Columns (Address, City, State) for both Property and Owner addresses
4. Standardize 'Yes' and 'No' values in the "Sold as Vacant" Field
5. Remove Duplicate Records
6. Perform Additional Data Quality Checks
   - Check for remaining NULL values in key fields
   - Display a sample of the final cleaned data
7. Create a View of the Cleaned Data for Future Analysis

*/

USE NashvilleHousing;
GO

-- 1. Standardize Date Format 
-- Purpose: Convert SaleDate to a standard Date format for consistency and easier querying
UPDATE NashvilleHousing.dbo.NashvilleHousingData
SET SaleDate = CONVERT(Date, SaleDate);

-- Verify date standardization
SELECT TOP 10 SaleDate, CONVERT(Date, SaleDate) AS StandardizedSaleDate 
FROM NashvilleHousing.dbo.NashvilleHousingData;

-- 2. Populate Property Address data for NULL Values 
-- Purpose: Fill in missing PropertyAddress values using data from records with the same ParcelID
UPDATE Original
SET PropertyAddress = ISNULL(Original.PropertyAddress, Matched.PropertyAddress)
FROM NashvilleHousing.dbo.NashvilleHousingData Original 
JOIN NashvilleHousing.dbo.NashvilleHousingData Matched
    ON Original.ParcelID = Matched.ParcelID
    AND Original.UniqueID <> Matched.UniqueID
WHERE Original.PropertyAddress IS NULL;

-- Verify NULL PropertyAddress update
SELECT COUNT(*) AS RemainingNullAddresses 
FROM NashvilleHousing.dbo.NashvilleHousingData
WHERE PropertyAddress IS NULL;

-- 3a. Breaking out PropertyAddress into Individual Columns (Address, City)
-- Purpose: Separate PropertyAddress into distinct columns for easier analysis
ALTER TABLE NashvilleHousing.dbo.NashvilleHousingData
ADD PropertySplitAddress NVARCHAR(255),
    PropertySplitCity NVARCHAR(255);

UPDATE NashvilleHousing.dbo.NashvilleHousingData
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1),
    PropertySplitCity = LTRIM(SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress)));

-- 3b. Breaking out OwnerAddress into Individual Columns (Address, City, State)
-- Purpose: Separate OwnerAddress into distinct columns for easier analysis
ALTER TABLE NashvilleHousing.dbo.NashvilleHousingData
ADD OwnerSplitAddress NVARCHAR(255),
    OwnerSplitCity NVARCHAR(255),
    OwnerSplitState NVARCHAR(255);

UPDATE NashvilleHousing.dbo.NashvilleHousingData
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3),
    OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2),
    OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1);

-- Verify address splitting
SELECT TOP 10 
    PropertyAddress, PropertySplitAddress, PropertySplitCity,
    OwnerAddress, OwnerSplitAddress, OwnerSplitCity, OwnerSplitState
FROM NashvilleHousing.dbo.NashvilleHousingData;

-- 4. Change Y and N to Yes and No in "Sold as Vacant" Field
-- Purpose: Standardize values in the SoldAsVacant field for consistency
UPDATE NashvilleHousing.dbo.NashvilleHousingData
SET SoldAsVacant = CASE 
                     WHEN SoldAsVacant = 'Y' THEN 'Yes'
                     WHEN SoldAsVacant = 'N' THEN 'No'
                     ELSE SoldAsVacant
                   END;

-- Verify SoldAsVacant update
SELECT DISTINCT SoldAsVacant, COUNT(SoldAsVacant) AS Count
FROM NashvilleHousing.dbo.NashvilleHousingData
GROUP BY SoldAsVacant
ORDER BY Count DESC;

-- 5. Remove Duplicates
-- Purpose: Identify and remove duplicate records based on specific criteria
-- Note: In practice, removing duplicates should be done cautiously and often with stakeholder approval
WITH RowNumCTE AS (
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY ParcelID,
                            PropertyAddress,
                            SalePrice,
                            SaleDate,
                            LegalReference
               ORDER BY UniqueID
           ) AS row_num
    FROM NashvilleHousing.dbo.NashvilleHousingData
)
DELETE FROM RowNumCTE WHERE row_num > 1;

-- Verify duplicate removal
SELECT COUNT(*) AS TotalRows FROM NashvilleHousing.dbo.NashvilleHousingData;

-- Additional Data Quality Checks
-- Purpose: Perform final checks on the cleaned data

-- Check for any remaining NULL values in key fields
SELECT COUNT(*) AS NullValueCount,
       'PropertyAddress' AS FieldName
FROM NashvilleHousing.dbo.NashvilleHousingData
WHERE PropertyAddress IS NULL
UNION ALL
SELECT COUNT(*), 'SaleDate'
FROM NashvilleHousing.dbo.NashvilleHousingData
WHERE SaleDate IS NULL
UNION ALL
SELECT COUNT(*), 'OwnerName'
FROM NashvilleHousing.dbo.NashvilleHousingData
WHERE OwnerName IS NULL;

-- Sample of final cleaned data
SELECT TOP 20 *
FROM NashvilleHousing.dbo.NashvilleHousingData;

-- Create a view of the cleaned data for easier future analysis
CREATE OR ALTER VIEW vw_CleanNashvilleHousing AS
SELECT 
    UniqueID,
    ParcelID,
    LandUse,
    PropertySplitAddress,
    PropertySplitCity,
    SaleDate,
    SalePrice,
    LegalReference,
    SoldAsVacant,
    OwnerName,
    OwnerSplitAddress,
    OwnerSplitCity,
    OwnerSplitState,
    Acreage,
    TaxDistrict,
    LandValue,
    BuildingValue,
    TotalValue,
    YearBuilt,
    Bedrooms,
    FullBath,
    HalfBath
FROM NashvilleHousing.dbo.NashvilleHousingData;

-- Verify the view
SELECT TOP 10 * FROM vw_CleanNashvilleHousing;
