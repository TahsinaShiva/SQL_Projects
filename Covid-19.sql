select *
from Covid19..coviddeaths order by 3,4

select *
from Covid19..covidvaccination order by 3,4

select location, date, total_cases, new_cases, total_deaths, population
from Covid19..coviddeaths order by 1,2



--1. total case vs total deaths
SELECT location, date, total_cases, total_deaths,
       CONCAT(FORMAT(TRY_CONVERT(float, total_deaths) / TRY_CONVERT(float, total_cases) * 100, 'N2'), '%') AS death_rate_percentage
FROM Covid19..coviddeaths where location like '%states%'
ORDER BY 1,2


--2. total case vs population to check what percentage of population got covid 

SELECT location, date, Population ,total_cases, 
       CONCAT(FORMAT(TRY_CONVERT(float, total_cases) / TRY_CONVERT(float, Population) * 100, 'N2'), '%') AS affected_percentage
FROM Covid19..coviddeaths 
ORDER BY 1,2

--3. countries with highest infection rate compared to population 

SELECT location, Population ,max(total_cases) as highestinfection ,
       CONCAT(FORMAT(max(TRY_CONVERT(float, total_cases) / TRY_CONVERT(float, Population)) * 100, 'N2'), '%') AS infectedpopulation_percentage
FROM Covid19..coviddeaths group by location, Population
ORDER BY 1,2 --approach 1 

SELECT location, Population, MAX(total_cases) AS highest_infection,
       CONCAT(FORMAT(MAX(total_cases / Population) * 100, 'N2'), '%') AS infected_population_percentage
FROM Covid19..coviddeaths
GROUP BY location, Population
ORDER BY 1,2 --approach 2

SELECT location, Population, MAX(total_cases) AS highest_infection,
   MAX((total_cases / Population)) * 100 AS infected_population_percentage
FROM Covid19..coviddeaths where continent is not null
GROUP BY location, Population
ORDER BY infected_population_percentage desc -- approach 3 

--note : The GROUP BY clause is applied to group the data by location and Population, allowing us to calculate the infection rate based on the highest total cases for each country.

--4. showing countries with highest death count per population
SELECT location,max(cast(total_deaths as int)) as totaldeathcount
FROM Covid19..coviddeaths where continent is not null
GROUP BY location
ORDER BY totaldeathcount desc

-- now by continent 
SELECT continent,max(cast(total_deaths as int)) as totaldeathcount
FROM Covid19..coviddeaths where continent is not null
GROUP BY continent 
ORDER BY totaldeathcount desc

--5. Accross the world find out the new death percentage everyday

SELECT date, 
       SUM(new_cases) AS total_cases, SUM(new_deaths) AS total_deaths,
      concat( FORMAT((SUM(new_deaths) / NULLIF(SUM(new_cases), 0)) * 100, 'N2'), '%') AS death_percentage
FROM Covid19..coviddeaths
WHERE continent IS NOT NULL GROUP BY date ORDER BY date;
-- note: So the 0 in the NULLIF function is the value that we want to compare against the first argument (SUM(new_cases)) to determine if it should be replaced with NULL. If the sum of new cases is zero, the NULLIF function will replace it with NULL, preventing the division operation and avoiding the divide by zero error.

-- accross the world newdeath percentage
SELECT  
       SUM(new_cases) AS totalnew_cases, SUM(new_deaths) AS totalnew_deaths,
      concat( FORMAT((SUM(new_deaths) / NULLIF(SUM(new_cases), 0)) * 100, 'N2'), '%') AS newdeath_percentage
FROM Covid19..coviddeaths
WHERE continent IS NOT NULL 


--VACCINATION-- 

select * from [Covid19 ].dbo.[covidvaccination ]

--6. join the two tables
select * from
Covid19..coviddeaths as dea join Covid19..covidvaccination as vac
on dea.location=vac.location 
and dea.date= vac.date

--7. vaccinated from total population per day 
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations  from
Covid19..coviddeaths as dea join Covid19..covidvaccination as vac
on dea.location=vac.location 
and dea.date= vac.date 
WHERE dea.continent IS NOT NULL 
order by 2,3 

--8. looking at the total new_vaccination of total population in each location. so we are going to use partition by


ALTER TABLE Covid19..covidvaccination
ALTER COLUMN new_vaccinations BIGINT; -- 

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
       NULLIF(SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location order by dea.location, dea.date), 0) as rollingpeoplevaccinated 
FROM Covid19..coviddeaths AS dea
JOIN Covid19..covidvaccination AS vac ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY dea.location, dea.date;


--9. CTE

WITH popVsvac (continent, location, date, population, new_vaccinations, rollingpeoplevaccinated) AS
(
    SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
           NULLIF(SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date), 0) as rollingpeoplevaccinated
    FROM Covid19..coviddeaths AS dea
    JOIN Covid19..covidvaccination AS vac ON dea.location = vac.location AND dea.date = vac.date
    WHERE dea.continent IS NOT NULL
)
SELECT *, CONCAT(FORMAT(rollingpeoplevaccinated/population, 'N2'), '%') AS percentage
FROM popVsvac;

--10. temp table
drop table if exists #percentpopvaccinated
create table #percentpopvaccinated ( continent nvarchar(255), 
location nvarchar(255), 
date datetime , 
population numeric,
new_vaccinations numeric, 
rollingpeoplevaccinated numeric )

insert into #percentpopvaccinated 
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
           NULLIF(SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date), 0) as rollingpeoplevaccinated
    FROM Covid19..coviddeaths AS dea
    JOIN Covid19..covidvaccination AS vac ON dea.location = vac.location AND dea.date = vac.date
    --WHERE dea.continent IS NOT NULL

SELECT *, CONCAT(FORMAT(rollingpeoplevaccinated/population, 'N2'), '%') AS percentage
FROM #percentpopvaccinated ;

--11. create view 
create view percentpopvaccinated as 
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
           NULLIF(SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date), 0) as rollingpeoplevaccinated
    FROM Covid19..coviddeaths AS dea
    JOIN Covid19..covidvaccination AS vac ON dea.location = vac.location AND dea.date = vac.date
    WHERE dea.continent IS NOT NULL
	--order by 2,3 