SELECT *
FROM SQLDataExplorationProject..CovidDeaths
ORDER BY 3,4


SELECT location, date, total_cases, new_cases, total_deaths, population
FROM SQLDataExplorationProject..CovidDeaths
ORDER BY 1,2


-- total cases vs total deaths
-- likelihood of dying if you interact with covid in your country
SELECT location, date, total_cases, total_deaths,
(CONVERT(FLOAT, total_deaths) / NULLIF(CONVERT(FLOAT, total_cases), 0)) * 100 AS PercentageOfDeaths
FROM SQLDataExplorationProject..CovidDeaths
WHERE location like '%states%'
ORDER BY 1, 2


--total cases vs population
--percentage of population that got covid
SELECT location, date, population, total_cases, total_deaths,
(CONVERT(FLOAT, total_deaths) / NULLIF(CONVERT(FLOAT, total_cases), 0)) * 100 AS PercentageOfDeaths
FROM SQLDataExplorationProject..CovidDeaths
ORDER BY 1, 2


--countries with highest infection rate compared to population
SELECT location, population, 
MAX(CONVERT(FLOAT, total_cases)) AS HighestInfectionCount,
(MAX(CONVERT(FLOAT, total_cases)) / NULLIF(CONVERT(FLOAT, population), 0)) * 100 AS PercentageOfInfection
FROM SQLDataExplorationProject..CovidDeaths
GROUP BY location, population
ORDER BY PercentageOfInfection desc


--countries with highest death count per poplulation
SELECT location, population,
MAX(CONVERT(FLOAT, total_deaths)) AS TotalDeaths
FROM SQLDataExplorationProject..CovidDeaths
GROUP BY location, population
ORDER BY TotalDeaths desc


--for continents having highest death count
SELECT continent,
MAX(CONVERT(FLOAT, total_deaths)) AS TotalDeaths
FROM SQLDataExplorationProject..CovidDeaths
WHERE continent is not null
GROUP BY continent
ORDER BY TotalDeaths desc


--countries with the fastest vaccination rollout
SELECT deaths.location, 
CONVERT(FLOAT, deaths.population) AS population, 
MAX(CONVERT(FLOAT, vaccines.new_vaccinations)) AS MaxDailyVaccinations,
(MAX(CONVERT(FLOAT, vaccines .new_vaccinations)) / NULLIF(CONVERT(FLOAT, deaths.population), 0)) * 100 AS MaxDailyVaccinationPercent
FROM SQLDataExplorationProject..CovidDeaths deaths
JOIN SQLDataExplorationProject..CovidVaccinations vaccines 
ON deaths.location = vaccines.location AND deaths.date = vaccines.date
WHERE deaths.continent IS NOT NULL
GROUP BY deaths.location, deaths.population
ORDER BY MaxDailyVaccinationPercent desc;


