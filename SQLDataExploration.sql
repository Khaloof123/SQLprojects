
SET ARITHABORT OFF 
SET ANSI_WARNINGS OFF
--data cleaning
ALTER TABLE Covidcases ADD Totalcases REAL;
ALTER TABLE Covidcases ADD Totaldeaths REAL;
ALTER TABLE Covidcases ADD pop REAL;
ALTER TABLE Covidcases ADD pop2 DECIMAL;
ALTER TABLE Covidcases ADD newcases REAL;
ALTER TABLE Covidcases ADD newdeaths REAL;

UPDATE Covidcases SET Totalcases = CAST(Total_cases AS REAL);
UPDATE Covidcases SET Totaldeaths = CAST(Total_deaths AS REAL);
UPDATE Covidcases SET pop = CAST(population AS REAL);
UPDATE Covidcases SET Test = CAST(Total_deaths AS REAL);
UPDATE Covidcases SET pop2 = CAST(pop AS DECIMAL);
UPDATE Covidcases SET newcases = CAST(new_cases AS REAL);
UPDATE Covidcases SET newdeaths = CAST(new_deaths AS REAL);

select Covidvaccine set newvaccinations = 0 where newvaccinations = null;

update Coviddeaths set Total_deaths = 0 where Total_deaths = ' ';
select total_deaths from Coviddeaths
select newvaccinations from covidvaccine
SELECT NULLIF(newvaccinations, 0) AS newvaccinations FROM whatever

--1. exploration
select * from coviddeaths

-- 2. finding the percentage of death when contracting covid per country
Select location, date, totalcases, total_deaths, (total_deaths / totalcases) *100 as DeathPercentage from Coviddeaths order by 1,2 

-- 3. percentage of population contracting covid per country
Select Location, date, Population, totalcases,  (totalcases/population)*100 as PercentPopulationInfected
From coviddeaths
Where continent != ' ' 
and location not in ('World', 'European Union', 'International')
order by 1,2



-- 4. Highest infections per country
Select Location, Population, MAX(totalcases) as HighestInfectionCount,  Max((totalcases/population))*100 as PercentPopulationInfected
From Coviddeaths
Where continent != ' ' 
and location not in ('World', 'European Union', 'International')
Group by Location, Population
order by PercentPopulationInfected desc

-- 5. continental numbers
Select distinct continent, MAX(cast(total_deaths as real)) as TotalDeathCount
From covidcases
WHERE continent != ' '
and location not in ('World', 'European Union', 'International')
Group by continent
order by TotalDeathCount desc


-- 6. total percentage population infected per country
select totaldeaths from coviddeaths

Select Location, Population, MAX(totalcases) as HighestInfectionCount, max (totalcases / NULLIF(pop,0) *100) as PercentPopulationInfected 
From covidcases
WHERE continent != ' '
and location not in ('World', 'European Union', 'International')
Group by Location, Population
order by PercentPopulationInfected desc

-- 7. Global number of fatality rate

Select SUM(newcases) as totalcases, SUM(cast(newdeaths as int)) as totaldeaths, SUM(cast(newdeaths as int))/SUM(NewCases)*100 as DeathPercentage
From Coviddeaths
where continent != ' '
and location not in ('World', 'European Union', 'International')
order by 1,2

-- Fixing vaccine data

ALTER TABLE Covidvaccine ADD newvaccinations REAL;

UPDATE Covidvaccine SET newvaccinations = CAST(new_vaccinations AS REAL);
select newvaccinations from covidvaccine

-- 8. Join vaccine data with covid deaths data

FROM Coviddeaths dea 
JOIN Covidvaccine vac 
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
order by 2,3

SELECT *
From Coviddeaths dea
Join Covidvaccine vac
	On dea.location = vac.location
	and dea.date = vac.date

-- 9. total population and vaccination

SELECT dea.continent, dea.date, dea.location, vac.newvaccinations
From Coviddeaths dea
Join Covidvaccine vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent != ' ' 
order by 2,3 

-- 10. Partitioned by location - showing countries with atleast 1 vaccine
SELECT dea.continent, dea.date, dea.location, vac.newvaccinations,
SUM(vac.newvaccinations) OVER (Partition by dea.location order by dea.location, dea.date) as frequency
From Coviddeaths dea
Join Covidvaccine vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent != ' ' 
order by dea.location, dea.date

-- OR CONVERT IT TO INT
SELECT dea.continent, dea.date, dea.location, vac.newvaccinations,
SUM(CONVERT(int, vac.new_vaccinations)) OVER (Partition by dea.location order by dea.location, dea.date) as frequency
From Coviddeaths dea
Join Covidvaccine vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent != ' ' 

-- 11. CTE Shows Percentage of Population that has recieved at least one Covid Vaccine

With PopvsVac (Continent, Location, Date, Population, newvaccinations, vaccinationfrequency)
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.newvaccinations
, SUM(vac.newvaccinations) OVER (Partition by dea.Location Order by dea.location, dea.Date) as Rvaccinationfrequency
From Coviddeaths dea
Join Covidvaccine vac
	On dea.location = vac.location
	and dea.date = vac.date
)
Select *, (vaccinationfrequency/Population)*100
From PopvsVac



With PopvsVac (Continent, Location, Date, newvaccinations,population,frequency)
as
(
SELECT dea.continent, dea.date, dea.location,dea.population vac.newvaccinations,
SUM(CONVERT(int, vac.new_vaccinations)) OVER (Partition by dea.location order by dea.location, dea.date) as frequency
From Coviddeaths dea
Join Covidvaccine vac
		On dea.location = vac.location
		and dea.date = vac.date
)
Select *, (frequency/Population)*100
From PopvsVac


-- 12. temp table

CREATE TABLE vaccinationpopulation 
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population int,
new_vaccinations int,
vaccinationfrequency int
)

insert into vaccinationpopulation
Select dea.continent, dea.location, dea.date, dea.pop, vac.newvaccinations
, SUM(vac.newvaccinations) OVER (Partition by dea.Location Order by dea.location, dea.Date) as vaccinationfrequency
--, (RollingPeopleVaccinated/population)*100
From Coviddeaths dea
Join Covidvaccine vac
	On dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent != ' ' 

select * from vaccinationpopulation

-- 13. creating view for later

Create View totalpopulationvaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From coviddeaths dea
Join covidvaccine vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
