USE hotel_booking;

-- ------------------------------------------------------------- Data Prep

-- Adding an ID for each booking record:

ALTER TABLE hotel_booking
ADD COLUMN booking_id INT AUTO_INCREMENT PRIMARY KEY;





-- ------------------------------------------------------------- Exploratory Data Analysis

/*
	This dataset was retrieved from Kaggel by MOJTABA. The original source is from the article Hotel Booking Demand Datasets, 
	written by Nuno Antonio, Ana Almeida, and Luis Nunes for Data in Brief, Volume 22, February 2019.
	This dataset contains records for a  City and Resort Hotel located in Portugal. 
	Each record represents a booking between July 1, 2015 -- August 31, 2017

*/

SELECT * FROM hotel_booking;


-- Compare the number of Resort Hotel bookings vs City Hotel & canceled booking

SELECT
    hotel,
    COUNT(*) AS bookings,
    COUNT(CASE WHEN is_canceled = 1 AND reservation_status = 'Canceled' THEN 1 ELSE NULL END) AS canceled_bookings
FROM hotel_booking
GROUP BY 
    hotel;
    
    
    
-- Show total bookings, total "canceled" bookings, and % of canceled bookings per Hotel and Year

SELECT 
    hotel,
    arrival_date_year AS year,
    COUNT(*) AS bookings,
    COUNT(CASE WHEN is_canceled = 1 AND reservation_status = 'Canceled' THEN 1 ELSE NULL END) AS canceled_bookings,
    ROUND(COUNT(CASE WHEN is_canceled = 1 AND reservation_status = 'Canceled' THEN 1 ELSE NULL END) / COUNT(*) * 100,2) AS per_of_bookings_canceled
FROM hotel_booking
GROUP BY 
    hotel,
    year
ORDER BY 
    hotel;


    

/*
    The majority of the bookings are made to the City Hotel. 
    In addition, the City Hotel experiences a higher cancelation percentage than the Resort Hotel.
    However, for both hotels, there was a drop in bookings between the years 2016-2017
*/

-- ---------------- "Overall "Bookings" Monthly Trend Analysis

    SELECT
	arrival_date_year AS year,
        arrival_date_month AS month,
        COUNT(*) AS bookings,
	COUNT(CASE WHEN is_canceled = 1 AND reservation_status = 'Canceled' THEN 1 ELSE NULL END) AS canceled_bookings,
        ROUND(COUNT(CASE WHEN is_canceled = 1 AND reservation_status = 'Canceled' THEN 1 ELSE NULL END) 
	   /  COUNT(*) *100,2) AS cancel_rate
	FROM hotel_booking
    GROUP BY 
	year,
        month;


  -- Completed Bookings per Month: Guests who did not cancel their reservations

   SELECT
	arrival_date_year AS year,
        arrival_date_month AS month,
        COUNT(*) AS bookings
	FROM hotel_booking
    WHERE is_canceled = 0
    GROUP BY 
	year,
        month;
        
        
        

        
-- ---------------- "Overall "Bookings" Quarterly Trend Analysis     
    
    SELECT
	 arrival_date_year AS year,
	 CASE 
	      WHEN arrival_date_month IN ('January', 'February', 'March') THEN 'Q1'
              WHEN arrival_date_month IN ('April', 'May', 'June') THEN 'Q2'
              WHEN arrival_date_month IN ('July', 'August', 'September') THEN 'Q3'
              WHEN arrival_date_month IN ('October', 'November', 'December') THEN 'Q4'
              ELSE NULL
	END AS season,
        COUNT(*) AS bookings,
        COUNT(CASE WHEN is_canceled = 1 AND reservation_status = 'Canceled' THEN 1 ELSE NULL END) AS canceled_bookings,
        ROUND(COUNT(CASE WHEN is_canceled = 1 AND reservation_status = 'Canceled' THEN 1 ELSE NULL END) 
	   /  COUNT(*) *100,2) AS cancel_rate
    FROM hotel_booking
    GROUP BY 1,2
    ORDER BY 1,2;


/*
    There tends to be a drop of bookings during Quarter 4 (Oct - Dec).
    Q2 tends to have a spike in cancelations
    The months of November and December bring in the least amount of bookings.
*/
    


-- Show on average how early in advanced hotels booked


SELECT
    hotel,
    ROUND(AVG(lead_time),0) AS avg_lead_time
FROM hotel_booking
GROUP BY 
    hotel;
    
    
-- Show the average amount of days stayed per visit, broken down per month

SELECT
    arrival_date_month AS month,
    ROUND(AVG(stays_in_weekend_nights + stays_in_week_nights),0) AS avg_nights_stayed
