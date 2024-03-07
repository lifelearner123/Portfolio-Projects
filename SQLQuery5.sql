SELECT *
FROM [Portfolio Project ]..CovidDeaths$
where continent is not null
Order by 3,4


--SELECT *
--FROM [Portfolio Project ]..CovidVaccinations$
--Order by 3,4

--Select Data that we are going to be using 

Select location, date, total_cases, new_cases, population 
FROM [Portfolio Project ]..CovidDeaths$
where continent is not null
Order by 1,2

--Looking at Total Cases Vs Total Deaths (  % of people diagoned vs dies)
--Shows likelihood of dying if you contract covid in your country 
Select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage 
FROM [Portfolio Project ]..CovidDeaths$
where continent is not null
Where location like '%states%'
Order by 1,2 

--Looking at Total Cases Vs Population 
--Shows what percentage of population got covid 
Select location, date, population, total_cases, (total_cases/population)*100 as PercentPopulation 
FROM [Portfolio Project ]..CovidDeaths$
Where location like '%states%' and continent is not null
Order by 1,2 

--Looking at countries with highest infection rate compared to poplation 
--Only looking at the highest ones not everthing like what countries had highest covid infections in proportion to pop
Select location, population, Max (total_cases)as HighestInfectionCount, Max((total_cases/population))*100 as PercentPopulationInfected 
FROM [Portfolio Project ]..CovidDeaths$
--Where location like '%states%'
Group By location, population
Order by PercentPopulationInfected desc

--LOOKING AT SPECIFIC CONTIENT AND COUNTRIES UNDER IT WITH HIGHEST INFECTION RATE COMP TO POP ( DRILL DOWN)

Select continent, location, population, Max (total_cases)as HighestInfectionCount, Max((total_cases/population))*100 as PercentPopulationInfected 
FROM [Portfolio Project ]..CovidDeaths$
--Where location like '%states%'
Where Continent is not null
Group By continent, location, population
Order by continent,HighestInfectionCount Desc
--DRILLING IT DOWN TO SPECIFIC CONTINENT AND COUNTRIES 

Select continent, location, population, Max (total_cases)as HighestInfectionCount, Max((total_cases/population))*100 as PercentPopulationInfected 
FROM [Portfolio Project ]..CovidDeaths$
Where continent like '%Asia%' and Continent is not null
Group By continent, location, population
Order by continent,HighestInfectionCount Desc



--Showing countries with the highest death count per Population 
Select location, Max(cast (total_deaths as int))as TotalDeathCount  
FROM [Portfolio Project ]..CovidDeaths$
where continent is not null
--Where location like '%states%'
Group By location
Order by TotalDeathCount desc

--LETS BREAK THINGS DOWN BY CONTINENT 
Select continent, Max(cast (total_deaths as int))as TotalDeathCount  
FROM [Portfolio Project ]..CovidDeaths$
where continent is not null
--Where location like '%states%'
Group By continent
Order by TotalDeathCount desc

-- THESE NOS ARE MORE ACCUARATE WITH CONTINENT BEING NULL AND SELECTING WITH LOCATIION
Select location, Max(cast (total_deaths as int))as TotalDeathCount  
FROM [Portfolio Project ]..CovidDeaths$
where continent is null
--Where location like '%states%'
Group By location
Order by TotalDeathCount desc

 --GLOBAL NUMBERS 
 -- This will give error as we are grouping only by date while we hv other field in select and need to run aggrgate on all 
Select date, total_cases,total_deaths, (total_deaths/total_cases)*100 as DeathPercentage 
FROM [Portfolio Project ]..CovidDeaths$
where continent is not null
Group by date
--Where location like '%states%'
Order by 1,2 

-- TRY WITH AGGREGATE FUNCTIONS WITHIN AGGREGATE FUNCTION WONT WORK 
Select date, sum(max(total_cases)) --,total_deaths, (total_deaths/total_cases)*100 as DeathPercentage 
FROM [Portfolio Project ]..CovidDeaths$
where continent is not null
Group by date
--Where location like '%states%'
Order by 1,2 

--TRY WITH JUST ONE AGGREGATE 
Select date, sum(new_cases) as total_cases, sum(cast(new_deaths as int)) as total_deaths,sum(cast(new_deaths as int))/Sum (new_cases)*100 as DeathPercentage --,total_deaths, (total_deaths/total_cases)*100 as DeathPercentage 
FROM [Portfolio Project ]..CovidDeaths$
where continent is not null
Group by date
--Where location like '%states%'
Order by 1,2 

--IF WE REMOVE THE DATE WE GET TO KNOW THE TOTAL GLOBAL DEATH PERCENTAGE 
Select sum(new_cases) as total_cases, sum(cast(new_deaths as int)) as total_deaths,sum(cast(new_deaths as int))/Sum (new_cases)*100 as DeathPercentage
FROM [Portfolio Project ]..CovidDeaths$
where continent is not null
Order by 1,2 

