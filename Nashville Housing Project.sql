-- cleaning data in sql query

select * from Housingdatabase.dbo.Nashvillehousing

--standardize date format

select SaleDate from Housingdatabase.dbo.Nashvillehousing

SELECT CONVERT(date, SaleDate) AS saledateconverted
from Housingdatabase.dbo.Nashvillehousing

UPDATE Nashvillehousing
SET SaleDate = CONVERT(date, SaleDate)

--populate property address data which are null. there are parcel multiple same parcel id which corresponds to same propertyaddress, but some address
--is null so we are going to populate it by joing the same table together


select a.ParcelID, a.PropertyAddress , b.ParcelID,b.PropertyAddress, isnull (a.PropertyAddress,b.PropertyAddress)
from Housingdatabase.dbo.Nashvillehousing a
join Housingdatabase.dbo.Nashvillehousing b
on a.ParcelID=b.ParcelID
and a.[UniqueID ]<> b.[UniqueID ]  -- so that these will never repeat
where a.PropertyAddress is null 

update a
set PropertyAddress = b.PropertyAddress
from Housingdatabase.dbo.Nashvillehousing a
join Housingdatabase.dbo.Nashvillehousing b
on a.ParcelID=b.ParcelID
and a.[UniqueID ]<> b.[UniqueID ]  -- so that these will never repeat
where a.PropertyAddress is null 

-- breaking out address into individual columns (address,city,state)

select *
from Housingdatabase.dbo.Nashvillehousing

SELECT
    SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1) AS address,
    SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress)) AS city
FROM Nashvillehousing;

alter table Nashvillehousing
add PropertysplitAddress nvarchar(255)

update Nashvillehousing
set PropertysplitAddress =  SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1)

alter table Nashvillehousing
add PropertysplitCity nvarchar(255)

update Nashvillehousing
set PropertysplitCity = Substring (PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress))

--owneradress split

select OwnerAddress
from Housingdatabase.dbo.Nashvillehousing

select 
Parsename(replace (OwnerAddress, ',','.'),3) As Address,
Parsename(replace (OwnerAddress, ',','.'),2) as City,
Parsename(replace (OwnerAddress, ',','.'),1) As State
from Housingdatabase.dbo.Nashvillehousing

alter table Nashvillehousing
add OwnersplitAddress nvarchar(255)

update Nashvillehousing
set OwnersplitAddress = Parsename(replace (OwnerAddress, ',','.'),3)

alter table Nashvillehousing
add OwnersplitCity nvarchar(255)

update Nashvillehousing
set OwnersplitCity = Parsename(replace (OwnerAddress, ',','.'),2) 

alter table Nashvillehousing
add OwnersplitState nvarchar(255)

update Nashvillehousing
set OwnersplitState = Parsename(replace (OwnerAddress, ',','.'),1)

-- change Y and N to yes and no

Select distinct (SoldAsVacant), COUNT( SoldAsVacant)

from Housingdatabase.dbo.Nashvillehousing
Group by SoldAsVacant
order by 2

Select SoldAsVacant,
CASE
   When SoldAsVacant='N' Then 'No'
   When SoldAsVacant='Y'Then 'Yes'
   Else SoldAsVacant

End 
from Housingdatabase.dbo.Nashvillehousing

update Nashvillehousing
set SoldAsVacant= CASE
   When SoldAsVacant='N' Then 'No'
   When SoldAsVacant='Y'Then 'Yes'
   Else SoldAsVacant

End

-- remove duplicates
select * 
from Housingdatabase.dbo.Nashvillehousing

With RowNumCTE as (
Select *,
ROW_NUMBER() over ( Partition by 

ParcelId, PropertyAddress, SalePrice,SaleDate,LegalReference 
Order by UniqueId) row_num
from Housingdatabase.dbo.Nashvillehousing
)

select* from RowNumCTE
where row_num> 1 
Order by PropertyAddress -- duplicate value showing  as row-num

With RowNumCTE as (
Select *,
ROW_NUMBER() over ( Partition by 

ParcelId, PropertyAddress, SalePrice,SaleDate,LegalReference 
Order by UniqueId) as row_num
from Housingdatabase.dbo.Nashvillehousing
)

delete from RowNumCTE
where row_num> 1 --In this modified query, the CTE named RowNumCTE is defined and includes the ROW_NUMBER() function applied to the specified columns. 
--The PARTITION BY clause determines the grouping criteria for identifying duplicates

-- deleting some columns that are not necessary

select * 
from Housingdatabase.dbo.Nashvillehousing

Alter table Nashvillehousing
drop column SaleDate, TaxDistrict,OwnerAddress,PropertyAddress


