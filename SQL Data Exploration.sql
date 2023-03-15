select * from world.coviddeaths_p1
where continent is not null
order by 3,4
;
select * from world.covidvaccinations_p1
where continent is not null
order by 3,4;
-- to explore total_cases and total_deaths
select location,date,total_cases,new_cases,total_deaths,population
from world.coviddeaths_p1
where continent is not null
order by 1,2;

-- total cases Vs total deaths
select location,date,total_cases,
total_deaths,round((total_deaths/total_cases)*100,2) as Death_Percentage
from world.coviddeaths_p1
where location = "India" and 
continent is not null
order by 1,2;

-- total cases Vs population
-- percentage of population got covid
select location,date,total_cases,
population,round((total_cases/population)*100,2)as Population_Infected_Percentage
from world.coviddeaths_p1
where location = "India" and
continent is not null
order by 1,2;

-- countries with highest infected count compared to population
select distinct(location),population,max(total_cases) as highest_infected_count,
round(max((total_cases/population))*100,2) as Population_Infected_Percentage
from world.coviddeaths_p1
-- where location = "India"  
where continent is not null
group by location,population
order by 4 desc;

-- countries with highest death count per population 
select distinct(location) as location,max(cast(total_deaths as unsigned)) as highest_death_count
from world.coviddeaths_p1
-- where location = "India"
where continent is not null 
group by location
order by 2 desc;

-- breaking down by continent
select  location ,max(cast(total_deaths as unsigned)) as highest_death_count
from world.coviddeaths_p1
-- where location = "India"
where continent is null
group by location
order by 2 desc;
select continent ,max(cast(total_deaths as unsigned)) as highest_death_count
from world.coviddeaths_p1
-- where location = "India"
where continent is not null
group by continent
order by 2 desc;

-- Global numbers by date
select date,sum(new_cases) as total_new_cases,
sum(cast(new_deaths as signed)) as total_new_deaths,
round(sum(cast(new_deaths as signed))/sum(new_cases)*100,2) as new_death_percentage
from world.coviddeaths_p1
where continent is not null
group by date
order by 1,2;

-- total global numbers
select sum(new_cases) as total_new_cases,
sum(cast(new_deaths as signed)) as total_new_deaths,
round(sum(cast(new_deaths as signed))/sum(new_cases)*100,2) as new_death_percentage
from world.coviddeaths_p1
where continent is not null
-- group by date
order by 1,2;

-- Total population Vs vaccination using CTE
with popvsvac (continent, location,date,population,new_vaccinations,Rolling_people_vaccinated) as
(
select dea.continent,dea.location,dea.date,dea.population,
cast(vac.new_vaccinations as unsigned),
sum(cast(vac.new_vaccinations as unsigned)) over(partition by dea.location
order by dea.location,dea.date) as Rolling_people_vaccinated
from world.coviddeaths_p1 dea
join
world.covidvaccinations_p1 vac
on dea.location = vac.location and dea.date = vac.date
where dea.continent is not null
)
-- order by 2, 3
select *, (Rolling_people_vaccinated/population)*100
as Rollingpeoplevaccinated_pct from popvsvac;

-- using temp table 
drop table if exists percentage_population_vaccinated;
create temporary table percentage_population_vaccinated
(continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
Rolling_people_vaccinated numeric
);
insert into percentage_population_vaccinated 

select dea.continent,dea.location,dea.date,dea.population,
cast(vac.new_vaccinations as unsigned),
sum(cast(vac.new_vaccinations as unsigned)) over(partition by dea.location
order by dea.location,dea.date) as Rolling_people_vaccinated
from world.coviddeaths_p1 dea
join
world.covidvaccinations_p1 vac
on dea.location = vac.location and dea.date = vac.date
where dea.continent is not null;

select *, round((Rolling_people_vaccinated/population)*100,2)
as Rollingpeoplevaccinated_pct from percentage_population_vaccinated;



