USE Covid_Project

-- Checking to make sure tables imported successfully. 
Select top(15) *
From CovidData;

-- Some of the more important columns I'll be using in this exploratory analysis. 
Select C.Location, C.Date, C.Total_Cases, C.New_Cases, C.Total_Deaths, C.New_Deaths, V.Total_Vaccinations, V.New_Vaccinations, P.Population
From CovidData C Join PopulationInfo P
On C.Location = P.Location and C.Date = P.Date
Join VaccineInfo V
On C.Location = V.Location and C.Date = V.Date
Order by 1,2;

-- Creating a Covid Death Rate statistic by dividing total deaths by total cases. This number shouldn't change much day-by-day, but over time the percent should change. 
Select Location, Date, Total_Cases, Total_Deaths, (Total_Deaths/Total_Cases)*100 Covid_Death_Rate
From CovidData
Order by 1,2;

--Narrowing Data to just the United States.
Select Location, Date, Total_Cases, Total_Deaths, (Total_Deaths/Total_Cases)*100 Covid_Death_Rate
From CovidData
Where Location = 'United States'
Order by 1,2;

-- Seeing the percent of American who has had COVID.
Select C.Location, C.Date, C.Total_Cases, C.Total_Deaths, (C.Total_Cases/P.Population)*100 Rate_of_Covid_Cases
From CovidData C Join PopulationInfo P
On C.Location = P.Location and C.Date = P.Date
Where C.Location = 'United States'
Order by 1,2;

Select Location, Max(cast(Total_Deaths as int)) as Total_Death_Numerical
From CovidData
Group by Location
Order by Total_Death_Numerical desc;
--Slight problem with the data as the data doesn't differentiate between countries and regions in terms of location, so we need to find a way to separate the two.

Select Location, Max(cast(Total_Deaths as int)) as Total_Death_Numerical
From CovidData
Where continent is not null
Group by Location
Order by Total_Death_Numerical desc;
--This query just pulls data from countries

Select Location, Max(cast(Total_Deaths as int)) as Total_Death_Numerical1
From CovidData
Where continent is null
Group by Location
Order by Total_Death_Numerical1 desc;
-- Due to a quark with our data, we can use the null values in the continent column to get the total deaths by continent. This is because the null values in the Continent column instead use the Location column to record their continent.

Select Continent, Max(cast(Total_Deaths as int)) as Total_Death_Numerical2
From CovidData
Group by Continent
Order by Continent desc;
--This is the more typical method to get the statistics for continents, but it's data doesn't seem as reliable. North America, for instance has a death count very similar to the USA alone, when the number should be higher given the relative populations of Mexico and Canada. 
--Therefore, using continent = null as a constraint is the better method.


-- Checking Rate of COVID Cases and the Percent of Deaths across all the countries with data.
Select C.Location, AVG(P.Population) Average_Population, Max(C.Total_Cases/P.Population) Rate_of_Covid_Cases, AVG(C.Total_Deaths/C.Total_Cases)*100 Average_Covid_Death_Rate, AVG(P.gdp_per_capita) AS Average_GDP_per_capita
From CovidData C Join PopulationInfo P
On C.Location = P.Location and C.Date = P.Date
Where C.Continent is not null 
Group by C.Location
Order by 4 desc, 3;
-- This is the first point of concern with future exploration of the data. Based on the fact that many of the countries with high percentages of deaths have an extremely low rate of infections, it's very likely that the amount of cases is being misreported by various countries, influencing the accuracy of the data.
-- Interestingly, there doesn't seem to be much relation between the COVID death rate and GDP per capita. More analysis can be done here in the future though.

--This can also be done by continent.
Select C.Location, AVG(P.Population) Average_Population, Max(C.Total_Cases/P.Population) Rate_of_Covid_Cases, AVG(C.Total_Deaths/C.Total_Cases)*100 Average_Covid_Death_Rate
From CovidData C Join PopulationInfo P
On C.Location = P.Location and C.Date = P.Date
Where C.Continent is null and P.population is not null
Group by C.Location
Order by 4 desc, 3;

--Global counts
--By Date
Select Date, SUM(New_Cases) Daily_Global_Cases, SUM(Cast(New_Deaths as int)) Daily_Global_Deaths, SUM(Cast(New_Deaths as int))/SUM(New_Cases)*100 Covid_Death_Rate
From CovidData
Where Continent is not null
Group by date
Order by 1,2;

--Total
Select SUM(New_Cases) Daily_Global_Cases, SUM(Cast(New_Deaths as int)) Daily_Global_Deaths, SUM(Cast(New_Deaths as int))/SUM(New_Cases)*100 Covid_Death_Rate
From CovidData
Where Continent is not null
Order by 1,2;

--Vaccination Data

Select C.Continent, C.Location, C.Date, P.Population, V.New_Vaccinations, SUM(Cast(V.New_Vaccinations as int)) OVER (Partition by c.Location Order by C.Location, C.Date) as Rolling_Vaccinated
From CovidData C Join VaccineInfo V
On C.Date=V.Date and C.Location=V.Location
Join PopulationInfo P
On C.Date=P.Date and C.Location=P.Location
Where C.Continent = 'Europe'
Order by 2,3;

--Using CTE to create new calculated column
With PercVac (Continent, Location, Date, Population, New_Vaccinations, Rolling_Vaccinated)
as
(Select C.Continent, C.Location, C.Date, P.Population, V.New_Vaccinations, SUM(Cast(V.New_Vaccinations as int)) OVER (Partition by c.Location Order by C.Location, C.Date) as Rolling_Vaccinated
From CovidData C Join VaccineInfo V
On C.Date=V.Date and C.Location=V.Location
Join PopulationInfo P
On C.Date=P.Date and C.Location=P.Location
Where C.Continent = 'Europe')
Select *, (Rolling_Vaccinated/Population)*100 as Total_Vaccinated
From PercVac
Order by Location, Date;

--Storing data for later use. 
Create View Europe_Vaccinations as
Select C.Continent, C.Location, C.Date, P.Population, V.New_Vaccinations, SUM(Cast(V.New_Vaccinations as int)) OVER (Partition by c.Location Order by C.Location, C.Date) as Rolling_Vaccinated
From CovidData C Join VaccineInfo V
On C.Date=V.Date and C.Location=V.Location
Join PopulationInfo P
On C.Date=P.Date and C.Location=P.Location
Where C.Continent = 'Europe';

--More queries for Tableau
Select SUM(New_Cases) as Total_Cases, SUM(Cast(New_Deaths as int)) as Total_Deaths, Sum(CAST(New_Deaths as INT))/Sum(New_Cases)*100 as Death_Rate
FROM CovidData
Where Location = 'United States';

Select Location, SUM(Cast(New_Deaths as int)) as Total_Deaths
From CovidData
Where Continent is null and Location not in ('World', 'European Union', 'International', 'High Income', 'Middle Income', 'Low Income', 'Lower Middle Income', 'Upper Middle Income')
Group by Location;

Select C.Location, AVG(P.Population) Population, MAX(C.Total_Cases) as Maximum_Infections, Max((C.Total_Cases/P.Population))*100 as Percent_Infected
From CovidData C Join PopulationInfo P
On C.Location = P.Location and C.Date = P.Date
Group by C.Location, C.Date; 

Select C.Location, P.Population, C.Date, Max(C.Total_Cases) as Highest_Infections, Max((C.Total_Cases/P.Population))*100 as Infection_Rate 
From CovidData C Join PopulationInfo P
On C.Location = P.Location and C.Date = P.Date
Group by C.Location, P.Population, C.Date
Order by Infection_Rate;
