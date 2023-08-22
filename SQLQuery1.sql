SELECT TOP (1000) [Hour_of_Day]
      ,[CSAT_Rating]
      ,[In_Out_Network]
      ,[Service_type]
      ,[Job_Accept_Channel]
      ,[Customer_Wait_Time]
      ,[Actual_Time_of_Arrival]
      ,[Time_to_Assign_Job]
      ,[ETA_min]
      ,[State]
      ,[Month]
      ,[Day]
      ,[Year]
  FROM [PortfolioProject].[dbo].[TridentMotors]

 
-- Make the 12 rows that were affected in Excel that were a negative, to 0. 
  UPDATE [PortfolioProject].[dbo].TridentMotors
SET Actual_Time_of_Arrival = CASE
                       WHEN Actual_Time_of_Arrival < 0 THEN 0
                       ELSE Actual_Time_of_Arrival
                    END;


-- Count of each states rating grouped by the rating itself.  
 SELECT state, CSAT_Rating, COUNT(*) AS ratings
 FROM [PortfolioProject].[dbo].TridentMotors
 WHERE CSAT_Rating IS NOT NULL
 GROUP BY CSAT_Rating, state
 ORDER BY CSAT_Rating Desc;

 -- Count of each states rating group by the rating, as well as the total count of ratings for each state.
 SELECT state, CSAT_Rating, COUNT(*) AS ratings
 FROM [PortfolioProject].[dbo].TridentMotors
 WHERE CSAT_Rating IS NOT NULL
 GROUP BY ROLLUP(state, CSAT_Rating)
 ORDER BY CSAT_Rating Desc;
 
 -- Count of all values in each column. 
  SELECT state, CSAT_Rating, COUNT(*) AS ratings
 FROM [PortfolioProject].[dbo].TridentMotors
 WHERE CSAT_Rating IS NOT NULL
 GROUP BY CUBE(state, CSAT_Rating)
 ORDER BY CSAT_Rating Desc;

 --  Count of each total states ratings and the states average. 
 SELECT state, COUNT(*) AS ratings, AVG(CSAT_Rating) as average_rating
 FROM [PortfolioProject].[dbo].TridentMotors
 WHERE CSAT_Rating IS NOT NULL
 GROUP BY state
 ORDER BY average_rating Desc;

 -- Does the actual amount of time someone waits to when the estimated time is affect star ratings? -Yes
  SELECT CSAT_Rating, AVG(Customer_Wait_Time) AS avg_real_wait_time, AVG(ETA_min) AS avg_ETA, AVG(Customer_Wait_Time - ETA_min) AS avg_wait_time_difference
FROM  [PortfolioProject].[dbo].TridentMotors
 WHERE CSAT_Rating IS NOT NULL
 GROUP BY CSAT_Rating
 ORDER BY CSAT_Rating Desc;

 -- How does the service differ in each state? What is the difference between ETA and actual time per state? Is that also affecting rating? 
SELECT State, AVG(CSAT_Rating) as average_rating,  AVG(Customer_Wait_Time) AS avg_real_wait_time, AVG(ETA_min) AS avg_ETA, AVG(Customer_Wait_Time - ETA_min) AS avg_wait_time_difference
FROM [PortfolioProject].[dbo].TridentMotors
 WHERE CSAT_Rating IS NOT NULL
 GROUP BY State
 ORDER BY average_rating Desc;

 -- Does the average wait time difference change with the time of day it is? What hour usually has the largest difference? 
 SELECT Hour_of_Day, AVG(Customer_Wait_Time) AS avg_real_wait_time, AVG(ETA_min) AS avg_ETA, AVG(Customer_Wait_Time - ETA_min) AS avg_wait_time_difference
 FROM  [PortfolioProject].[dbo].TridentMotors
 GROUP BY Hour_of_Day
 ORDER BY avg_wait_time_difference DESC;
 
 --Does star rating significantly differ specific hour of the day, business in the day and such?
 SELECT Hour_of_Day, AVG(CSAT_Rating) AS rating, AVG(Customer_Wait_Time - ETA_min) AS avg_wait_time_difference
 FROM [PortfolioProject].[dbo].TridentMotors
 GROUP BY Hour_of_Day
 ORDER BY avg_wait_time_difference

 --Is there a difference in the ETA, Time to Assign, and actual wait time between a Call or Digital request? 
 SELECT Job_Accept_Channel, AVG(ETA_min) AS avg_ETA, AVG(Time_to_Assign_Job) AS Time_to_Assign, AVG(Customer_Wait_Time) AS avg_real_wait_time,  AVG(Customer_Wait_Time - ETA_min) AS avg_wait_time_difference, COUNT(*) AS Total_requests
 FROM [PortfolioProject].[dbo].TridentMotors
 GROUP BY Job_Accept_Channel

 -- Add bins grouping different times of day to find which timeframe has the longest and shortest average wait. 
 SELECT AVG(ETA_min) AS average_wait,
	CASE WHEN Hour_Of_Day < 8 THEN 'Morning (0-7)'
		WHEN Hour_Of_Day < 16 THEN 'Day_time (8-15)'
		ELSE 'Evening/Night (16-23)'
	END AS Zones