--moving average of COVID-19 cases over time
SELECT location, date, 
CONVERT(FLOAT, new_cases) AS new_cases, 
AVG(CONVERT(FLOAT, new_cases)) OVER (PARTITION BY location ORDER BY date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS SevenDayMovingAvg
FROM SQLDataExplorationProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY location, date;


--countries with the most severe COVID-19 effect
SELECT location, 
CONVERT(FLOAT, population) AS population, 
MAX(CONVERT(FLOAT, total_cases)) AS TotalCases, 
MAX(CONVERT(FLOAT, total_deaths)) AS TotalDeaths,
(MAX(CONVERT(FLOAT, total_deaths)) / NULLIF(MAX(CONVERT(FLOAT, total_cases)), 0)) * 100 AS DeathPercent,
(MAX(CONVERT(FLOAT, total_deaths)) / NULLIF(CONVERT(FLOAT, population), 0)) * 100 AS DeathsPerPopulation
FROM SQLDataExplorationProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY DeathsPerPopulation desc;


--global numbers
SELECT 
SUM(CONVERT(FLOAT, new_cases)) AS TotalCases,
SUM(CONVERT(FLOAT, new_deaths)) AS TotalDeaths,
(SUM(CONVERT(FLOAT, new_deaths)) / NULLIF(SUM(CONVERT(FLOAT, new_cases)), 0)) * 100 AS PercentageOfDeaths
FROM SQLDataExplorationProject..CovidDeaths
WHERE continent IS NOT NULL  
ORDER BY 1,2


--total population vs vaccinations
SELECT deaths.continent, deaths.location, deaths.date, deaths.population, vaccines.new_vaccinations,
SUM(CONVERT(INT, vaccines.new_vaccinations)) OVER (PARTITION BY deaths.location ORDER BY deaths.date) AS RollingPeopleVaccinated
FROM SQLDataExplorationProject..CovidDeaths deaths
JOIN SQLDataExplorationProject..CovidVaccinations vaccines
ON deaths.location = vaccines.location
AND deaths.date = vaccines.date
WHERE deaths.continent IS NOT NULL
ORDER BY deaths.location, deaths.date;


--using CTE
WITH PopulationVSVaccination (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated) AS
(
SELECT deaths.continent, deaths.location, deaths.date, 
CONVERT(FLOAT, deaths.population) AS population, 
CONVERT(FLOAT, vaccines.new_vaccinations) AS new_vaccinations,
SUM(CONVERT(FLOAT, vaccines.new_vaccinations)) OVER (
PARTITION BY deaths.location ORDER BY deaths.date) AS RollingPeopleVaccinated
FROM SQLDataExplorationProject..CovidDeaths deaths
JOIN SQLDataExplorationProject..CovidVaccinations vaccines
ON deaths.location = vaccines.location
AND deaths.date = vaccines.date
WHERE deaths.continent IS NOT NULL
)

SELECT *,
(RollingPeopleVaccinated / NULLIF(Population, 0)) * 100 AS PopulationVaccinatedPercent
FROM PopulationVSVaccination;


--TEMP TABLE
DROP TABLE IF EXISTS #PopulationVaccinatedPercent;

CREATE TABLE #PopulationVaccinatedPercent (
Continent NVARCHAR(255),
Location NVARCHAR(255),
Date DATETIME,
Population FLOAT,
New_vaccinations FLOAT,
RollingPeopleVaccinated FLOAT
);

INSERT INTO #PopulationVaccinatedPercent
SELECT 
deaths.continent, 
deaths.location, 
deaths.date, 
CONVERT(FLOAT, deaths.population) AS Population, 
CONVERT(FLOAT, vaccines.new_vaccinations) AS New_vaccinations,
SUM(CONVERT(FLOAT, vaccines.new_vaccinations)) OVER (PARTITION BY deaths.location ORDER BY deaths.date) AS RollingPeopleVaccinated
FROM SQLDataExplorationProject..CovidDeaths deaths
JOIN SQLDataExplorationProject..CovidVaccinations vaccines
ON deaths.location = vaccines.location
AND deaths.date = vaccines.date
WHERE deaths.continent is not null
ORDER BY 2,3;

SELECT *,
(RollingPeopleVaccinated / NULLIF(Population, 0)) * 100 AS PopulationVaccinatedPercent
FROM #PopulationVaccinatedPercent


--creating view to store data for later visualizations
USE SQLDataExplorationProject;
DROP VIEW IF EXISTS PopulationVaccinatedPercent;
GO  

CREATE VIEW PopulationVaccinatedPercent AS
SELECT 
deaths.continent, 
deaths.location, 
deaths.date, 
CONVERT(FLOAT, deaths.population) AS Population, 
CONVERT(FLOAT, vaccines.new_vaccinations) AS New_vaccinations,
SUM(CONVERT(FLOAT, vaccines.new_vaccinations)) OVER (PARTITION BY deaths.location ORDER BY deaths.date) AS RollingPeopleVaccinated
FROM SQLDataExplorationProject..CovidDeaths deaths
JOIN SQLDataExplorationProject..CovidVaccinations vaccines
ON deaths.location = vaccines.location
AND deaths.date = vaccines.date
WHERE deaths.continent IS NOT NULL;
GO  

SELECT *
FROM PopulationVaccinatedPercent;






