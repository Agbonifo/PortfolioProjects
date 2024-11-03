/*
Nashville housing data cleaning
*/


SELECT *
FROM ProjectDatabase.dbo.NashvilleHousing

---------------------------------------------------------------------------------------

-- Standardizing sale date to include only date instead of the initial date and time
SELECT SaleDate, CONVERT(date, SaleDate)
FROM ProjectDatabase.dbo.NashvilleHousing

ALTER TABLE ProjectDatabase.dbo.NashvilleHousing
ADD SaleDateConverted date;

UPDATE ProjectDatabase.dbo.NashvilleHousing
SET SaleDateConverted = CONVERT(date, SaleDate);


-----------------------------------------------------------------------------------------

-- Filling null property address with the corresponding address

SELECT *
FROM ProjectDatabase.dbo.NashvilleHousing;


SELECT a.ParcelID,
    a.PropertyAddress,
    b.ParcelID,
    b.PropertyAddress,
    ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM ProjectDatabase.dbo.NashvilleHousing a
    JOIN ProjectDatabase.dbo.NashvilleHousing b ON a.ParcelID = b.ParcelID
    AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress IS NULL;

UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM ProjectDatabase.dbo.NashvilleHousing a
    JOIN ProjectDatabase.dbo.NashvilleHousing b ON a.ParcelID = b.ParcelID
    AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress IS NULL;


------------------------------------------------------------------------

-- Breaking out address into separate columns (address, city, state)

SELECT *
FROM ProjectDatabase.dbo.NashvilleHousing;

SELECT PropertyAddress,
    SUBSTRING(
        PropertyAddress,
        1,
        CHARINDEX(',', PropertyAddress) - 1
    ) AS Address,
    SUBSTRING(
        PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress)
    ) AS City
FROM ProjectDatabase.dbo.NashvilleHousing;


SELECT OwnerAddress,
    SUBSTRING(
        OwnerAddress,
        1,
        CHARINDEX(',', OwnerAddress) - 1
    ) AS Address,
    SUBSTRING(
        OwnerAddress,
        CHARINDEX(',', OwnerAddress) + 1,
        CHARINDEX(
            ',',
            OwnerAddress,
            CHARINDEX(',', OwnerAddress) + 1
        ) - CHARINDEX(',', OwnerAddress) - 1
    ) AS City,
    LTRIM(
        RIGHT(
            OwnerAddress,
            LEN(OwnerAddress) - CHARINDEX(
                ',',
                OwnerAddress,
                CHARINDEX(',', OwnerAddress) + 1
            )
        )
    ) AS State
FROM ProjectDatabase.dbo.NashvilleHousing;

-- Using ParseName instead of Substring

-- Property address
Select PARSENAME(REPLACE(PropertyAddress, ',', '.'), 2) AS Address,
    PARSENAME(REPLACE(PropertyAddress, ',', '.'), 1) AS City
from ProjectDatabase.dbo.NashvilleHousing;

ALTER TABLE ProjectDatabase.dbo.NashvilleHousing
ADD PropertySplitAddress NVARCHAR(255);

UPDATE ProjectDatabase.dbo.NashvilleHousing
SET PropertySplitAddress = PARSENAME(REPLACE(PropertyAddress, ',', '.'), 2)

ALTER TABLE ProjectDatabase.dbo.NashvilleHousing
ADD PropertySplitCity NVARCHAR(255);

UPDATE ProjectDatabase.dbo.NashvilleHousing
SET PropertySplitCity = PARSENAME(REPLACE(PropertyAddress, ',', '.'), 1)

-- Owerner address 
Select PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3) AS Address,
    PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2) AS City,
    PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1) AS State
from ProjectDatabase.dbo.NashvilleHousing;

ALTER TABLE ProjectDatabase.dbo.NashvilleHousing
ADD OwnerSplitAddress NVARCHAR(255);

UPDATE ProjectDatabase.dbo.NashvilleHousing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3)

ALTER TABLE ProjectDatabase.dbo.NashvilleHousing
ADD OwnerSplitCity NVARCHAR(255);

UPDATE ProjectDatabase.dbo.NashvilleHousing
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2)

ALTER TABLE ProjectDatabase.dbo.NashvilleHousing
ADD OwnerSplitState NVARCHAR(255);

UPDATE ProjectDatabase.dbo.NashvilleHousing
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)



-----------------------------------------------------------------------------

-- Modify SoldAsVacant column to have uniform "Yes" or "No"


SELECT *
FROM ProjectDatabase.dbo.NashvilleHousing;


SELECT DISTINCT(SoldAsVacant),
    COUNT(SoldAsVacant) AS CountSoldAsVacant,
    CASE
    WHEN SoldAsVacant = 'Y' THEN 'Yes'
    WHEN SoldAsVacant = 'N' THEN 'No'
    ELSE SoldAsVacant
    End
FROM ProjectDatabase.dbo.NashvilleHousing
GROUP BY SoldAsVacant
ORDER BY CountSoldAsVacant;

UPDATE ProjectDatabase.dbo.NashvilleHousing
SET SoldAsVacant = CASE
        WHEN SoldAsVacant = 'Y' THEN 'Yes'
        WHEN SoldAsVacant = 'N' THEN 'No'
        ELSE SoldAsVacant
    End;



-------------------------------------------------------------------

-- Delete duplicate rows

WITH CTE AS (
SELECT *, ROW_NUMBER() OVER (PARTITION BY ParcelID,
PropertyAddress, SaleDate, SalePrice, LegalReference
ORDER BY UniqueID
) AS RowNum
FROM ProjectDatabase.dbo.NashvilleHousing
)
SELECT *
FROM CTE
WHERE RowNum > 1

WITH CTE AS (
SELECT *, ROW_NUMBER() OVER (PARTITION BY ParcelID,
PropertyAddress, SaleDate, SalePrice, LegalReference
ORDER BY UniqueID
) AS RowNum
FROM ProjectDatabase.dbo.NashvilleHousing
)
DELETE
FROM CTE
WHERE RowNum > 1

-----------------------------------------------------------------------

-- Drop unused columns

SELECT *
FROM ProjectDatabase.dbo.NashvilleHousing

ALTER TABLE ProjectDatabase.dbo.NashvilleHousing
DROP COLUMN SaleDate, PropertyAddress, OwnerAddress, TaxDistrict


------------------------------------------------------------------------

-- Rename the address columns (PropertySplitAddress, PropertySplitCity, OwnerSplitAddress, OwnerSplitCity, OwnerSplitState)