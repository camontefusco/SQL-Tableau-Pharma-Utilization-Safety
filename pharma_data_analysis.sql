-- =============================================
-- PHARMA DATA ANALYSIS FULL SQL SCRIPT
-- Author: Carlos Montefusco
-- Description: Comprehensive SQL queries demonstrating
--              SELECTs, JOINs, aggregates, subqueries,
--              CTEs, temporary tables, window functions
-- Database: pharma_db
-- =============================================

USE pharma_db;

-- =============================================
-- BASIC QUERIES
-- =============================================

-- 1. List all drugs with relevant details
SELECT drug_id, drug_name, atc_code, manufacturer, approval_date
FROM drugs
LIMIT 1000;

-- 2. Count total number of patients
SELECT COUNT(*) AS total_patients
FROM patients;

-- 3. List all patients from a specific region
-- Replace 'RegionNameHere' with the actual region string you want to filter
SELECT *
FROM patients
WHERE region = 'East' -- 'RegionNameHere'
LIMIT 1000;

-- 4. List prescriptions with drug names
SELECT pr.prescription_id, d.drug_name, pr.patient_id, pr.prescribed_date
FROM prescriptions pr
JOIN drugs d ON pr.drug_id = d.drug_id
LIMIT 1000;

-- 5. Adverse events for patient_id = 381
SELECT *
FROM adverse_events
WHERE patient_id = 381;

-- =============================================
-- AGGREGATE QUERIES
-- =============================================

-- 6. Count prescriptions per drug
SELECT drug_id, COUNT(*) AS prescription_count
FROM prescriptions
GROUP BY drug_id
ORDER BY prescription_count DESC;

-- 7. Average age of patients per region
SELECT region, AVG(age) AS avg_age
FROM patients
GROUP BY region;

-- 8. Total adverse events reported per drug
SELECT d.drug_name, COUNT(a.event_id) AS adverse_event_count
FROM adverse_events a
JOIN drugs d ON a.drug_id = d.drug_id
GROUP BY d.drug_name
ORDER BY adverse_event_count DESC
LIMIT 1000;

-- 9. Count of patients by gender
SELECT gender, COUNT(*) AS count
FROM patients
GROUP BY gender;

-- 10. Number of prescriptions per year
SELECT YEAR(pr.prescribed_date) AS year, COUNT(*) AS prescription_count
FROM prescriptions pr
GROUP BY year
ORDER BY year;

-- 11. Patients with more than 3 prescriptions
SELECT patient_id, COUNT(*) AS prescription_count
FROM prescriptions
GROUP BY patient_id
HAVING prescription_count > 3;

-- 12. Drugs with no adverse events reported
SELECT d.drug_id, d.drug_name
FROM drugs d
LEFT JOIN adverse_events a ON d.drug_id = a.drug_id
WHERE a.event_id IS NULL;

SELECT drug_id, drug_name
FROM drugs
WHERE drug_name IS NULL OR drug_name = '';

SELECT d.drug_id, d.drug_name
FROM drugs d
LEFT JOIN adverse_events a ON d.drug_id = a.drug_id
WHERE a.event_id IS NULL
  AND d.drug_name IS NOT NULL
  AND d.drug_name <> '';

SELECT d.drug_id,
       COALESCE(NULLIF(d.drug_name, ''), '[No Name]') AS drug_name
FROM drugs d
LEFT JOIN adverse_events a ON d.drug_id = a.drug_id
WHERE a.event_id IS NULL;
/*Every drug has at least one adverse event in the adverse_events table, or

There's a mismatch causing no drugs to qualify as “no adverse events”.*/

-- 13. Most common adverse event description (event_type)
SELECT event_type, COUNT(*) AS count
FROM adverse_events
GROUP BY event_type
ORDER BY count DESC
LIMIT 1;

-- 14. Patients with their region names
SELECT patient_id, gender, age, region
FROM patients;

-- 15. Drugs prescribed to patients over 65 years old
SELECT DISTINCT d.drug_name
FROM prescriptions pr
JOIN patients p ON pr.patient_id = p.patient_id
JOIN drugs d ON pr.drug_id = d.drug_id
WHERE p.age > 65;

-- 16. Average prescriptions per patient by region
SELECT region, AVG(prescription_counts.count) AS avg_prescriptions
FROM (
  SELECT patient_id, COUNT(*) AS count
  FROM prescriptions
  GROUP BY patient_id
) AS prescription_counts
JOIN patients p ON prescription_counts.patient_id = p.patient_id
GROUP BY region;

