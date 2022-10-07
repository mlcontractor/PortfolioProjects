Select *
From PortfolioProject..CovidDeaths
order by 3,4

-- Select the data that is going to be used
Select Location, date, total_cases, new_cases, total_deaths, population
From PortfolioProject..CovidDeaths
order by 1,2

-- Look at Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract Covid
Select Location, date, total_cases, total_deaths, (total_deaths/total_cases) * 100 as DeathPercentage
From PortfolioProject..CovidDeaths
Where location like '%states%'
order by 1,2

-- Look at Total Cases vs Population
-- Shows what percentage of population contracted Covid
Select Location, date, population, total_cases, (total_cases/population) * 100 as PercentInfected
From PortfolioProject..CovidDeaths
Where location like '%states%'
order by 1,2

-- Showing countries with the highest infection rate
Select Location, population, MAX(total_cases) as HighestInfectionCount, (MAX(total_cases)/population) * 100 as PercentInfected
From PortfolioProject..CovidDeaths
--Where location like '%states%'
group by location, population
order by PercentInfected desc

-- Showing countries with Highest Death Count per person
-- total_deaths is a varchar. To get the correct calculation, cast it as int
Select Location, MAX(cast(total_deaths as int)) as TotalDeathCount
From PortfolioProject..CovidDeaths
Where continent is not null
group by location
order by TotalDeathCount desc

-- Highest Death County by continent
-- Does N. America include the data from Canada?
-- Use this one for Tableau
Select continent, MAX(cast(total_deaths as int)) as TotalDeathCount
From PortfolioProject..CovidDeaths
Where continent is not null
group by continent
order by TotalDeathCount desc

-- Use this query instead if you want more accurate data
Select location, MAX(cast(total_deaths as int)) as TotalDeathCount
From PortfolioProject..CovidDeaths
Where continent is null
group by location
order by TotalDeathCount desc

-- Continents with the highest death count per capita

-- Global numbers
Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(new_cases)*100 as DeathPercentage
From PortfolioProject..CovidDeaths
--Where location like '%states%'
where continent is not null
--group by date
order by 1,2

-- Looking at Total Population Vs Vaccinations
-- How many people in the world have been vaccinated? Look at dates when countries began to vax.
select d.continent, d.location, d.date, d.population, v.new_vaccinations
from PortfolioProject..CovidDeaths d
join PortfolioProject..CovidVaccinations v
	on d.location = v.location
	and d.date = v.date
where d.continent is not null
order by 2,3

-- Add a cumulative sum for new_vaccinations grouped by location
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
	d.date) as rollingPeopleVaccinated
from PortfolioProject..CovidDeaths d
join PortfolioProject..CovidVaccinations v
	on d.location = v.location
	and d.date = v.date
where d.continent is not null
order by 2,3

-- Percentage of people getting vaccinated
-- If you try to use RPV here, it wont let you. You need to either use CTE or temp table
select d.continent, d.location, d.date, d.population, v.new_vaccinations
, SUM(cast(v.new_vaccinations as bigint)) OVER (Partition by d.location order by d.location, 
	d.date) as RollingPeopleVaccinated
from PortfolioProject..CovidDeaths d
join PortfolioProject..CovidVaccinations v
	on d.location = v.location
	and d.date = v.date
where d.continent is not null
order by 2,3

-- CTE
-- If the # of columns in CTE doesn't match query, will throw an error. Added "New_Vaccinations"
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

-- TEMP TABLE
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

-- Creating View to store data for visualizations
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
