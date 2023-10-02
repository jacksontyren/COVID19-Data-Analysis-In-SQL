-- Select Data that we are going to be using.
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM coviddeaths
ORDER BY location, date;


-- Change date column data type from text to the DATE data type.

ALTER TABLE coviddeaths
ALTER COLUMN date TYPE DATE
USING TO_DATE(date, 'MM/DD/YY');

ALTER TABLE covidvaccinations
ALTER COLUMN date TYPE DATE
USING TO_DATE(date, 'MM/DD/YY');


-- Looking at the Total Cases vs Total Deaths

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases) * 100 AS death_percentage
FROM coviddeaths
WHERE location ILIKE '%state%' AND continent IS NOT NULL
ORDER BY location, date


-- Looking at the Total Cases vs Population

SELECT location, date, total_cases, population, (total_cases/population) * 100 AS infected_percentage
FROM coviddeaths
WHERE location ILIKE '%state%' AND continent IS NOT NULL
ORDER BY location, date

-- Looking at Countries with Highest Infection Rate Compared to Population

SELECT location, MAX(total_cases) AS highest_infection_count, population, MAX((total_cases/population)) * 100 AS infected_percentage
FROM coviddeaths
WHERE (total_cases, population) IS NOT NULL AND continent IS NOT NULL
GROUP BY location, population
ORDER BY infected_percentage DESC


-- Showing the countries with the Highest Death Count

SELECT location, MAX(total_deaths) AS highest_death_count
FROM coviddeaths
WHERE (total_deaths, population) IS NOT NULL AND continent IS NOT NULL
GROUP BY location
ORDER BY highest_death_count DESC


-- Showing the continent with the Highest Death Count

SELECT location, MAX(total_deaths) AS highest_death_count
FROM coviddeaths
WHERE continent IS NULL
GROUP BY location
ORDER BY highest_death_count DESC


-- Global Numbers

SELECT date, SUM(new_cases) AS total_cases, SUM(new_deaths) AS total_deaths, 
SUM(new_deaths)/SUM(new_cases) * 100 AS deathpercentage
FROM coviddeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY date


--Looking at Total Poulation vs Vaccinations
--Joining coviddeaths and covidvaccinations tables
--Use of Common Table Expression, CTE

WITH pop_vs_vac AS (
	SELECT cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations,
	SUM(cv.new_vaccinations) OVER (PARTITION BY cd.location ORDER BY cd.location, cd.date) AS rolling_sum_vaccinations
	FROM coviddeaths cd INNER JOIN covidvaccinations cv ON cd.location = cv.location
	AND cd.date = cv.date
	WHERE cd.continent IS NOT NULL
	ORDER BY cd.location, cd.date
)
SELECT *, (rolling_sum_vaccinations / population) * 100 AS rolling_percent_vaccinated
FROM pop_vs_vac


--To-Date Percent of People Vaccinated by Location
WITH pop_vs_vac AS (
	SELECT cd.continent, cd.location, cd.population, cv.new_vaccinations,
	SUM(cv.new_vaccinations) OVER (PARTITION BY cd.location ORDER BY cd.location, cd.date) AS rolling_sum_vaccinations
	FROM coviddeaths cd INNER JOIN covidvaccinations cv ON cd.location = cv.location
	AND cd.date = cv.date
	WHERE cd.continent IS NOT NULL
	ORDER BY cd.location, cd.date
)
SELECT location, MAX((rolling_sum_vaccinations / population)) * 100 AS current_percent_vaccinated
FROM pop_vs_vac
GROUP BY location 


--Creating Views from previous queries to store data for later vizualizations

--Rolling count of population vaccinated
CREATE VIEW rolling_population_vaccinated AS
	(SELECT cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations,
	SUM(cv.new_vaccinations) OVER (PARTITION BY cd.location ORDER BY cd.location, cd.date) AS rolling_sum_vaccinations
	FROM coviddeaths cd INNER JOIN covidvaccinations cv ON cd.location = cv.location
	AND cd.date = cv.date
	WHERE cd.continent IS NOT NULL
	ORDER BY cd.location, cd.date);
	

--Total percent of population vaccinated
CREATE VIEW percent_population_vaccinated AS (
	WITH pop_vs_vac AS (
		SELECT cd.continent, cd.location, cd.population, cv.new_vaccinations,
		SUM(cv.new_vaccinations) OVER (PARTITION BY cd.location ORDER BY cd.location, cd.date) AS rolling_sum_vaccinations
		FROM coviddeaths cd INNER JOIN covidvaccinations cv ON cd.location = cv.location
		AND cd.date = cv.date
		WHERE cd.continent IS NOT NULL
		ORDER BY cd.location, cd.date
	)
SELECT location, MAX((rolling_sum_vaccinations / population)) * 100 AS current_percent_vaccinated
FROM pop_vs_vac
GROUP BY location )


--Death rate
CREATE VIEW death_percentage AS(
	SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases) * 100 AS death_percentage
	FROM coviddeaths
	WHERE location ILIKE '%state%' AND continent IS NOT NULL
	ORDER BY location, date);


--Percent of populationon infected
CREATE VIEW percent_pop_infected AS (
	SELECT location, date, total_cases, population, (total_cases/population) * 100 AS infected_percentage
	FROM coviddeaths
	WHERE location ILIKE '%state%' AND continent IS NOT NULL
	ORDER BY location, date);
	

--Total death count
CREATE VIEW death_toll_by_continent AS (
	SELECT location, MAX(total_deaths) AS highest_death_count
	FROM coviddeaths
	WHERE continent IS NULL
	GROUP BY location
	ORDER BY highest_death_count DESC)
	


