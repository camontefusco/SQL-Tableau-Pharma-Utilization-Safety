CREATE DATABASE pharma_db;

-- Use the new database
USE pharma_db;
SELECT USER();

-- Create tables
CREATE TABLE drugs (
    drug_id INT PRIMARY KEY,
    drug_name VARCHAR(100),
    atc_code VARCHAR(10),
    manufacturer VARCHAR(100),
    approval_date DATE
);

CREATE TABLE patients (
    patient_id INT PRIMARY KEY,
    gender CHAR(1),
    age INT,
    region VARCHAR(50)
);

CREATE TABLE regions (
    region VARCHAR(50) PRIMARY KEY,
    country VARCHAR(50),
    population INT
);

CREATE TABLE prescriptions (
    prescription_id INT PRIMARY KEY,
    patient_id INT,
    drug_id INT,
    prescribed_date DATE,
    dosage_mg INT,
    duration_days INT,
    FOREIGN KEY (patient_id) REFERENCES patients(patient_id),
    FOREIGN KEY (drug_id) REFERENCES drugs(drug_id)
);

CREATE TABLE adverse_events (
    event_id INT PRIMARY KEY,
    patient_id INT,
    drug_id INT,
    event_date DATE,
    event_type VARCHAR(50),
    severity ENUM('Mild', 'Moderate', 'Severe'),
    outcome ENUM('Recovered', 'Ongoing', 'Hospitalized', 'Death'),
    FOREIGN KEY (patient_id) REFERENCES patients(patient_id),
    FOREIGN KEY (drug_id) REFERENCES drugs(drug_id)
);