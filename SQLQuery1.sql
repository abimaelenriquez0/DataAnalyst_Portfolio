SELECT *
FROM CovidProject.dbo.CovidDeaths
--WHERE continent IS NOT NULL
ORDER BY location, date;


--Overview of Data 
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM CovidProject.dbo.CovidDeaths
WHERE continent IS NOT NULL
ORDER BY total_deaths, date;


--BREAKDOWN IN USA

--Total Cases vs Total Deaths (percentage) in USA
--Percentage of population who've died from Covid
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS death_per
FROM CovidProject.dbo.CovidDeaths
WHERE location LIKE '%states%' 
AND continent IS NOT NULL
ORDER BY location, date;

--Total Cases vs Population (percentage) in USA
--Percentage of population who've contracted Covid
SELECT location, date, total_cases, population, (total_cases/population)*100 AS case_per
FROM CovidProject.dbo.CovidDeaths
WHERE location LIKE '%states%'
AND continent IS NOT NULL
ORDER BY location, date;


--BREAKDOWN BY COUNTRY


--Countries with the highest number of Covid infections per population
--(visual)
SELECT location, population, MAX(total_cases) AS highest_infection_count, MAX((total_cases/population)*100) AS percent_infected
FROM CovidProject.dbo.CovidDeaths
WHERE location  NOT IN ('World', 'Upper middle income', 'High income', 'Lower middle income', 'Low income', 
'International', 'Europe', 'North America', 'South America', 'Asia', 'Africa', 'Oceania', 'European Union')
GROUP BY location, population
ORDER BY highest_infection_count DESC;


--Countries with the highest number of Covid deaths per population
SELECT location, population, MAX(CAST(total_deaths AS int)) AS total_death_count, MAX((total_deaths/total_cases)*100) AS death_percentage
FROM CovidProject.dbo.CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY total_death_count DESC;


--Total number of cases and deaths per country
SELECT location, SUM(new_cases) AS total_cases, SUM(CAST (new_deaths AS INT)) AS total_deaths, (SUM(CAST (new_deaths AS INT))/SUM(new_cases))*100 AS death_percentage
FROM CovidProject.dbo.CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY total_cases DESC;


--BREAKDOWN BY CONTINENT


--Death Count by CONTINENT
--(visaul)
SELECT location, SUM(CAST (new_deaths AS INT)) AS total_death_count
FROM CovidProject.dbo.CovidDeaths
WHERE continent IS NULL
AND location NOT IN ('World', 'European Union', 'International', 'Low income', 'Lower middle income', 'Upper middle income', 'High income')
GROUP BY location
ORDER BY total_death_count DESC;



--GLOBAL NUMBERS



--Toal number of cases and deaths across the globe
--(visual)
SELECT SUM(new_cases) AS total_cases, SUM(CAST (new_deaths AS INT)) AS total_deaths, (SUM(CAST (new_deaths AS INT))/SUM(new_cases))*100 AS death_percentage
FROM CovidProject.dbo.CovidDeaths
WHERE continent IS NOT NULL;


--JOINS

--Overview of CovidVaccinations table
SELECT *
FROM CovidProject.dbo.CovidVaccinations;


--INNER JOIN CovidDeaths and CovidVaccinations

SELECT *
FROM CovidProject.dbo.CovidDeaths AS CD
INNER JOIN CovidProject.dbo.CovidVaccinations AS CV
	ON CD.iso_code = CV.iso_code
	AND CD.location = CV.location
	AND CD.date = CV.date;


--Total vaccinations given per country

SELECT CD.location, CD.population, SUM(CAST(CV.new_vaccinations AS BIGINT)) AS total_vaccinations
FROM CovidProject.dbo.CovidDeaths AS CD
INNER JOIN CovidProject.dbo.CovidVaccinations AS CV
	ON CD.iso_code = CV.iso_code
	AND CD.location = CV.location
	AND CD.date = CV.date
WHERE CD.continent IS NOT NULL
	AND new_vaccinations IS NOT NULL
GROUP BY CD.location, CD.population
ORDER BY location;


--Total Populations vs Total Vaccinations Explorations

SELECT CD.continent, CD.location, CD.date, CD.population, CV.new_vaccinations,
	SUM(CONVERT(BIGINT,new_vaccinations)) OVER(PARTITION BY CD.location ORDER BY CD.location, CD.date) AS running_total_vaccination
FROM CovidProject.dbo.CovidDeaths AS CD
INNER JOIN CovidProject.dbo.CovidVaccinations AS CV
	ON CD.iso_code = CV.iso_code
	AND CD.location = CV.location
	AND CD.date = CV.date
WHERE CD.continent IS NOT NULL
ORDER BY CD.location, CD.date;


--Use of CTE

WITH PopVsVac AS (
	SELECT CD.continent, CD.location, CD.date, CD.population, CV.new_vaccinations,
	SUM(CONVERT(BIGINT,new_vaccinations)) OVER(PARTITION BY CD.location ORDER BY CD.location, CD.date) AS rolling_total_vaccination
FROM CovidProject.dbo.CovidDeaths AS CD
INNER JOIN CovidProject.dbo.CovidVaccinations AS CV
	ON CD.iso_code = CV.iso_code
	AND CD.location = CV.location
	AND CD.date = CV.date
WHERE CD.continent IS NOT NULL)

SELECT *, (rolling_total_vaccination/population)*100 AS rolling_per_vac
FROM PopVsVac;


--Use of TEMP TABLE
DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
rolling_per_vac numeric
)
INSERT INTO #PercentPopulationVaccinated
SELECT CD.continent, CD.location, CD.date, CD.population, CV.new_vaccinations,
	SUM(CONVERT(BIGINT,new_vaccinations)) OVER(PARTITION BY CD.location ORDER BY CD.location, CD.date) AS rolling_total_vaccination
FROM CovidProject.dbo.CovidDeaths AS CD
INNER JOIN CovidProject.dbo.CovidVaccinations AS CV
	ON CD.iso_code = CV.iso_code
	AND CD.location = CV.location
	AND CD.date = CV.date
WHERE CD.continent IS NOT NULL


--Creating VIEW to store data later for visualization

CREATE VIEW PercentPopulationVaccinated AS
SELECT CD.continent, CD.location, CD.date, CD.population, CV.new_vaccinations,
	SUM(CONVERT(BIGINT,new_vaccinations)) OVER(PARTITION BY CD.location ORDER BY CD.location, CD.date) AS rolling_total_vaccination
FROM CovidProject.dbo.CovidDeaths AS CD
INNER JOIN CovidProject.dbo.CovidVaccinations AS CV
	ON CD.iso_code = CV.iso_code
	AND CD.location = CV.location
	AND CD.date = CV.date
WHERE CD.continent IS NOT NULL;


SELECT *
FROM PercentPopulationVaccinated



