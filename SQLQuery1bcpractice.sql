Select Location, date,population, total_cases, (total_cases / population) * 100 AS PercentagePoluationEffected
From projects.dbo.CovidDeaths1$
--Where location = ' india '
Order by 1,2 


--looking at countries with highest infection rate compared to population
Select Location,population, MAX(total_cases) AS HighestInfectionCount, MAX((total_cases / population)) * 100 AS PercentagePoluationEffected 
From projects.dbo.CovidDeaths1$
--Where location = ' india '
Group by Location,population
Order by PercentagePoluationEffected DESC

-- showing countries with highest death count per population
SELECT location, MAX(cast(total_deaths as int)) as TotalDeathCount
From projects.dbo.CovidDeaths1$
Group by location
order by TotalDeathCount desc

--SELECT * 
--FROM projects.dbo.CovidDeaths1$

--by location
SELECT location, MAX(cast(total_deaths as int)) as TotalDeathCount
From projects.dbo.CovidDeaths1$
where continent is null
Group by location
order by TotalDeathCount desc

--by continent
SELECT continent, MAX(cast(total_deaths as int)) as TotalDeathCount
From projects.dbo.CovidDeaths1$
where continent is not null
Group by continent
order by TotalDeathCount desc

--showing continents with the highest death count per population 

SELECT continent, MAX(cast(total_deaths as int)) as TotalDeathCount
From projects.dbo.CovidDeaths1$
where continent is not null
Group by continent
order by TotalDeathCount desc

--breaking global numbers

Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/ SUM(new_cases) * 100 as DeathPercentage
From projects.dbo.CovidDeaths1$
--Where location like '%states%'
Where continent is not null
--Group by Date
order by 1,2

-- breaking global numbers by date 
Select date, SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/ SUM(new_cases) * 100 as DeathPercentage
From projects.dbo.CovidDeaths1$
--Where location like '%states%'
Where continent is not null
Group by date
order by 1,2

--Select *
--from projects.dbo.CovidVaccine1$\

-- total population vs vaccination
Select dea.continent,dea.location, dea.date, dea.population, vac.new_Vaccinations,
SUM(cast(vac.new_Vaccinations as int)) OVER (Partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
From projects.dbo.CovidDeaths1$ dea
JOIN projects.dbo.covidVaccinations vac
	ON dea.location = vac.location
	and dea.date = vac.date
Where dea.continent is not null
order by 2,3

-- USE CTE

With popvsvac (continent,Location, Date, Population, new_Vaccinations, RollingPeopleVaccinated)
as
(Select dea.continent,dea.location, dea.date, dea.population, vac.new_Vaccinations,
SUM(cast(vac.new_Vaccinations as int)) OVER (Partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
From projects.dbo.CovidDeaths1$ dea
JOIN projects.dbo.covidVaccinations vac
	ON dea.location = vac.location
	and dea.date = vac.date
Where dea.continent is not null
--order by 2,3
)
Select *, (RollingPeopleVaccinated/Population * 100) as percentageOfPeopleVAC
From popvsvac





---temp table--
DROP Table if exists #percentagePopulationVaccinated
Create Table #percentagePopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
population numeric,
new_vaccination numeric,
RollingPeopleVaccinated numeric
)

Insert into #PercentagePopulationVaccinated
Select dea.continent,dea.location, dea.date, dea.population, vac.new_Vaccinations,
SUM(cast(vac.new_Vaccinations as int)) OVER (Partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
From projects.dbo.CovidDeaths1$ dea
JOIN projects.dbo.covidVaccinations vac
	ON dea.location = vac.location
	and dea.date = vac.date
--Where dea.continent is not null
--order by 2,3
Select *, (RollingPeopleVaccinated/Population * 100) as percentageOfPeopleVAC
From #PercentagePopulationVaccinated

-- Creating view to store data later visualizations --
--Drop view if exists PercentagePopulationVaccinated
Create View  PercentagePopulationVaccinated as
Select dea.continent,dea.location, dea.date, dea.population, vac.new_Vaccinations,
SUM(cast(vac.new_Vaccinations as int)) OVER (Partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
From projects.dbo.CovidDeaths1$ dea
JOIN projects.dbo.covidVaccinations vac
	ON dea.location = vac.location
	and dea.date = vac.date
Where dea.continent is not null
--order by 2,3
--view
SELECT * FROM PercentagePopulationVaccinated


-- create another view--

-- Create the table
Drop table if exists popvsvac
CREATE TABLE #popvsvac
(
    Continent nvarchar(255),
    Location nvarchar(255),
    Date datetime,
    Population numeric,
    New_Vaccinations numeric,
    RollingPeopleVaccinated numeric
);

-- Insert data into the table using a CTE
WITH VaccinationData AS
(
    SELECT 
        dea.continent,
        dea.location, 
        dea.date, 
        dea.population, 
        TRY_CAST(vac.new_vaccinations AS int) AS new_vaccinations, -- Ensure compatibility
        SUM(TRY_CAST(vac.new_vaccinations AS int)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
    FROM 
        projects.dbo.CovidDeaths1$ dea
    JOIN 
        projects.dbo.covidVaccinations vac
        ON dea.location = vac.location
        AND dea.date = vac.date
    WHERE 
        dea.continent IS NOT NULL
)
INSERT INTO #popvsvac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
SELECT 
    Continent,
    Location,
    Date,
    Population,
    New_Vaccinations,
    RollingPeopleVaccinated
FROM 
    VaccinationData;

-- Creating view to store data later visualizations --
--create view for popvsvac ---
--Drop view if exists popvsvac
Create View  popvsvac as
SELECT 
        dea.continent,
        dea.location, 
        dea.date, 
        dea.population, 
        TRY_CAST(vac.new_vaccinations AS numeric) AS new_vaccinations, -- Ensure compatibility
        SUM(TRY_CAST(vac.new_vaccinations AS numeric)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
    FROM 
        projects.dbo.CovidDeaths1$ dea
    JOIN 
        projects.dbo.covidVaccinations vac
        ON dea.location = vac.location
        AND dea.date = vac.date
    WHERE 
        dea.continent IS NOT NULL
--view
Select * 
from popvsvac
