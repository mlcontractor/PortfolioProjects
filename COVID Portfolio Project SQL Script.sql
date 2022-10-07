-- View data
Select *
From PortfolioProject..CovidDeaths
order by 3,4

-- Select the data that is going to be used
Select Location, date, total_cases, new_cases, total_deaths, population
From PortfolioProject..CovidDeaths
order by 1,2

-- Look at Total Cases vs Total Deaths
-- Shows the likelihood of dying if a person were to contract Covid
Select Location, date, total_cases, total_deaths, (total_deaths/total_cases) * 100 as DeathPercentage
From PortfolioProject..CovidDeaths
Where location like '%states%'
order by 1,2

-- Look at Total Cases vs Population
-- Shows what percentage of the population contracted Covid
Select Location, date, population, total_cases, (total_cases/population) * 100 as PercentInfected
From PortfolioProject..CovidDeaths
Where location like '%states%'
order by 1,2

-- Show the countries with the highest infection rate
Select Location, population, MAX(total_cases) as HighestInfectionCount, (MAX(total_cases)/population) * 100 as PercentInfected
From PortfolioProject..CovidDeaths
--Where location like '%states%'
group by location, population
order by PercentInfected desc

-- Show countries with Highest Death Count per capita
-- Total_deaths is a varchar. To get the correct calculation, cast as int
Select Location, MAX(cast(total_deaths as int)) as TotalDeathCount
From PortfolioProject..CovidDeaths
Where continent is not null
group by location
order by TotalDeathCount desc

-- Show the highest Death Count by continent
-- Question: Does N. America include the data from Canada?
-- Use this one for Tableau
Select continent, MAX(cast(total_deaths as int)) as TotalDeathCount
From PortfolioProject..CovidDeaths
Where continent is not null
group by continent
order by TotalDeathCount desc

-- Use this query instead if you want more accurate data for highest death count by continent
Select location, MAX(cast(total_deaths as int)) as TotalDeathCount
From PortfolioProject..CovidDeaths
Where continent is null
group by location
order by TotalDeathCount desc


-- Global numbers
Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(new_cases)*100 as DeathPercentage
From PortfolioProject..CovidDeaths
where continent is not null
order by 1,2

-- Show Total Population Vs Vaccinations
-- How many people in the world have been vaccinated? Look at dates when countries began to vaccinate.
select d.continent, d.location, d.date, d.population, v.new_vaccinations
from PortfolioProject..CovidDeaths d
join PortfolioProject..CovidVaccinations v
	on d.location = v.location
	and d.date = v.date
where d.continent is not null
order by 2,3

-- Add a cumulative sum for new_vaccinations grouped by location
-- This will only sum by location and will not provide a real cumulative sum in the results
select d.continent, d.location, d.date, d.population, v.new_vaccinations
, SUM(cast(v.new_vaccinations as bigint)) OVER (Partition by d.location) as total_new_vax
from PortfolioProject..CovidDeaths d
join PortfolioProject..CovidVaccinations v
	on d.location = v.location
	and d.date = v.date
where d.continent is not null
order by 2,3

-- Add a cumulative sum for new_vaccinations grouped by location and date
select d.continent, d.location, d.date, d.population, v.new_vaccinations
, SUM(cast(v.new_vaccinations as bigint)) OVER (Partition by d.location order by d.location, 
	d.date) as RollingPeopleVaccinated
from PortfolioProject..CovidDeaths d
join PortfolioProject..CovidVaccinations v
	on d.location = v.location
	and d.date = v.date
where d.continent is not null
order by 2,3

-- Percentage of people getting vaccinated
-- RPV cannot be used here. A CTE or temp table must be used.
select d.continent, d.location, d.date, d.population, v.new_vaccinations
, SUM(cast(v.new_vaccinations as bigint)) OVER (Partition by d.location order by d.location, 
	d.date) as RollingPeopleVaccinated
from PortfolioProject..CovidDeaths d
join PortfolioProject..CovidVaccinations v
	on d.location = v.location
	and d.date = v.date
where d.continent is not null
order by 2,3

-- Using a CTE
-- If the number of columns in the CTE doesn't match what's in the query, it will throw an error. Added "New_Vaccinations"
With PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as
(
select d.continent, d.location, d.date, d.population, v.new_vaccinations
, SUM(cast(v.new_vaccinations as bigint)) OVER (Partition by d.location order by d.location, 
	d.date) as RollingPeopleVaccinated
from PortfolioProject..CovidDeaths d
join PortfolioProject..CovidVaccinations v
	on d.location = v.location
	and d.date = v.date
where d.continent is not null
--order by 2,3 CANNOT USE ORDER BY IN SUBQUERIES
)
select *, (RollingPeopleVaccinated/Population)*100 AS RollingPercentVaccinated
from PopvsVac

-- Using a temporary table
DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_Vaccinations numeric,
RollingPeopleVaccinated numeric
)
Insert into #PercentPopulationVaccinated
select d.continent, d.location, d.date, d.population, v.new_vaccinations
, SUM(cast(v.new_vaccinations as bigint)) OVER (Partition by d.location order by d.location, 
	d.date) as RollingPeopleVaccinated
from PortfolioProject..CovidDeaths d
join PortfolioProject..CovidVaccinations v
	on d.location = v.location
	and d.date = v.date
where d.continent is not null

select *, (RollingPeopleVaccinated/Population)*100 AS RollingPercentVaccinated
from #PercentPopulationVaccinated

-- Create a View to store data for visualizations
Use PortfolioProject -- statement added because my view did not go into PortfolioProject
GO
Create View PercentPopulationVaccinated	as
select d.continent, d.location, d.date, d.population, v.new_vaccinations
, SUM(cast(v.new_vaccinations as bigint)) OVER (Partition by d.location order by d.location, 
	d.date) as RollingPeopleVaccinated
from PortfolioProject..CovidDeaths d
join PortfolioProject..CovidVaccinations v
	on d.location = v.location
	and d.date = v.date
where d.continent is not null

-- Now you can query the view
select *
from PercentPopulationVaccinated
