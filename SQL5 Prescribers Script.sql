-- 1.a. Which prescriber had the highest total number of claims (totaled over all drugs)? Report the npi and the total number of claims.
SELECT npi, nppes_provider_first_name, nppes_provider_last_org_name, SUM(total_claim_count) AS total_claim_count
FROM prescription INNER JOIN prescriber USING (npi)
GROUP BY npi, nppes_provider_first_name, nppes_provider_last_org_name
ORDER BY total_claim_count DESC
LIMIT 1;
--A: NPI=1881634483, Total Claim Count=99707


--1.b. Repeat the above, but this time report the nppes_provider_first_name, nppes_provider_last_org_name,  specialty_description, and the total number of claims.
SELECT npi, nppes_provider_first_name, nppes_provider_last_org_name, specialty_description, SUM(total_claim_count) AS total_claim_count
FROM prescription INNER JOIN prescriber USING (npi)
GROUP BY npi, nppes_provider_first_name, nppes_provider_last_org_name,  specialty_description
ORDER BY total_claim_count DESC
LIMIT 1;
--A: NPI=1881634483, Bruce Pendley, Family Practice, Total Claim Count=99707


--2.a.Which specialty had the most total number of claims (totaled over all drugs)?
SELECT DISTINCT specialty_description, SUM(total_claim_count) AS Total_Claim_Count
FROM prescriber INNER JOIN prescription USING (npi)
GROUP BY specialty_description
ORDER BY Total_Claim_Count DESC
LIMIT 1;
--A: Family Practice


-- 2.b. Which specialty had the most total number of claims for opioids?
SELECT DISTINCT specialty_description, opioid_drug_flag, SUM(total_claim_count) AS Total_Claim_Count
FROM prescriber INNER JOIN prescription USING (npi)
				INNER JOIN drug USING (drug_name)
WHERE opioid_drug_flag ='Y'
GROUP BY specialty_description, opioid_drug_flag
ORDER BY Total_Claim_Count DESC
LIMIT 1;
--A: Nurse Practitioner, 900845

-- 2.c. **Challenge Question:** Are there any specialties that appear in the prescriber table that have no associated prescriptions in the prescription table?

--V1
SELECT specialty_description
FROM prescriber LEFT JOIN prescription ON prescriber.npi = prescription.npi
GROUP BY specialty_description
HAVING SUM(total_claim_count) IS NULL;
--A: Yes, 15


-- 2.d. **Difficult Bonus:** *Do not attempt until you have solved all other problems!* For each specialty, report the percentage of total claims by that specialty which are for opioids. Which specialties have a high percentage of opioids?

-- 3.a. Which drug (generic_name) had the highest total drug cost?

SELECT generic_name, SUM(total_drug_cost) AS total_drug_cost
FROM prescription INNER JOIN drug USING (drug_name)
GROUP BY generic_name
ORDER BY total_drug_cost DESC;

--A: generic_name = Insulin Glargine, Hum.REd.anlog

-- 3.b. Which drug (generic_name) has the hightest total cost per day? **Bonus: Round your cost per day column to 2 decimal places. Google ROUND to see how this works.**

SELECT generic_name, ROUND(SUM(total_drug_cost)/SUM(total_day_supply),2)::MONEY AS total_cost_per_day
FROM prescription INNER JOIN drug USING (drug_name)
GROUP BY generic_name
ORDER BY total_cost_per_day DESC
LIMIT 1;

-- 4.a. For each drug in the drug table, return the drug name and then a column named 'drug_type' which says 'opioid' for drugs which have opioid_drug_flag = 'Y', says 'antibiotic' for those drugs which have antibiotic_drug_flag = 'Y', and says 'neither' for all other drugs.

--**Hint:** You may want to use a CASE expression for this. See https://www.postgresqltutorial.com/postgresql-tutorial/postgresql-case/

SELECT drug_name,
		CASE
      		WHEN opioid_drug_flag = 'Y' THEN 'opioid'
      		WHEN antibiotic_drug_flag = 'Y'  THEN 'antibiotic'
      		ELSE 'neither'
		END AS drug_type
FROM drug;

-- 4.b. Building off of the query you wrote for part a, determine whether more was spent (total_drug_cost) on opioids or on antibiotics. Hint: Format the total costs as MONEY for easier comparision.

SELECT drug_type, SUM(total_drug_cost)::MONEY AS total_drug_cost
FROM prescription INNER JOIN  
	(SELECT drug_name,
		CASE
      		WHEN opioid_drug_flag = 'Y' THEN 'opioid'
      		WHEN antibiotic_drug_flag = 'Y'  THEN 'antibiotic'
      		ELSE 'neither'
		END AS drug_type
	FROM drug) AS drug_type_table USING(drug_name)
