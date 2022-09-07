use sql_project;

-- selecting few columns
select *
from sql_project.covid_deaths
where location = 'Afghanistan';

-- liklihood of dying if you are infected by virus
select location, str_to_date(case_date, "%d-%m-%Y") as case_date, total_cases, total_deaths, 
       round((total_deaths/total_cases)*100, 2) as DeathPercentage
from sql_project.covid_deaths
where location like '%Asia%'
order by 1,2;

-- looking at total deaths vs population
select location, str_to_date(case_date, "%d-%m-%Y") as case_date, total_cases, population, total_deaths, 
       round((total_deaths/population)*100, 4) as DeathPercentage_by_population
from sql_project.covid_deaths
-- where location like '%Asia%'
order by 1,2;

-- looking at percentage of people infected in each location and finding out maximum
select location, max(total_cases) as highest_infected, total_cases, population, total_deaths, 
       max(round((total_cases/population)*100, 4)) as PercentPopulationInfected
from sql_project.covid_deaths
-- where location like '%Asia%'
group by location
order by PercentPopulationInfected desc;

-- showing the countries with the highest death count per population
select location, max(total_deaths) as total_death_count, total_deaths
from sql_project.covid_deaths
where location = 'Afghanistan';
-- group by location
-- order by total_death_count desc;

select continent, location, total_deaths from sql_project.covid_deaths
where continent is not NULL;

UPDATE sql_project.covid_deaths
SET total_deaths = 0
where total_deaths='NULL';

-- showing the countries with the highest death count per population
select location, max(total_deaths) as total_death_count
from sql_project.covid_deaths
where continent <> 'NULL'
group by location
order by total_death_count desc;

-- let's break thing by continent
select location, max(total_deaths) as total_death_count
from sql_project.covid_deaths
where continent = 'NULL' 
group by location
order by total_death_count desc;

select * from sql_project.covid_deaths;

-- Global numbers
select  sum(new_cases) as total_cases, sum(new_deaths) as total_deaths, round(sum(new_deaths)/sum(new_cases)*100, 4) as DeathPercentage
from sql_project.covid_deaths
where continent <> "NULL"
-- group by case_date
order by 1,2;


-- Now using covid vaccination table
select * 
from sql_project.covid_deaths deaths
join sql_project.covid_vaccination vaccine
on deaths.location = vaccine.location
and deaths.case_date = vaccine.date
limit 10;

-- how many people are vaccinated in the world
select sum(vaccine.new_vaccinations )
from sql_project.covid_deaths deaths
join sql_project.covid_vaccination vaccine
on deaths.location = vaccine.location
and deaths.case_date = vaccine.date;

select deaths.continent, deaths.location, deaths.population, str_to_date(deaths.case_date, "%d-%m-%Y") as case_date, vaccine.new_vaccinations
from sql_project.covid_deaths deaths
join sql_project.covid_vaccination vaccine
on deaths.location = vaccine.location
and deaths.case_date = vaccine.date
where deaths.continent <> "NULL" 
-- group by deaths.continent
order by 1,2,4;

select deaths.continent, deaths.location, deaths.population, str_to_date(deaths.case_date, "%d-%m-%Y") as case_date,vaccine.new_vaccinations, 
sum(vaccine.new_vaccinations) over (partition by deaths.location order by deaths.location, str_to_date(deaths.case_date, "%d-%m-%Y")) RollingVaccineCount
from sql_project.covid_deaths deaths
join sql_project.covid_vaccination vaccine
on deaths.location = vaccine.location
and deaths.case_date = vaccine.date
where deaths.continent <> "NULL" 
-- group by deaths.continent
order by 1,2,4;

-- Using cte to how many in that country get vaccinated
-- we can divide the newly created RollingVaccineCount and get the no of people vaccinated by RollingVaccineCount/population on each location
-- but we can't use newly created variable 
-- so use cte
with popvsvacc (continent, location, population, case_date, new_vaccinations, RollingVaccineCount)
as (
select deaths.continent, deaths.location, deaths.population, str_to_date(deaths.case_date, "%d-%m-%Y") as case_date,vaccine.new_vaccinations, 
sum(vaccine.new_vaccinations) over (partition by deaths.location order by deaths.location, str_to_date(deaths.case_date, "%d-%m-%Y")) RollingVaccineCount
from sql_project.covid_deaths deaths
join sql_project.covid_vaccination vaccine
on deaths.location = vaccine.location
and deaths.case_date = vaccine.date
where deaths.continent <> "NULL" 
-- group by deaths.continent
)
select *, RollingVaccineCount/population * 100
 from popvsvacc;
 
 -- temp table
drop table if exists sql_project.PercentPopulationVaccinated;
create table sql_project.PercentPopulationVaccinated
 (
 Continent nvarchar(255),
 Location nvarchar(255),
 Date datetime,
 population numeric,
 RollingVaccineCount numeric
 );
 
insert into PercentPopulationVaccinated 
select deaths.continent, deaths.location, str_to_date(deaths.case_date, "%d-%m-%Y") as case_date, deaths.population,
sum(vaccine.new_vaccinations) over (partition by deaths.location order by deaths.location, str_to_date(deaths.case_date, "%d-%m-%Y")) RollingVaccineCount
from sql_project.covid_deaths deaths
join sql_project.covid_vaccination vaccine
on deaths.location = vaccine.location
and deaths.case_date = vaccine.date
where deaths.continent <> "NULL"; 
-- group by deaths.continent
-- order by 1,2,4

select *, RollingVaccineCount/population * 100
from PercentPopulationVaccinated;

-- CREATING VIEW
create view PopulationVaccinated as 
select deaths.continent, deaths.location, str_to_date(deaths.case_date, "%d-%m-%Y") as case_date, deaths.population,
sum(vaccine.new_vaccinations) over (partition by deaths.location order by deaths.location, str_to_date(deaths.case_date, "%d-%m-%Y")) RollingVaccineCount
from sql_project.covid_deaths deaths
join sql_project.covid_vaccination vaccine
on deaths.location = vaccine.location
and deaths.case_date = vaccine.date
where deaths.continent <> "NULL"; 




