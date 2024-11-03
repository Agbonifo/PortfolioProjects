/*
Covid-19 Data Exploration 

Skills used: CTE's, Joins, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types
*/

SELECT *
FROM ProjectDatabase..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 3, 4;


--  Global Cases vs Deaths
-- Shows what percentage of global population infected with Covid AND the likelihood of dying if infected

SELECT MAX(population) As total_population,
    SUM(new_cases) AS total_cases,
    SUM(new_deaths) AS total_deaths,
    (SUM(new_cases) / MAX(population)) * 100 AS case_percent,
    (SUM(new_deaths) / SUM(New_Cases)) * 100 AS deaths_percent
FROM ProjectDatabase..CovidDeaths
WHERE [location] = 'world'

-- Using CTE (Common Table Expression)
WITH GlobalPopulationCasesAndDeaths AS ( 
    SELECT location,
        MAX(population) AS total_population,        
        SUM(new_cases) AS total_cases,      
        SUM(new_deaths) AS total_deaths       
    FROM ProjectDatabase..CovidDeaths                   
    WHERE location = 'world'      
    GROUP BY location       
)  
SELECT *,
    (total_cases / total_population) * 100 AS cases_percent,
    (total_deaths / total_cases) * 100 AS deaths_percent
FROM GlobalPopulationCasesAndDeaths;  



-- Total Cases vs Total Deaths
-- Shows the global weekly likelihood of dying if infected with Covid

WITH WeeklyCasesAndDeaths AS (
    SELECT [date],
        SUM(new_cases) AS new_cases,
        SUM(new_deaths) AS new_deaths
    FROM ProjectDatabase..CovidDeaths
    WHERE [location] = 'world'
    GROUP BY [date]
)
SELECT *,
    (new_deaths / new_cases) * 100 AS deaths_percent
FROM WeeklyCasesAndDeaths
WHERE new_cases != 0
ORDER BY [date] DESC;


-- Total Cases vs Total Deaths vs Population
-- Showing contintents with the highest death count per population

SELECT continent,
    MAX(cumulative_deaths) AS TotalDeathCount
FROM ProjectDatabase..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC


-- Shows what percentage of continent population infected with Covid AND the likelihood of dying if infected

WITH PopulationCasesAndDeathsPerContinent AS (
    SELECT location AS continent,
        MAX(population) AS total_population,
        SUM(new_cases) AS total_cases,
        SUM(new_deaths) AS total_deaths
    FROM ProjectDatabase..CovidDeaths
    WHERE continent IS NULL
        AND location NOT LIKE '%income%'
        AND location NOT LIKE '%world%'
        AND location NOT LIKE '%union%'
    GROUP BY location
)
SELECT *,
    (total_cases / total_population) * 100 AS cases_percent,
    (total_deaths / total_cases) * 100 AS deaths_percent
FROM PopulationCasesAndDeathsPerContinent
ORDER BY deaths_percent DESC;




-- Total Cases vs Total Deaths vs Population
-- Shows what percentage of country population infected with Covid AND the likelihood of dying if infected

WITH PopulationCasesAndDeathsPerCountry AS (
    SELECT location,
        MAX(population) AS total_population,
        SUM(new_cases) AS total_cases,
        SUM(new_deaths) AS total_deaths
    FROM ProjectDatabase..CovidDeaths
    WHERE continent IS NOT NULL
        AND location NOT LIKE '%United Kingdom%'
    GROUP BY location
)
SELECT *,
    (total_cases / total_population) * 100 AS infected_population_percent,
    CASE
        WHEN total_cases IS NULL
        OR total_cases = 0 THEN NULL
        ELSE (total_deaths / total_cases) * 100
    END AS deaths_percent
FROM PopulationCasesAndDeathsPerCountry
ORDER BY deaths_percent DESC;

-- Countries with Highest Infection Rate compared to Population

SELECT Location,
    Population,
    MAX(cumulative_cases) AS HighestInfectionCount,
    Max((cumulative_cases / population)) * 100 AS infected_population_percent
FROM ProjectDatabase..CovidDeaths
GROUP BY Location,
    Population
ORDER BY infected_population_percent DESC


-- Countries with Highest Death Count per Population