--DATA ON VACCINATIN COMBINED WITH DEATHS 


SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
--Partition is used to make sure that aggregate sum functions don't keep running over and gets restarted with new location 
, Sum(cast(vac.new_vaccinations as int)) Over ( Partition by  dea.location Order by dea.location, dea.date) as  RollingPeopleVaccinated 
FROM [Portfolio Project ]..CovidDeaths$ dea
JOIN [Portfolio Project ]..CovidVaccinations$ vac
On dea.location=vac.location
and dea.date=vac.date
Where dea.continent is not null
order by 2,3

 --IF WE WANT TO LOOK AT THE TOTAL POP VS VACCINATION AND USE THIS TOT PPL VACCINATED BY USING THAT NO AND DIVIDE BY POP 
 --WE GET ERROR AS WE CAN'T USE COLUMN NAME JUST CREATED 

 SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, Sum(cast(vac.new_vaccinations as int)) Over ( Partition by  dea.location Order by dea.location, dea.date) as  RollingPeopleVaccinated 
, (RollingPeopleVaccinated/population)*100
FROM [Portfolio Project ]..CovidDeaths$ dea
JOIN [Portfolio Project ]..CovidVaccinations$ vac
On dea.location=vac.location
and dea.date=vac.date
Where dea.continent is not null
order by 2,3

--THEREFORE WE ARE GOING TO USE CTE 

With PopvsVac ( Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as
(SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, Sum(cast(vac.new_vaccinations as int)) Over ( Partition by  dea.location Order by dea.location, dea.date) as  RollingPeopleVaccinated 
FROM [Portfolio Project ]..CovidDeaths$ dea
JOIN [Portfolio Project ]..CovidVaccinations$ vac
On dea.location=vac.location
and dea.date=vac.date
Where dea.continent is not null )
--order by 2,3
Select *, RollingPeopleVaccinated/population 
FROM PopvsVac

--TEMP TABLE 
Create Table #PercentPopulationVaccinated 
(Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric,
)
Insert into #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, Sum(cast(vac.new_vaccinations as int)) Over ( Partition by  dea.location Order by dea.location, dea.date) as  RollingPeopleVaccinated 
FROM [Portfolio Project ]..CovidDeaths$ dea
JOIN [Portfolio Project ]..CovidVaccinations$ vac
On dea.location=vac.location
and dea.date=vac.date
Where dea.continent is not null 
--order by 2,3

Select *
FROM #PercentPopulationVaccinated

--IF WE WANT TO MAKE ANY ALTERATIONS TO YOUR INSERT DATA IN TEMP TABLE FOR EXAMPLE REMOVE WHERE CONTINENT IS NOT NULL YOU WOULD GET AN ERROR 
Create Table #PercentPopulationVaccinated 
(Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric,
)
Insert into #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, Sum(cast(vac.new_vaccinations as int)) Over ( Partition by  dea.location Order by dea.location, dea.date) as  RollingPeopleVaccinated 
FROM [Portfolio Project ]..CovidDeaths$ dea
JOIN [Portfolio Project ]..CovidVaccinations$ vac
On dea.location=vac.location
and dea.date=vac.date
--Where dea.continent is not null 
--order by 2,3

Select *
FROM #PercentPopulationVaccinated

--TO AVOID THAT WE DO DROP TABLE IF EXIST 

Drop Table IF Exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated 
(Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric,
)
Insert into #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, Sum(cast(vac.new_vaccinations as int)) Over ( Partition by  dea.location Order by dea.location, dea.date) as  RollingPeopleVaccinated 
FROM [Portfolio Project ]..CovidDeaths$ dea
JOIN [Portfolio Project ]..CovidVaccinations$ vac
On dea.location=vac.location
and dea.date=vac.date
--Where dea.continent is not null 
--order by 2,3

Select *
FROM #PercentPopulationVaccinated

--CREATE VIEW 
--CREATING VIEW TO STORE DATA FOR LATER VUSUALIZATIONS 

Create View PercentPopulationVaccinated As
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, Sum(cast(vac.new_vaccinations as int)) Over ( Partition by  dea.location Order by dea.location, dea.date) as  RollingPeopleVaccinated 
FROM [Portfolio Project ]..CovidDeaths$ dea
JOIN [Portfolio Project ]..CovidVaccinations$ vac
On dea.location=vac.location
and dea.date=vac.date
Where dea.continent is not null 
--order by 2,3



Create View DeathPercentage As
Select date, total_cases,total_deaths, (total_deaths/total_cases)*100 as DeathPercentage 
FROM [Portfolio Project ]..CovidDeaths$
where continent is not null

--Where location like '%states%'
--Order by 1,2 

Select *
From DeathPercentage
