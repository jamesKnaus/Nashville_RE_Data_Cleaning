/*
Nashville Housing Data Analysis Views

Purpose: This script creates various views for analyzing the cleaned Nashville Housing dataset.
Database: NashvilleHousing

Views created:
1. vw_PriceTrends - Analyzes price trends over time
2. vw_PropertyCharacteristics - Examines property characteristics in relation to sale prices
3. vw_LocationAnalysis - Compares property sales and prices across different cities
4. vw_AgeValueRelation - Analyzes how property age relates to sale prices and total values
5. vw_VacantPropertySales - Compares sales of vacant properties versus occupied properties
6. vw_PropertyPriceComparison - Detailed price analysis and comparison within categories

Note: Ensure that the vw_CleanNashvilleHousing view from the data cleaning script exists before running these view creations.
*/

USE NashvilleHousing;
GO

-- 1. Price Trends View
CREATE OR ALTER VIEW vw_PriceTrends AS
WITH MonthlyStats AS (
    SELECT 
        YEAR(SaleDate) AS SaleYear,
        MONTH(SaleDate) AS SaleMonth,
        AVG(SalePrice) AS AvgSalePrice,
        COUNT(*) AS TotalSales
    FROM vw_CleanNashvilleHousing
    GROUP BY YEAR(SaleDate), MONTH(SaleDate)
)
SELECT 
    SaleYear,
    SaleMonth,
    AvgSalePrice,
    TotalSales,
    AVG(AvgSalePrice) OVER (ORDER BY SaleYear, SaleMonth ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS MovingAvgPrice,
    LAG(AvgSalePrice) OVER (ORDER BY SaleYear, SaleMonth) AS PrevMonthAvgPrice,
    (AvgSalePrice - LAG(AvgSalePrice) OVER (ORDER BY SaleYear, SaleMonth)) / LAG(AvgSalePrice) OVER (ORDER BY SaleYear, SaleMonth) * 100 AS PriceChangePercent,
    SUM(TotalSales) OVER (ORDER BY SaleYear, SaleMonth) AS CumulativeSales,
    RANK() OVER (ORDER BY AvgSalePrice DESC) AS PriceRank,
    PERCENT_RANK() OVER (ORDER BY AvgSalePrice) AS PercentileRank
FROM MonthlyStats;

GO

-- 2. Property Characteristics and Price View
CREATE OR ALTER VIEW vw_PropertyCharacteristics AS
WITH RankedProperties AS (
    SELECT 
        LandUse,
        SalePrice,
        Acreage,
        YearBuilt,
        Bedrooms,
        FullBath + HalfBath AS TotalBaths,
        ROW_NUMBER() OVER (PARTITION BY LandUse ORDER BY SalePrice DESC) AS PriceRank
    FROM vw_CleanNashvilleHousing
)
SELECT 
    LandUse,
    AVG(SalePrice) AS AvgSalePrice,
    AVG(Acreage) AS AvgAcreage,
    AVG(YearBuilt) AS AvgYearBuilt,
    AVG(Bedrooms) AS AvgBedrooms,
    AVG(TotalBaths) AS AvgTotalBaths,
    COUNT(*) AS PropertyCount,
    MAX(CASE WHEN PriceRank = 1 THEN SalePrice END) AS HighestSalePrice,
    MIN(CASE WHEN PriceRank = COUNT(*) OVER (PARTITION BY LandUse) THEN SalePrice END) AS LowestSalePrice
FROM RankedProperties
GROUP BY LandUse;

GO

-- 3. Location-based Analysis View
CREATE OR ALTER VIEW vw_LocationAnalysis AS
WITH CityStats AS (
    SELECT 
        PropertySplitCity,
        COUNT(*) AS TotalProperties,
        AVG(SalePrice) AS AvgSalePrice,
        MAX(SalePrice) AS MaxSalePrice,
        MIN(SalePrice) AS MinSalePrice,
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY SalePrice) OVER (PARTITION BY PropertySplitCity) AS MedianSalePrice
    FROM vw_CleanNashvilleHousing
    GROUP BY PropertySplitCity
)
SELECT 
    PropertySplitCity,
    TotalProperties,
    AvgSalePrice,
    MaxSalePrice,
    MinSalePrice,
    MedianSalePrice,
    RANK() OVER (ORDER BY AvgSalePrice DESC) AS CityPriceRank,
    PERCENT_RANK() OVER (ORDER BY TotalProperties) AS PercentileByPropertyCount
