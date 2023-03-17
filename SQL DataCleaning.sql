-- Basic information about the table

select count(*) from nashvillehousing; -- 56465 rows
SELECT count(*) FROM information_schema.columns 
WHERE table_name = 'nashvillehousing';   -- 19 columns
--------------------------------------------------------------
-- Standardize date format (SaleDate field is in text datatype)

update nashvillehousing set SaleDate =str_to_date(SaleDate,"%m/%d/%Y");
alter table nashvillehousing modify Saledate date;
---------------------------------------------------------------
-- Populate PropertyAddress data (Same ParcelID has unique UniqueID)
select a.UniqueID,a.ParcelID,a.PropertyAddress,b.ParcelID,b.PropertyAddress,
ifnull(a.PropertyAddress,b.PropertyAddress) -- 35rows returned
from nashvillehousing a
join nashvillehousing b
on a.ParcelID = b.ParcelID 
and a.UniqueID <> b.UniqueID
where a.PropertyAddress is null;

update world.nashvillehousing a 
join world.nashvillehousing b
on a.ParcelID = b.ParcelID 
and a.UniqueID <> b.UniqueID
set a.PropertyAddress = b.PropertyAddress
where a.PropertyAddress is null;

select * from world.nashvillehousing 
where PropertyAddress is null;   -- 0 rows returned
----------------------------------------------------------------------
-- Breaking out address into different columns(Address,city,state)
-- The substring() returns the string from the starting position SUBSTRING(str, pos, len)
-- however the CHARINDEX returns the substring position CHARINDEX 
-- (expressionToFind ,expressionToSearch [ , start_location ])in MS SQL
-- similar to charindex fn is locate fn  in mySQL
select propertyAddress from nashvillehousing;
select substring(PropertyAddress,1,locate(',',PropertyAddress)-1) as Address,
substring(PropertyAddress,locate(',',PropertyAddress)+1,length(PropertyAddress)) as City
from world.nashvillehousing ;

alter table nashvillehousing 
add PropertySplitAddress varchar(255);

update nashvillehousing
set PropertySplitAddress = substring(PropertyAddress,1,locate(',',PropertyAddress)-1);

alter table nashvillehousing 
add PropertySplitCity varchar(255);

update nashvillehousing
set PropertySplitCity = substring(PropertyAddress,locate(',',PropertyAddress)+1,length(PropertyAddress));

-- using substring_index
select OwnerAddress from nashvillehousing;
--  Syntax: SUBSTRING_INDEX(string, delimiter, number)in mysql
-- Syntax in MSSQL :parsename(replace(string,'delimiter','.'),string_piece from reverse)
SELECT SUBSTRING_INDEX(OwnerAddress, ', ', 1) AS Address,
SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress,',', 2), ',',-1) AS City,
SUBSTRING_INDEX(OwnerAddress, ',', -1) as State FROM  nashvillehousing;

alter table nashvillehousing 
add OwnerSplitAddress varchar(255);

update nashvillehousing
set OwnerSplitAddress = SUBSTRING_INDEX(OwnerAddress, ', ', 1);

alter table nashvillehousing 
add OwnerSplitCity varchar(255);

update nashvillehousing
set OwnerSplitCity = SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress,',', 2), ',',-1);

alter table nashvillehousing 
add OwnerSplitState varchar(255);

update nashvillehousing
set OwnerSplitState = SUBSTRING_INDEX(OwnerAddress,',',-1);

-- change Y and N to Yes and No in 'soldasvacant' field

select distinct(SoldAsVacant),count(SoldAsVacant) from nashvillehousing
group by SoldAsVacant;

update nashvillehousing set SoldAsVacant = case 
            when SoldAsVacant ='Y' then 'Yes'
            when SoldAsVacant ='N' then 'No'
            else SoldAsVacant
            end;
select count(SoldasVacant) from nashvillehousing
where SoldAsVacant ='NULL';
UPDATE nashvillehousing
SET SoldAsVacant = (@n := COALESCE(SoldAsVacant, @n))
ORDER BY SaleDate;

select SoldAsVacant from nashvillehousing;

-- remove duplicates rows 
SELECT 
ParcelID
FROM
nashvillehousing
    GROUP BY ParcelID
    HAVING 
    COUNT(ParcelID) > 1;
delete t1 from nashvillehousing t1
inner join nashvillehousing t2
where t1.UniqueID <t2.UniqueID and
      t1.ParcelID = t2.ParcelID  and
      t1.Saledate = t2.Saledate and
	  t1.SalePrice = t2.SalePrice and 
      t1.LegalReference = t2.LegalReference;
      
      
DELETE FROM nashvillehousing
WHERE 
	ParcelID IN (
	SELECT 
		ParcelID,PropertyAddress,SaleDate,SalePrice,LegalReference 
	FROM (
		SELECT *, ROW_NUMBER() OVER (
				PARTITION BY ParcelID,
                             PropertyAddress,
						     SaleDate,
                             SalePrice,
                             LegalReference 
				ORDER BY UniqueID) AS row_num
		FROM nashvillehousing
		) t
    WHERE row_num > 1
);
-- Delete unused columns
select * from nashvillehousing;
alter table nashvillehousing 
drop column PropertyAddress,
drop column OwnerAddress,
drop column TaxDistrict;