FROM [PortfolioProject].[dbo].TridentMotors
GROUP BY CASE WHEN Hour_Of_Day < 8 THEN 'Morning (0-7)'
		WHEN Hour_Of_Day < 16 THEN 'Day_time (8-15)'
		ELSE 'Evening/Night (16-23)'
	END
ORDER BY AVG(ETA_min) Desc;
 
 
 -- Is there a difference in the ETA, Time to Assign, and Actualt wait time between clients that are In-Network Vs Out_of_Network?
 SELECT In_Out_Network, AVG(ETA_min) AS avg_ETA, AVG(Time_to_Assign_Job) AS Time_to_Assign, AVG(Customer_Wait_Time) AS avg_real_wait_time, 
 AVG(Customer_Wait_Time - ETA_min) AS avg_wait_time_difference, COUNT(*) AS Total_requests, MAX(Customer_Wait_Time) AS MaxWait
 FROM [PortfolioProject].[dbo].TridentMotors
 GROUP BY In_Out_Network

 --What Percentage of the time do they arrive on time? How often are they way late? - Got additional help from CHAT GPT to add case stmt in group by clause
SELECT
    CASE 
        WHEN (Customer_Wait_Time - ETA_min) <= 0 THEN 'On Time' 
        WHEN (Customer_Wait_Time - ETA_min) <= 20 THEN 'Within 20 Min' 
        WHEN (Customer_Wait_Time - ETA_min) <= 40 THEN 'Within 40 Min'
        WHEN (Customer_Wait_Time - ETA_min) <= 60 THEN 'Within 60 Min' 
        ELSE 'Over 60 Minute Additional Wait'
    END AS Times,
    COUNT(*) AS Count, 
	 CAST(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM PortfolioProject.dbo.TridentMotors) AS DECIMAL(10, 2)) AS percentage_of_total
FROM [PortfolioProject].[dbo].TridentMotors
GROUP BY
    CASE 
        WHEN (Customer_Wait_Time - ETA_min) <= 0 THEN 'On Time' 
        WHEN (Customer_Wait_Time - ETA_min) <= 20 THEN 'Within 20 Min' 
        WHEN (Customer_Wait_Time - ETA_min) <= 40 THEN 'Within 40 Min'
        WHEN (Customer_Wait_Time - ETA_min) <= 60 THEN 'Within 60 Min' 
        ELSE 'Over 60 Minute Additional Wait'
    END
ORDER BY percentage_of_total Desc;

 -- What are the top 5 busiest days? Was it July 4th?
 SELECT TOP 5 Month, day, year, COUNT(*) AS requests
 FROM [PortfolioProject].[dbo].TridentMotors
 GROUP BY day, month, year
 ORDER BY requests Desc

 -- Which states have the highest requests? -- Assitance from CHATGPT to find percentage
 SELECT state, COUNT(*) AS requests,
  CAST(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM PortfolioProject.dbo.TridentMotors) AS DECIMAL(10, 2)) AS percentage_of_total
 FROM PortfolioProject.dbo.TridentMotors
 GROUP BY state
 ORDER BY requests Desc

-- Which job types are the highest requested which are the least? 
SELECT Service_type, COUNT(*) AS Type_of_Service
FROM PortfolioProject.dbo.TridentMotors
GROUP BY Service_type
ORDER BY Type_of_Service Desc;

-- Which states the request which service the most? 
 SELECT state, Service_type, service_count
FROM (
    SELECT 
        state, 
        Service_type, 
        COUNT(*) as service_count,
        RANK() OVER(PARTITION BY state ORDER BY COUNT(*) DESC) as service_rank
    FROM [PortfolioProject].[dbo].TridentMotors
    GROUP BY state, Service_type
) AS ranked_services
WHERE service_rank = 1
ORDER BY state;

 -- Where is the dominant intersection of requests coming from ? (IN-or-OUT Network, JOB TYPE, Call or Digital?) -Double checked using Pivot Tables in Excel
 SELECT State, service_type, In_Out_Network, Job_Accept_Channel, mainrequests
 FROM (
	SELECT state, In_Out_Network, Job_Accept_Channel, Service_type, COUNT(*) AS mainrequests,
		RANK() OVER(PARTITION BY state ORDER BY COUNT(*) DESC) AS ranking
	FROM [PortfolioProject].[dbo].TridentMotors
	GROUP BY State, In_Out_Network, Job_Accept_Channel, Service_type
) AS ranked_services
WHERE ranking = 1 
ORDER BY State;
 