FROM CityStats;

GO

-- 4. Age of Property and Value View
CREATE OR ALTER VIEW vw_AgeValueRelation AS
WITH AgeCategorized AS (
    SELECT 
        CASE 
            WHEN YearBuilt >= 2010 THEN '2010s and newer'
            WHEN YearBuilt >= 2000 THEN '2000s'
            WHEN YearBuilt >= 1990 THEN '1990s'
            WHEN YearBuilt >= 1980 THEN '1980s'
            WHEN YearBuilt >= 1970 THEN '1970s'
            ELSE 'Pre-1970s'
        END AS AgeGroup,
        SalePrice,
        TotalValue,
        YearBuilt
    FROM vw_CleanNashvilleHousing
)
SELECT 
    AgeGroup,
    AVG(SalePrice) AS AvgSalePrice,
    AVG(TotalValue) AS AvgTotalValue,
    COUNT(*) AS PropertyCount,
    MIN(YearBuilt) AS OldestProperty,
    MAX(YearBuilt) AS NewestProperty,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY SalePrice) OVER (PARTITION BY AgeGroup) AS MedianSalePrice,
    STDEV(SalePrice) AS SalePriceStdDev
FROM AgeCategorized
GROUP BY AgeGroup;

GO

-- 5. Vacant Property Sales View
CREATE OR ALTER VIEW vw_VacantPropertySales AS
WITH VacancyStats AS (
    SELECT 
        SoldAsVacant,
        COUNT(*) AS TotalSales,
        AVG(SalePrice) AS AvgSalePrice,
        AVG(Acreage) AS AvgAcreage,
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY SalePrice) OVER (PARTITION BY SoldAsVacant) AS MedianSalePrice
    FROM vw_CleanNashvilleHousing
    GROUP BY SoldAsVacant
)
SELECT 
    SoldAsVacant,
    TotalSales,
    AvgSalePrice,
    MedianSalePrice,
    AvgAcreage,
    AvgSalePrice - LAG(AvgSalePrice) OVER (ORDER BY SoldAsVacant) AS PriceDifferenceFromNonVacant,
    (AvgSalePrice - LAG(AvgSalePrice) OVER (ORDER BY SoldAsVacant)) / LAG(AvgSalePrice) OVER (ORDER BY SoldAsVacant) * 100 AS PercentDifferenceFromNonVacant
FROM VacancyStats;

GO

-- 6. Property Price Comparison
CREATE OR ALTER VIEW vw_PropertyPriceComparison AS
WITH RankedProperties AS (
    SELECT 
        UniqueID,
        PropertySplitAddress,
        SalePrice,
        SaleDate,
        Acreage,
        LandUse,
        YearBuilt,
        TotalValue,
        DENSE_RANK() OVER (PARTITION BY LandUse ORDER BY SalePrice DESC) AS PriceRankInCategory,
        PERCENT_RANK() OVER (PARTITION BY LandUse ORDER BY SalePrice) AS PercentileInCategory,
        AVG(SalePrice) OVER (PARTITION BY LandUse) AS AvgPriceInCategory,
        SalePrice - AVG(SalePrice) OVER (PARTITION BY LandUse) AS PriceDiffFromCategoryAvg,
        SUM(SalePrice) OVER (PARTITION BY LandUse ORDER BY SaleDate) AS CumulativeSalesInCategory
    FROM vw_CleanNashvilleHousing
)
SELECT 
    UniqueID,
    PropertySplitAddress,
    SalePrice,
    SaleDate,
    Acreage,
    LandUse,
    YearBuilt,
    TotalValue,
    PriceRankInCategory,
    PercentileInCategory,
    AvgPriceInCategory,
    PriceDiffFromCategoryAvg,
    CumulativeSalesInCategory,
    FIRST_VALUE(SalePrice) OVER (PARTITION BY LandUse ORDER BY SalePrice DESC) AS HighestPriceInCategory,
    LAST_VALUE(SalePrice) OVER (PARTITION BY LandUse ORDER BY SalePrice DESC 
        RANGE BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS LowestPriceInCategory,
    LEAD(SalePrice) OVER (PARTITION BY LandUse ORDER BY SalePrice) AS NextHigherPrice,
    LAG(SalePrice) OVER (PARTITION BY LandUse ORDER BY SalePrice) AS PreviousLowerPrice,
    NTILE(4) OVER (PARTITION BY LandUse ORDER BY SalePrice) AS PriceQuartile
FROM RankedProperties;

GO