-- 17. Rank drugs by adverse events count
SELECT d.drug_name, COUNT(a.event_id) AS adverse_event_count,
       RANK() OVER (ORDER BY COUNT(a.event_id) DESC) AS `rank`
FROM drugs d
LEFT JOIN adverse_events a ON d.drug_id = a.drug_id
GROUP BY d.drug_name
ORDER BY `rank`;

-- 18. Patients with adverse events within 30 days of prescription
SELECT DISTINCT p.patient_id
FROM patients p
JOIN prescriptions pr ON p.patient_id = pr.patient_id
JOIN adverse_events a ON p.patient_id = a.patient_id AND a.drug_id = pr.drug_id
WHERE DATEDIFF(a.event_date, pr.prescribed_date) <= 30;

-- 19. Count of adverse events by event_type (severity)
SELECT event_type, severity, COUNT(*) AS count
FROM adverse_events
GROUP BY event_type, severity
ORDER BY count DESC;

-- 20. Prescriptions without any adverse events
SELECT pr.prescription_id, pr.patient_id, pr.drug_id, pr.prescribed_date
FROM prescriptions pr
LEFT JOIN adverse_events a ON pr.patient_id = a.patient_id AND pr.drug_id = a.drug_id
WHERE a.event_id IS NULL;

-- Bonus: Create view summarizing patient safety
CREATE OR REPLACE VIEW patient_safety_summary AS
SELECT p.patient_id, p.gender, p.age, p.region,
       COUNT(DISTINCT pr.prescription_id) AS total_prescriptions,
       COUNT(DISTINCT a.event_id) AS total_adverse_events
FROM patients p
LEFT JOIN prescriptions pr ON p.patient_id = pr.patient_id
LEFT JOIN adverse_events a ON p.patient_id = a.patient_id AND pr.drug_id = a.drug_id
GROUP BY p.patient_id, p.gender, p.age, p.region;

SELECT * FROM patient_safety_summary
ORDER BY total_adverse_events DESC
LIMIT 20;
/*Interpretation:
total_prescriptions: How many prescriptions that patient had.

total_adverse_events: How many adverse events linked to their prescribed drugs.

You can spot patients with high adverse events relative to prescriptions — these might need further review.*/

-- Patients with no prescriptions
SELECT * FROM patient_safety_summary WHERE total_prescriptions = 0;

-- Patients with prescriptions but no adverse events
SELECT * FROM patient_safety_summary WHERE total_prescriptions > 0 AND total_adverse_events = 0;

-- Subquery example: Patients with more prescriptions than average
SELECT patient_id
FROM patients
WHERE patient_id IN (
  SELECT patient_id
  FROM prescriptions
  GROUP BY patient_id
  HAVING COUNT(*) > (
    SELECT AVG(prescription_count) FROM (
      SELECT COUNT(*) AS prescription_count
      FROM prescriptions
      GROUP BY patient_id
    ) AS sub_avg
  )
);

-- CTE: Rank drugs by adverse event counts
WITH adverse_counts AS (
  SELECT d.drug_id, d.drug_name, COUNT(a.event_id) AS adverse_event_count
  FROM drugs d
  LEFT JOIN adverse_events a ON d.drug_id = a.drug_id
  GROUP BY d.drug_id, d.drug_name
)
SELECT 
  drug_id, 
  drug_name, 
  adverse_event_count,
  RANK() OVER (ORDER BY adverse_event_count DESC) AS `rank`
FROM adverse_counts;


-- CTE: Patients with adverse events within 30 days after prescription
WITH adverse_within_30_days AS (
  SELECT p.patient_id, COUNT(a.event_id) AS adverse_event_count
  FROM patients p
  JOIN prescriptions pr ON p.patient_id = pr.patient_id
  JOIN adverse_events a ON p.patient_id = a.patient_id AND pr.drug_id = a.drug_id
  WHERE DATEDIFF(a.event_date, pr.prescribed_date) <= 30
  GROUP BY p.patient_id
)
SELECT *
FROM adverse_within_30_days
WHERE adverse_event_count > 0
ORDER BY adverse_event_count DESC;

-- Temporary table example: Prescriptions for patients over 60
CREATE TEMPORARY TABLE older_patients_prescriptions AS
SELECT pr.*
FROM prescriptions pr
JOIN patients p ON pr.patient_id = p.patient_id
WHERE p.age > 60;

SELECT drug_id, COUNT(*) AS prescription_count
FROM older_patients_prescriptions
GROUP BY drug_id
ORDER BY prescription_count DESC;

DROP TEMPORARY TABLE older_patients_prescriptions;

-- END OF SCRIPT