FROM hotel_booking
GROUP BY 
    month;


-- ------------------------------------------------------------------------- "Booking" Traffic Analysis

SELECT
    market_segment,
    COUNT(CASE WHEN hotel = 'Resort Hotel' THEN 1 ELSE NULL END) AS resort_hotel_bookings,
    COUNT(CASE WHEN hotel = 'City Hotel' THEN 1 ELSE NULL END) AS city_hotel_bookings,
    (COUNT(CASE WHEN hotel = 'Resort Hotel' THEN 1 ELSE NULL END) 
	+ COUNT(CASE WHEN hotel = 'City Hotel' THEN 1 ELSE NULL END)) AS total_bookings
FROM hotel_booking
GROUP BY
    market_segment
ORDER BY 
   market_segment;

    
/*
	The majority of the traffic comes from online Travel Agents.
	Overall, the city hotel attracts more business.
*/
    
    
    
-- Show the cancelation percentages per distribution channels

SELECT 
    distribution_channel,
    COUNT(*) AS distributions_made_by_channel
FROM hotel_booking
GROUP BY
    distribution_channel
ORDER BY
    distributions_made_by_channel DESC;
    
    
    
  
    
SELECT * FROM hotel_booking;


-- ----------------------------------------------------------------------- Customer Analysis
    
    
-- Show the customer types and their respective overall number of bookings
    SELECT
	customer_type,
        COUNT(*) AS bookings
    FROM hotel_booking
    GROUP BY 
	customer_type
    ORDER BY 
	bookings DESC;
        
/*
	The majority of bookings are made by "Transient" customer type. Transient customers are defined as those who are not part of a group or contract
	and is not associated to other transient bookings.
	Transient-party refers to customers who are not part of a group or contract, but is associated to other transient bookings.
*/
    
    
  -- Show the customer types and their respective overall number of bookings PER hotel
    
    SELECT
	hotel,
	customer_type,
        COUNT(*) AS bookings
    FROM hotel_booking
    GROUP BY 
	hotel,
	customer_type
    ORDER BY 
    	hotel,
	bookings DESC;
  

-- Show were customers originate from and their booking statistics:

    SELECT
	country,
        COUNT(*) AS customers,
        COUNT(CASE WHEN is_canceled = 1 AND reservation_status = 'Canceled' THEN 1 ELSE NULL END) AS canceled_bookings,
        ROUND(COUNT(CASE WHEN is_canceled = 1 AND reservation_status = 'Canceled' THEN 1 ELSE NULL END)
	   / COUNT(*)*100,2) AS per_of_canceled_bookings
    FROM hotel_booking
    GROUP BY 
	country
    ORDER BY 
   	customers DESC;




-- Show if there is a correlation between deposit_type and cancelation_rates

SELECT
   CASE
	WHEN is_canceled = 0 THEN 'not_canceled'
        ELSE 'canceled'
   END AS is_canceled,
   COUNT(CASE WHEN deposit_type = 'No Deposit' THEN 1 ELSE NULL END) AS no_deposit,
   COUNT(CASE WHEN deposit_type = 'Refundable' THEN 1 ELSE NULL END) AS refundable,
   COUNT(CASE WHEN deposit_type = 'Non Refund' THEN 1 ELSE NULL END) AS non_refundable
FROM hotel_booking
GROUP BY 1;


    


-- --------------------------------------- ADR (Average Daily Rate) Analysis

-- ADR Trending Analysis (yearly & monthly)


-- average yearly rate

SELECT
    arrival_date_year AS year,
    ROUND(AVG(adr),2) AS avg_daily_rate
FROM hotel_booking
GROUP BY 
    year
ORDER BY 
    year;


-- average monthly rate


SELECT
    arrival_date_year AS year,
    arrival_date_month AS month,
    ROUND(AVG(adr),2) AS avg_daily_rate
FROM hotel_booking
GROUP BY 
    year,
    month
ORDER BY
    year;


/*
	The months June - September have the highest average daily rates. A possible conclusion for this would be the impact of the "Summer" season. 
	Interestingly, the holiday months tend to be on the lower end of the spectrum 
*/


-- ADR comparison with Cancelation Rates

SELECT
    arrival_date_year AS year,
    arrival_date_month AS month,
    ROUND(AVG(adr),2) AS avg_daily_rate,
    ROUND(COUNT(CASE WHEN is_canceled = 1 THEN 1 ELSE NULL END) / COUNT(*) * 100,2) AS cancelation_rate
FROM hotel_booking
GROUP BY 
    year,
    month;
