GROUP BY drug_type
HAVING drug_type <> 'neither';
	
-- 5.a. How many CBSAs are in Tennessee? **Warning:** The cbsa table contains information for all states, not just Tennessee.

SELECT state, COUNT(DISTINCT cbsa) AS no_of_cbsa 
FROM cbsa INNER JOIN fips_county USING (fipscounty)
WHERE fips_county.state IN('TN')
GROUP BY state;


-- 5. b. Which cbsa has the largest combined population? Which has the smallest? Report the CBSA name and total population.

	--5.b.1: largest combined population
	SELECT cbsa, cbsaname, SUM(population) AS combined_population
	FROM cbsa 	INNER JOIN zip_fips USING(fipscounty)
				INNER JOIN population USING (fipscounty)
	GROUP BY cbsa, cbsaname
	ORDER BY combined_population DESC
	LIMIT 1;
	--A: Memphis, TN-MS-AR

	--5.b.2: smallest combined population
	SELECT cbsa, cbsaname, SUM(population) AS combined_population
	FROM cbsa 	INNER JOIN zip_fips USING(fipscounty)
				INNER JOIN population USING (fipscounty)
	GROUP BY cbsa, cbsaname
	ORDER BY combined_population
	LIMIT 1;
	--A: Morristown, TN

-- 5.c. What is the largest (in terms of population) county which is not included in a CBSA? Report the county name and population.

	SELECT fipscounty, county, population, cbsaname
	FROM fips_county INNER JOIN population USING (fipscounty)
					LEFT JOIN CBSA USING (fipscounty)
	WHERE CBSA IS NULL
	ORDER BY population DESC
	LIMIT 1;

	--A: SEVIER, 95,523


-- 6.a. Find all rows in the prescription table where total_claims is at least 3000. Report the drug_name and the total_claim_count.

	SELECT drug_name, total_claim_count
	FROM prescription
	WHERE total_claim_count >=3000;


-- 6.b. For each instance that you found in part a, add a column that indicates whether the drug is an opioid.

	SELECT drug_name, total_claim_count,
		CASE
			WHEN opioid_drug_flag = 'Y' THEN 'opioid'
			ELSE ''
		END AS opioid
	FROM prescription INNER JOIN drug USING (drug_name)
	WHERE total_claim_count >=3000;

-- 6.c. Add another column to you answer from the previous part which gives the prescriber first and last name associated with each row.

	SELECT drug_name, nppes_provider_first_name, nppes_provider_first_name, total_claim_count,
		CASE
			WHEN opioid_drug_flag = 'Y' THEN 'opioid'
			ELSE ''
		END AS opioid
	FROM prescription	INNER JOIN drug USING (drug_name)
						INNER JOIN prescriber USING (npi)
	WHERE total_claim_count >=3000;

-- 7. The goal of this exercise is to generate a full list of all pain management specialists in Nashville and the number of claims they had for each opioid. **Hint:** The results from all 3 parts will have 637 rows.


	-- 7.a. First, create a list of all npi/drug_name combinations for pain management specialists (specialty_description = 'Pain Management) in the city of Nashville (nppes_provider_city = 'NASHVILLE'), where the drug is an opioid (opiod_drug_flag = 'Y'). **Warning:** Double-check your query before running it. You will only need to use the prescriber and drug tables since you don't need the claims numbers yet.
		SELECT NPI, drug_name
		FROM prescriber CROSS JOIN drug
		WHERE specialty_description = 'Pain Management' AND nppes_provider_city ILIKE 'Nashville' AND opioid_drug_flag = 'Y';

-- b. Next, report the number of claims per drug per prescriber. Be sure to include all combinations, whether or not the prescriber had any claims. You should report the npi, the drug name, and the number of claims (total_claim_count).

	SELECT prescriber.npi, drug_name, SUM(total_claim_count) AS total_claim_count
	FROM prescriber		CROSS JOIN drug
						LEFT JOIN prescription USING (drug_name)
	WHERE specialty_description = 'Pain Management' AND nppes_provider_city ILIKE 'Nashville' AND opioid_drug_flag = 'Y'
	GROUP BY prescriber.npi, drug_name
	ORDER BY total_claim_count DESC;
    
--     c. Finally, if you have not done so already, fill in any missing values for total_claim_count with 0. Hint - Google the COALESCE function.

	SELECT prescriber.npi, drug_name, SUM(COALESCE(total_claim_count),0) AS total_claim_count
	FROM prescriber		CROSS JOIN drug
						LEFT JOIN prescription USING (drug_name)
	WHERE specialty_description = 'Pain Management' AND nppes_provider_city ILIKE 'Nashville' AND opioid_drug_flag = 'Y'
	GROUP BY prescriber.npi, drug_name
	ORDER BY total_claim_count DESC;
