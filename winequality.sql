
SELECT *
FROM winequality.winequality
WHERE (`volatile acidity` * sulphates) / alcohol > 0.05
  AND quality = 5;



select *
from winequalityred.winequality1
; 
-- Retrieve all records where quality < 6.

select *
from winequalityred.winequality1
WHERE quality < 6; 

-- Select wines with Risk Score > 0.05 and quality = 5.

SELECT *
FROM winequalityred.winequality1
WHERE risk_score > 0.05
  AND quality = 5;
  
-- Find average alcohol, density, and pH grouped by quality.

SELECT 
    quality,
    AVG(alcohol) AS avg_alcohol,
    AVG(density) AS avg_density,
    AVG(pH) AS avg_pH
FROM winequalityred.winequality1
GROUP BY quality
ORDER BY quality;

-- Find wines whose alcohol is above the average of their quality group.

SELECT w.*
FROM winequalityred.winequality1 w
WHERE w.alcohol >
      (SELECT AVG(w2.alcohol)
       FROM winequalityred.winequality1 w2
       WHERE w2.quality = w.quality);
       
-- Create a CTE to calculate Fermentation Index = alcohol × density / pH. 

WITH FermentationCTE AS (
    SELECT 
        quality,
        alcohol,
        density,
        pH,
        (alcohol * density / pH) AS fermentation_index
    FROM winequalityred.winequality1
)
SELECT *
FROM FermentationCTE;


 -- Join with a lookup table QualityBand to enrich quality categories. 
SELECT
    t.*,
    CASE
       
        WHEN t.quality >= 7 THEN 'High'
        WHEN t.quality >= 5 THEN 'Medium' 
	    WHEN t.quality <= 4 THEN 'Low'
	
        ELSE 'Unknown' 
    END AS QualityBand
FROM
    winequalityred.winequality1 t;
   SELECT
    t.*,
    qb.BandName AS QualityBand
FROM
    winequalityred.winequality1 t
INNER JOIN
    (
        SELECT 'Low' AS BandName, 0 AS MinScore, 4 AS MaxScore
        UNION ALL
        SELECT 'Medium', 5, 6
        UNION ALL
        SELECT 'High', 7, 10
    ) qb
    ON t.quality BETWEEN qb.MinScore AND qb.MaxScore;
    
--  Use RANK() to rank wines by citric acid within each quality band. 

SELECT
    t.*,
    
    CASE
        WHEN t.quality >= 7 THEN 'High'
        WHEN t.quality >= 5 THEN 'Medium'
        WHEN t.quality <= 4 THEN 'Low'
        ELSE 'Unknown'
    END AS QualityBand,
    
    RANK() OVER (
        PARTITION BY 
            (CASE
                WHEN t.quality >= 7 THEN 'High'
                WHEN t.quality >= 5 THEN 'Medium'
                WHEN t.quality <= 4 THEN 'Low'
                ELSE 'Unknown'
            END)
        ORDER BY 
            t.`citric acid`DESC 
    ) AS CitricAcid_Rank_Within_Band
FROM
    winequalityred.winequality1 t
ORDER BY
    QualityBand,
    CitricAcid_Rank_Within_Band;
    
-- Write a query to update quality to 'At Risk' where Risk Score > 0.08.

UPDATE
    winequalityred.winequality1
SET
    quality = 'At Risk'  
WHERE
    risk_score > 0.08;
    


-- Create a view HighRiskWines for Power BI import. 

CREATE OR REPLACE VIEW winequalityred.HighRiskWines AS
SELECT
    t.*, -- Keep this to select the original risk_score and all other base columns
    
    -- Calculated QualityBand
    CASE
        WHEN t.quality >= 7 THEN 'High'
        WHEN t.quality >= 5 THEN 'Medium'
        WHEN t.quality <= 4 THEN 'Low'
        ELSE 'Unknown'
    END AS QualityBand,
    
    -- Calculated RiskFlag
    CASE
        WHEN t.quality >= 7 THEN 'High Risk (Quality 7+)'
        ELSE 'Not High Risk' 
    END AS RiskFlag
    
    -- REMOVE the line 't.risk_score' here, as it's already included by t.*
    
FROM
    winequalityred.winequality1 t
WHERE
    t.quality >= 7;
    
SELECT
    *
FROM
    winequalityred.HighRiskWines
LIMIT 100;