SELECT Location,
    MAX(cumulative_deaths) AS TotalDeathCount
FROM ProjectDatabase..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY Location
ORDER BY TotalDeathCount DESC;


-- COVID VACCINATION

SELECT *
FROM ProjectDatabase..CovidVaccinations
WHERE continent IS NOT NULL
    AND people_vaccinated IS NOT NULL
    AND people_vaccinated <> 0
ORDER BY [location];

-- Total Population vs Vaccinations
-- Shows Percentage of Population that has recieved at least one Covid Vaccine

SELECT dea.continent,
    dea.location,
    dea.date,
    dea.population,
    vac.new_vaccinations,
    SUM(vac.new_vaccinations) OVER (
        PARTITION BY dea.Location
        ORDER BY dea.location,
            dea.Date
    ) AS RollingPeopleVaccinated
FROM ProjectDatabase..CovidDeaths dea
    JOIN ProjectDatabase..CovidVaccinations vac ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
    AND people_vaccinated IS NOT NULL
    AND people_vaccinated <> 0
ORDER BY 2,
    3;

With PopvsVac (
    Continent,
    Location,
    Date,
    Population,
    New_Vaccinations,
    RollingPeopleVaccinated
) AS (
    SELECT dea.continent,
        dea.location,
        dea.date,
        dea.population,
        vac.new_vaccinations,
        SUM(vac.new_vaccinations) OVER (
            PARTITION BY dea.Location
            ORDER BY dea.location,
                dea.Date
        ) AS RollingPeopleVaccinated
    FROM ProjectDatabase..CovidDeaths dea
        JOIN ProjectDatabase..CovidVaccinations vac ON dea.location = vac.location
        AND dea.date = vac.date
    WHERE dea.continent IS NOT NULL
        AND people_vaccinated IS NOT NULL
        AND people_vaccinated <> 0
)
SELECT *,
    (RollingPeopleVaccinated / Population) * 100
FROM PopvsVac;


-- Global total tests AND vaccinations

WITH globalTestsAndVaccinations AS (
    SELECT [location],
        SUM(new_tests) AS total_tests,
        MAX(people_vaccinated) AS people_vaccinated,
        MAX(people_fully_vaccinated) AS people_fully_vaccinated
    FROM ProjectDatabase..CovidVaccinations
    WHERE continent IS NOT NULL
        AND people_vaccinated IS NOT NULL
    GROUP BY [location]
)
SELECT MAX(total_tests) AS total_tests,
    SUM(people_vaccinated) AS people_vaccinated,
    SUM(people_fully_vaccinated) AS people_fully_vaccinated
FROM globalTestsAndVaccinations;

-- Using Temp TABLE to perform Calculation on PARTITION By in previous query

DROP TABLE IF EXISTS #VaccinatedPopulationPercent
CREATE TABLE #VaccinatedPopulationPercent
(
    Continent NVARCHAR(255),
    Location NVARCHAR(255),
    Date DATETIME,
    Population NUMERIC,
    New_vaccinations NUMERIC,
    RollingPeopleVaccinated NUMERIC
);

INSERT INTO #VaccinatedPopulationPercent
SELECT dea.continent,
    dea.location,
    dea.date,
    dea.population,
    vac.new_vaccinations,
    SUM(vac.new_vaccinations) OVER (
        PARTITION BY dea.Location
        ORDER BY dea.location,
            dea.Date
    ) AS RollingPeopleVaccinated
FROM ProjectDatabase..CovidDeaths dea
    JOIN ProjectDatabase..CovidVaccinations vac ON dea.location = vac.location
    AND dea.date = vac.date
SELECT *,
    (RollingPeopleVaccinated / Population) * 100
FROM #VaccinatedPopulationPercent;

-- Creating View to store data for later visualizations

CREATE View VaccinatedPopulationPercent AS
SELECT dea.continent,
    dea.location,
    dea.date,
    dea.population,
    vac.new_vaccinations,
    SUM(vac.new_vaccinations) OVER (
        PARTITION BY dea.Location
        ORDER BY dea.location,
            dea.Date
    ) AS RollingPeopleVaccinated
FROM ProjectDatabase..CovidDeaths dea
    JOIN ProjectDatabase..CovidVaccinations vac ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent IS NOT NULL