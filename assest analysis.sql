-- Count assets by type (Laptop / Desktop / Others)--

SELECT AssetType, COUNT(*) AS TotalAssets
FROM AM_AssetInwardDetails
GROUP BY AssetType;

-- Total purchase amount by vendor--

SELECT PartnerName, SUM(Amount) AS TotalSpend
FROM AM_AssetInwardDetails
GROUP BY PartnerName
ORDER BY TotalSpend DESC;

-- Count antivirus installations by antivirus type--

SELECT Name AS AntivirusName, COUNT(*) AS InstalledOnAssets
FROM AM_Antivirus
GROUP BY Name
ORDER BY InstalledOnAssets DESC;

-- Find devices with low battery (remaining < 50%)--

SELECT AssetId, PercentRemaining, PowerPlugged
FROM AM_BatteryInfo
WHERE PercentRemaining < 50;


-- Assets that failed audit (Not Found or Not Available)

SELECT AssetId, AssetOwnerName, AssetAvailability, AssetStatus
FROM AM_AssetVerification
WHERE AssetAvailability IN ('Not Found', 'Not Available');

-- Assets missing essential security software

SELECT AssetId, SapphireStatus, NetSkopeStatus, SCCMStatus
FROM AM_AssetVerification
WHERE SapphireStatus = 'Not Installed'
   OR NetSkopeStatus = 'Not Installed'
   OR SCCMStatus = 'Not Installed';

-- Count of assets assigned to each employee

SELECT AssetOwnerName, COUNT(*) AS TotalAssets
FROM AM_AssetVerification
GROUP BY AssetOwnerName
ORDER BY TotalAssets DESC;

-- Asset counts by location

SELECT LocationName, COUNT(*) AS AssetCount
FROM AM_AssetVerification
GROUP BY LocationName
ORDER BY AssetCount DESC;

-- Identify aging assets (Purchased more than 30 days)

SELECT AssetType, InvoiceDate, PartnerName
FROM AM_AssetInwardDetails
WHERE InvoiceDate < DATE_SUB(NOW(), INTERVAL 30 DAY);

-- Assets Purchased vs Actually Allocated

SELECT 
    d.AssetType,
    COUNT(DISTINCT d.id) AS Purchased,
    COUNT(DISTINCT v.AssetId) AS Allocated
FROM AM_AssetInwardDetails d
LEFT JOIN AM_AssetVerification v
    ON d.id = v.AssetId
GROUP BY d.AssetType;


-- Duplicate Assets (Same Serial in Multiple Tables)

SELECT SerialNumber, COUNT(*) AS Occurrences
FROM (
    SELECT SerialNumber FROM AM_AssetVerification
    UNION ALL
    SELECT SerialNumber FROM AM_Bios
) AS all_serials
GROUP BY SerialNumber
HAVING COUNT(*) > 1;

-- Devices Missing Warranty or AMC

SELECT assetid, PartnerName, Warranty, Amc
FROM AM_AssetPurchaseSupport
WHERE IFNULL(Warranty,0) = 0
   OR IFNULL(Amc,0) = 0;

-- System Health Score (Battery + BIOS + Antivirus)

SELECT 
    b.AssetId,
    b.PercentRemaining,
    bios.Version AS BiosVersion,
    av.Name AS Antivirus,
    CASE 
        WHEN b.PercentRemaining < 50 THEN 'Poor'
        WHEN av.Name IS NULL THEN 'Security Risk'
        ELSE 'Healthy'
    END AS HealthStatus
FROM AM_BatteryInfo b
LEFT JOIN AM_Bios bios ON b.AssetId = bios.AssetId
LEFT JOIN AM_Antivirus av ON b.AssetId = av.AssetId;

-- Assets With Outdated BIOS

SELECT 
    AssetId, Manufacturer, Version, ReleaseDate
FROM AM_Bios
WHERE ReleaseDate < DATE_SUB(NOW(), INTERVAL 3 YEAR);

-- Unauthorized USB Devices (External Storage)

SELECT AssetId, DeviceName, Manufacturer
FROM AM_AttachedDevices
WHERE DeviceNameDescription LIKE '%USB%'
  AND DeviceName NOT LIKE '%Mouse%'
  AND DeviceName NOT LIKE '%Keyboard%';
  
  -- Antivirus Not Up-To-Date
  
  SELECT AssetId, Name, IsUptoDate
FROM AM_Antivirus
WHERE IsUptoDate = '0';

-- Employee Having Multiple Assets

SELECT AssetOwnerName, COUNT(*) AS TotalAssets
FROM AM_AssetVerification
GROUP BY AssetOwnerName
HAVING COUNT(*) > 01;

-- Asset Condition Risk List

SELECT AssetId, AssetCondition, AssetRemarks
FROM AM_AssetVerification
WHERE AssetCondition IN ('Needs Repair', 'Minor scratches', 'Battery needs replacement');

-- Total Spend by Asset Category

SELECT AssetCategory, SUM(Amount) AS TotalCost
FROM AM_AssetInwardDetails
GROUP BY AssetCategory;

-- Top 5 Most Expensive Purchases

SELECT AssetType, Description, Amount, PartnerName
FROM AM_AssetInwardDetails
ORDER BY Amount DESC
LIMIT 5;

-- Devices Missing ANY Security Agent

SELECT AssetId, SapphireStatus, SCCMStatus, NetSkopeStatus
FROM AM_AssetVerification
WHERE SapphireStatus = 'Not Installed'
   OR SCCMStatus = 'Not Installed'
   OR NetSkopeStatus = 'Not Installed';
   
   -- Full Purchase → Asset Assignment → Verification Workflow
   
   SELECT 
    d.InvoiceNo,
    d.AssetType,
    d.Description,
    d.PartnerName AS Vendor,
    v.AssetOwnerName,
    v.LocationName,
    v.AssetCondition,
    v.VerificationStatus
FROM AM_AssetInwardDetails d
LEFT JOIN AM_AssetVerification v
       ON d.id = v.AssetId;

 -- Find Configuration Mismatch (RAM difference between records)
 
 SELECT 
    c.AssetId,
    c.PhysicalMemory AS ConfigRAM,
    v.RAM AS VerifiedRAM
FROM AM_Configuration c
JOIN AM_AssetVerification v ON c.AssetId = v.AssetId
WHERE c.PhysicalMemory <> v.RAM;

-- Location-Wise Hardware Performance Summary

SELECT 
    LocationName,
    AVG(CASE WHEN HDDType='SSD' THEN 1 ELSE 0 END) * 100 AS SSD_Percentage,
    AVG(RAM) AS AvgRAM
FROM AM_AssetVerification
GROUP BY LocationName;

-- Employees With Unverified Assets

SELECT AssetOwnerName, AssetId, VerificationStatus
FROM AM_AssetVerification
WHERE VerificationStatus <> 'Verified';

-- Monthly Asset Purchase Trend

SELECT 
    DATE_FORMAT(InvoiceDate, '%Y-%m') AS Month,
    COUNT(*) AS TotalAssetsPurchased,
    SUM(Amount) AS Cost
FROM AM_AssetInwardDetails
GROUP BY DATE_FORMAT(InvoiceDate, '%Y-%m')
ORDER BY Month;


