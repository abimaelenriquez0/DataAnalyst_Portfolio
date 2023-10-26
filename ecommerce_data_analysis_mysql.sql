-- ------------------------------------------------------------------------------- Ecommerce Digital Marketing Analysis

USE mavenfuzzyfactory;

SELECT * FROM website_pageviews;
SELECT * FROM order_item_refunds;
SELECT * FROM order_items;
SELECT * FROM orders;
SELECT * FROM website_sessions;


 -- Breakdown the number of website sessions  by UTM Source, campaign, and referring domain
 
SELECT 
    utm_source,
    utm_campaign,
    http_referer,
    COUNT(*) AS sessions
FROM website_sessions
GROUP BY
    utm_source,
    utm_campaign,
    http_referer
ORDER BY sessions DESC;


/* We discovered that the majority of traffic entering the site comes from the company's 'gsearch', 'nonbrand' sources. */





-- What is the conversion rate of the 'gsearch', 'nonbrand campaign'?
-- conversion_rate = orders/sessions

SELECT
    COUNT(DISTINCT website_sessions.website_session_id) AS sessions,
    COUNT(DISTINCT order_id) AS orders,
    COUNT(DISTINCT order_id) / COUNT(DISTINCT website_sessions.website_session_id) AS session_to_order_conv_rate
FROM website_sessions
	LEFT JOIN orders
		ON website_sessions.website_session_id = orders.website_session_id
WHERE  utm_source = 'gsearch'
    AND utm_campaign = 'nonbrand';

 
 
 
 
 
 -- Under 'gsearch', 'nonbrand' source, what is the session to order conversion rate for mobile and desktop devices?
 
 
SELECT
    website_sessions.device_type,
    COUNT(DISTINCT website_sessions.website_session_id) AS sessions,
    COUNT(DISTINCT orders.order_id) AS orders,
    COUNT(DISTINCT orders.order_id) / COUNT(DISTINCT website_sessions.website_session_id) AS session_to_order_conv_rate
FROM website_sessions
	LEFT JOIN orders
		ON website_sessions.website_session_id = orders.website_session_id
WHERE utm_source = 'gsearch'
    AND utm_campaign = 'nonbrand'
GROUP BY 
     website_sessions.device_type;



-- Under 'gsearch', 'nonbrand' source, show monthly website sessions trends; separated by device type.

SELECT
    MIN(DATE(created_at)) AS week_start_date,
    COUNT(CASE WHEN device_type = 'desktop' THEN website_session_id ELSE NULL END) AS desktop_sessions,
    COUNT(CASE WHEN device_type = 'mobile' THEN website_session_id ELSE NULL END) AS mobile_sessions
FROM website_sessions
WHERE utm_source = 'gsearch'
    AND utm_campaign = 'nonbrand'
GROUP BY
    YEAR(created_at),
    MONTH(created_at);
    
 
 
 -- What are the most-viewed website pages, ordered by session volume 
 
 SELECT
    pageview_url,
    COUNT(DISTINCT website_pageview_id) AS sessions
 FROM website_pageviews
 GROUP BY pageview_url
 ORDER BY sessions DESC;
 
 
 -- -----------------------------------------------------------------------------------------------------
 -- Show a list of the top entry pages, including each page's respective volume.
 
 
 -- Step 1: find the entry page for each website_session 
 CREATE TEMPORARY TABLE landing_page
 SELECT
    website_pageviews.website_session_id,
    MIN(website_pageviews.website_pageview_id) AS entry_page
 FROM website_pageviews
 GROUP BY website_pageviews.website_session_id;
 
 
 -- Step 2: find the URL for each entry ID and calculate its' respective volume
SELECT
    pageview_url,
    COUNT(DISTINCT entry_page) AS volume
FROM landing_page
	LEFT JOIN website_pageviews
		ON landing_page.entry_page = website_pageviews.website_pageview_id
GROUP BY pageview_url
ORDER BY volume DESC;
    
 
 
 -- -----------------------------------------------------------------------------------------------------
 -- Calculate the bounce rate for traffic landing on the homepage 

/* Steps to solve the problem:
     Step 1: find the first website_pageview_id for relevant sessions
     Step 2: count pageviews for each session, to identify "bounces"
     Step 3: summarize total sessions and bounced sessions, by landing page (LP)
*/


-- Step 1: find all sessions and their relevant min_pageview_id & store in a temporary table
CREATE TEMPORARY TABLE all_sessions
SELECT
    website_pageviews.website_session_id,
    MIN(website_pageviews.website_pageview_id) AS min_pageview_id
FROM website_pageviews
GROUP BY 
	website_pageviews.website_session_id;


-- Step 2: count pageviews for each session, to identify "bounces"
CREATE TEMPORARY TABLE bounced_sessions
SELECT
    all_sessions.website_session_id,
    COUNT(website_pageviews.website_pageview_id) AS sessions_bounced
FROM all_sessions
	LEFT JOIN website_pageviews
		ON all_sessions.website_session_id = website_pageviews.website_session_id
GROUP BY 
	all_sessions.website_session_id
HAVING
	COUNT(website_pageviews.website_pageview_id) = 1; -- filtering for "bounced" sessions



 -- Step 3: summarize total sessions and bounced sessions, by landing page (LP)
SELECT
    all_sessions.website_session_id,
    bounced_sessions.website_session_id AS bounced_session_id
FROM all_sessions
	LEFT JOIN bounced_sessions
		ON all_sessions.website_session_id = bounced_sessions.website_session_id;

-- Final Output: 

SELECT
    COUNT(DISTINCT all_sessions.website_session_id) AS sessions,
    COUNT(DISTINCT bounced_sessions.website_session_id) AS bounced_sessions,
    COUNT(DISTINCT bounced_sessions.website_session_id) / COUNT(DISTINCT all_sessions.website_session_id) AS bounce_rate
FROM all_sessions
	LEFT JOIN bounced_sessions
		ON all_sessions.website_session_id = bounced_sessions.website_session_id;



 -- -----------------------------------------------------------------------------------------------------
 -- Perform A/B Testing: Calculate the bounce rate for traffic landing on '/lander-1' compared to '/home' for gsearch, nonbrand

/* Steps to solve the problem:

    Step 1: find when '/lander-1' went live to discover the date range for this analysis 
    Step 2: find the first website_pageview_id for relevant sessions and their relevent landing page (url): /home and /lander-1
    Step 3: identify "bounced" sessions
    Step 4: summarize total sessions and bounced sessions, by landing page (LP)
*/


SELECT * FROM website_sessions;
SELECT * FROM website_pageviews;

-- Step 1: when '/lander-1' went live
	-- first website_pageview_id was 23504
SELECT
   pageview_url,
   MIN(website_pageview_id)
FROM website_pageviews
WHERE pageview_url = '/lander-1';


-- Step 2: find the first website_pageview_id for relevant sessions and their relevent landing page (url): /home and /lander-1
-- This allows fair A/B testing between both pages

CREATE TEMPORARY TABLE all_sessions_without_landing_page_url
SELECT
    website_pageviews.website_session_id,
    MIN(website_pageviews.website_pageview_id) AS min_pageview_id
FROM website_pageviews
	INNER JOIN website_sessions
		ON website_pageviews.website_session_id = website_sessions.website_session_id
        AND website_pageviews.website_pageview_id > 23504
        AND utm_source = 'gsearch'
        AND utm_campaign = 'nonbrand'
GROUP BY 
	website_pageviews.website_session_id;




-- Add the pageview_url and store in a temporary table
CREATE TEMPORARY TABLE all_sessions_with_landing_page_url
SELECT
   all_sessions_without_landing_page_url.website_session_id,
    all_sessions_without_landing_page_url.min_pageview_id,
    website_pageviews.pageview_url
FROM all_sessions_without_landing_page_url
	LEFT JOIN website_pageviews
		ON all_sessions_without_landing_page_url.min_pageview_id = website_pageviews.website_pageview_id
WHERE pageview_url IN ('/home', '/lander-1');



-- Step 3: identify "bounced" sessions
CREATE TEMPORARY TABLE 	all_bounced_sessions_w_landing_page
SELECT
    all_sessions_with_landing_page_url.website_session_id,
    all_sessions_with_landing_page_url.pageview_url,
    COUNT(website_pageviews.website_pageview_id) AS bounced_sessions
FROM all_sessions_with_landing_page_url
	LEFT JOIN website_pageviews
		ON all_sessions_with_landing_page_url.website_session_id = website_pageviews.website_session_id
GROUP BY 
    all_sessions_with_landing_page_url.website_session_id,
    all_sessions_with_landing_page_url.pageview_url
HAVING
	COUNT(website_pageviews.website_pageview_id) = 1;

    
    
 -- Step 4: summarize total sessions and bounced sessions, by landing page (LP)
SELECT 
    all_sessions_with_landing_page_url.website_session_id AS sessions,
    all_sessions_with_landing_page_url.pageview_url AS landing_page,
    all_bounced_sessions_w_landing_page.website_session_id AS bounced_sessions
FROM all_sessions_with_landing_page_url
	LEFT JOIN all_bounced_sessions_w_landing_page
		ON all_sessions_with_landing_page_url.website_session_id = all_bounced_sessions_w_landing_page.website_session_id;

-- Final Output:

SELECT 
    all_sessions_with_landing_page_url.pageview_url AS landing_page,
    COUNT(DISTINCT all_sessions_with_landing_page_url.website_session_id) AS sessions,
    COUNT(DISTINCT all_bounced_sessions_w_landing_page.website_session_id) AS bounced_sessions,
    COUNT(DISTINCT all_bounced_sessions_w_landing_page.website_session_id) / COUNT(DISTINCT all_sessions_with_landing_page_url.website_session_id) AS bounce_rate
FROM all_sessions_with_landing_page_url
	LEFT JOIN all_bounced_sessions_w_landing_page
		ON all_sessions_with_landing_page_url.website_session_id = all_bounced_sessions_w_landing_page.website_session_id
GROUP BY
	landing_page;
    
    


 -- -----------------------------------------------------------------------------------------------------
 -- A/B Testing: what is the volume of sessions for '/home' and '/lander-1' (Paid Search, Nonbrand), trended MONTHLY. Calcuate bounce rates as well.

/* Steps to solve the problem:
    Step 1: Filter for Paid, Nonbrand by month
    Step 2: find the first website_pageview_id for relevant sessions and their relevent landing page (url): /home and /lander-1
    Step 3: identify "bounced" sessions
    Step 4: summarize total sessions and bounced sessions, by MONTH (LP)
*/


SELECT * FROM website_sessions;
SELECT * FROM website_pageviews;


-- Combine Step 1 & Step 2 to get min_pageview_id and COUNT of pages viewed per session
CREATE TEMPORARY TABLE sessions_with_min_pv_id_and_view_count
SELECT 
    website_sessions.website_session_id,
    MIN(website_pageviews.website_pageview_id) AS first_pageview_id,
    COUNT(website_pageviews.website_pageview_id) AS count_pageviews
FROM website_sessions
	LEFT JOIN website_pageviews
		ON website_sessions.website_session_id = website_pageviews.website_session_id
WHERE website_sessions.utm_source = 'gsearch'
    AND website_sessions.utm_campaign = 'nonbrand'
GROUP BY
    website_sessions.website_session_id;


-- Combine Step 3 & Step 4 to add pageview_url &  summarize total sessions and bounced sessions
CREATE TEMPORARY TABLE sessions_with_counts_lander_and_created_at
SELECT
    sessions_with_min_pv_id_and_view_count.website_session_id,
    sessions_with_min_pv_id_and_view_count.first_pageview_id,
    sessions_with_min_pv_id_and_view_count.count_pageviews,
    website_pageviews.pageview_url AS landing_page,
    website_pageviews.created_at AS session_created_at
FROM sessions_with_min_pv_id_and_view_count
	LEFT JOIN website_pageviews
		ON sessions_with_min_pv_id_and_view_count.first_pageview_id = website_pageviews.website_pageview_id;


-- Summarize and provide final output:

SELECT
   MIN(DATE(session_created_at)) AS week_start_date,
   -- COUNT(DISTINCT website_session_id) AS total_sessions,
   -- COUNT(DISTINCT CASE WHEN count_pageviews = 1 THEN website_session_id ELSE NULL END) AS bounced_sessions,
    COUNT(DISTINCT CASE WHEN count_pageviews = 1 THEN website_session_id ELSE NULL END)*1.0 / COUNT(DISTINCT website_session_id) AS bounce_rate,
    COUNT(DISTINCT CASE WHEN landing_page = '/home' THEN website_session_id ELSE NULL END) AS home_sessions,
    COUNT(DISTINCT CASE WHEN landing_page = '/lander-1' THEN website_session_id ELSE NULL END) AS lander_sessions
FROM sessions_with_counts_lander_and_created_at
WHERE session_created_at <= '2013-03-01'
GROUP BY
    YEAR(session_created_at),
    MONTH(session_created_at);
    
-- Feb 2012 was the last month the 'lander-1' page was live, page 'lander-2' replaced 'lander-1' beginning March 2012


-- -----------------------------------------------------------------------------------------------------
-- ------------------------------- Building Conversion Funnels
/*
	Business Context:
	   - Build a conversion funnel from '/lander-1' to '/thank-you' for the mrfuzzy product
           - How many people reach each step (and also drop off)


    Steps to Build a Conversion Funnel
	- Step 1: select all relevant sessions (first 'lander-1' website_pageview_id 23504 & last 'lander-1' website_pageview_id 173471)
	     -- Funnel: '/lander-1' -> '/products' -> '/the-original-mr-fuzzy' -> '/cart' -> '/shipping' -> '/billing'

        - Step 2: identify each relevant pageview as the specific funnel step
        - Step 3: create session-level conversion view
        - Step 4: aggregate the data to assess funnel performance
        
*/

SELECT * FROM website_sessions;
SELECT * FROM website_pageviews;


-- Step 1: select all relevant sessions
SELECT 
    website_sessions.website_session_id,
    website_pageviews.created_at AS pageview_created_at,
    website_pageviews.pageview_url,
    CASE WHEN pageview_url = '/lander-1' THEN 1 ELSE 0 END AS lander_1_page,
    CASE WHEN pageview_url = '/products' THEN 1 ELSE 0 END AS products_page,
    CASE WHEN pageview_url = '/the-original-mr-fuzzy' THEN 1 ELSE 0 END AS mrfuzzy_page,
    CASE WHEN pageview_url = '/cart' THEN 1 ELSE 0 END AS cart_page,
    CASE WHEN pageview_url = '/shipping' THEN 1 ELSE 0 END AS shipping_page,
    CASE WHEN pageview_url = '/billing' THEN 1 ELSE 0 END AS billing_page,
    CASE WHEN pageview_url = '/thank-you-for-your-order' THEN 1 ELSE 0 END AS thankyou_page
FROM website_sessions
	LEFT JOIN website_pageviews
		ON website_pageviews.website_session_id = website_sessions.website_session_id
WHERE website_pageviews.website_pageview_id >= 23504
	AND website_pageviews.website_pageview_id <= 173471
	AND website_sessions.utm_source = 'gsearch'
    AND website_sessions.utm_campaign = 'nonbrand'
    AND website_pageviews.pageview_url IN ('/lander-1', '/products', '/the-original-mr-fuzzy', '/cart', '/shipping', '/billing', '/thank-you-for-your-order');


-- Step 2 & Step 3 : identify each relevant pageview as the specific funnel step || create session-level conversion view

CREATE TEMPORARY TABLE session_level_made_it
SELECT
    website_session_id,
    MAX(lander_1_page) AS made_to_lander1,
    MAX(products_page) AS made_to_products,
    MAX(mrfuzzy_page) AS made_to_mrfuzzy,
    MAX(cart_page) AS made_to_cart,
    MAX(shipping_page) AS made_to_shipping,
    MAX(billing_page) AS made_to_billing,
    MAX(thankyou_page) AS made_to_thankyou
FROM
	(
		SELECT 
			website_sessions.website_session_id,
			website_pageviews.created_at AS pageview_created_at,
			website_pageviews.pageview_url,
			CASE WHEN pageview_url = '/lander-1' THEN 1 ELSE 0 END AS lander_1_page,
			CASE WHEN pageview_url = '/products' THEN 1 ELSE 0 END AS products_page,
			CASE WHEN pageview_url = '/the-original-mr-fuzzy' THEN 1 ELSE 0 END AS mrfuzzy_page,
			CASE WHEN pageview_url = '/cart' THEN 1 ELSE 0 END AS cart_page,
			CASE WHEN pageview_url = '/shipping' THEN 1 ELSE 0 END AS shipping_page,
			CASE WHEN pageview_url = '/billing' THEN 1 ELSE 0 END AS billing_page,
			CASE WHEN pageview_url = '/thank-you-for-your-order' THEN 1 ELSE 0 END AS thankyou_page
		FROM website_sessions
			LEFT JOIN website_pageviews
				ON website_pageviews.website_session_id = website_sessions.website_session_id
		WHERE website_pageviews.website_pageview_id >= 23504
			AND website_pageviews.website_pageview_id <= 173471
			AND website_sessions.utm_source = 'gsearch'
			AND website_sessions.utm_campaign = 'nonbrand'
			AND website_pageviews.pageview_url IN ('/lander-1', '/products', '/the-original-mr-fuzzy', '/cart', '/shipping', '/billing', '/thank-you-for-your-order')
	) AS pageview_level
GROUP BY
	website_session_id
ORDER BY 
	website_session_id;


SELECT * FROM session_level_made_it;




-- Step 4: aggregate the data to assess funnel performance
SELECT
    COUNT(DISTINCT website_session_id) AS total_sessions,
    COUNT(DISTINCT CASE WHEN made_to_lander1 = 1 THEN website_session_id ELSE NULL END) AS to_lander_1,
    COUNT(DISTINCT CASE WHEN made_to_products = 1 THEN website_session_id ELSE NULL END) AS to_products, 
    COUNT(DISTINCT CASE WHEN made_to_mrfuzzy = 1 THEN website_session_id ELSE NULL END) AS to_mrfuzzy,
    COUNT(DISTINCT CASE WHEN made_to_cart = 1 THEN website_session_id ELSE NULL END) AS to_cart,
    COUNT(DISTINCT CASE WHEN made_to_shipping = 1 THEN website_session_id ELSE NULL END) AS to_shipping,
    COUNT(DISTINCT CASE WHEN made_to_billing = 1 THEN website_session_id ELSE NULL END) AS to_billing
FROM session_level_made_it;


-- Final Output: (conversion rates)

SELECT
    COUNT(DISTINCT website_session_id) AS total_sessions,
    
    COUNT(DISTINCT CASE WHEN made_to_lander1 = 1 THEN website_session_id ELSE NULL END)
		/ COUNT(DISTINCT website_session_id) AS made_to_lander_1,
        
	COUNT(DISTINCT CASE WHEN made_to_products = 1 THEN website_session_id ELSE NULL END) 
		/ COUNT(DISTINCT CASE WHEN made_to_lander1 = 1 THEN website_session_id ELSE NULL END) AS made_to_products, 
        
    COUNT(DISTINCT CASE WHEN made_to_mrfuzzy = 1 THEN website_session_id ELSE NULL END) 
		/ COUNT(DISTINCT CASE WHEN made_to_products = 1 THEN website_session_id ELSE NULL END) AS made_to_mrfuzzy,
        
    COUNT(DISTINCT CASE WHEN made_to_cart = 1 THEN website_session_id ELSE NULL END) 
		/ COUNT(DISTINCT CASE WHEN made_to_mrfuzzy = 1 THEN website_session_id ELSE NULL END) AS made_to_cart,
        
    COUNT(DISTINCT CASE WHEN made_to_shipping = 1 THEN website_session_id ELSE NULL END) 
		/ COUNT(DISTINCT CASE WHEN made_to_cart = 1 THEN website_session_id ELSE NULL END) AS made_to_shipping,
        
    COUNT(DISTINCT CASE WHEN made_to_billing = 1 THEN website_session_id ELSE NULL END) 
		/ COUNT(DISTINCT CASE WHEN made_to_shipping = 1 THEN website_session_id ELSE NULL END) AS made_to_billing
        
FROM session_level_made_it;



-- -----------------------------------------------------------------------------------------------------
/*
    Business Context:
	- A new billing page was created. Perform an A/B to check whether '/billing-2' is doing any better than '/billing'
        - What % of sessions on those pages end up placing an order?
    
    Steps to Build a Conversion Funnel
	- Step 1: find when '/billing-2' went live
	- Step 2: select all relevant sessions (nonbrand) [when '/billing-2' went live to Nov 10]
		-- Funnel: 
                           '/billing' -> '/thank-you-for-your-order'
	                   '/billing-2' -> '/thank-you-for-your-order'
        - Step 3: create billing-level conversion view (sessions -> order)
        - Step 4: aggregate the data to assess funnel performance
        
*/



-- Step 1: find when '/billing-2' went live
		-- '/billing-2' went live on Sep 10; first website_pageview_id = 53550

SELECT MIN(website_pageview_id)
FROM website_pageviews
WHERE pageview_url = '/billing-2';

SELECT *
FROM website_pageviews
WHERE website_pageview_id = 53550;



-- Step 2: select all relevant sessions [when '/billing-2' went live to Nov 10]

SELECT
    website_pageviews.website_session_id,
    website_pageviews.pageview_url AS billing_version_seen,
    orders.order_id
FROM website_pageviews
	LEFT JOIN orders
		ON orders.website_session_id = website_pageviews.website_session_id
WHERE website_pageviews.website_pageview_id >= 53550
    AND website_pageviews.created_at < '2012-11-10' -- arbitruary date to fairly compare both billing pages (two months of data where 'billing-2' went live
    AND website_pageviews.pageview_url IN ('/billing', '/billing-2');


-- Step 3 & 4 : create billing-level conversion view (sessions -> order) || aggregate the data to assess funnel performance
	-- Final Output:

SELECT
    billing_version_seen,
    COUNT(DISTINCT website_session_id) AS sessions,
    COUNT(DISTINCT order_id) AS orders,
    COUNT(DISTINCT order_id) / COUNT(DISTINCT website_session_id)  AS billing_to_order

FROM
		(
			SELECT
				website_pageviews.website_session_id,
				website_pageviews.pageview_url AS billing_version_seen,
				orders.order_id
			FROM website_pageviews
				LEFT JOIN orders
					ON orders.website_session_id = website_pageviews.website_session_id
			WHERE website_pageviews.website_pageview_id >= 53550
				AND website_pageviews.created_at < '2012-11-10'
				AND website_pageviews.pageview_url IN ('/billing', '/billing-2')
		) AS billing_level

GROUP BY
	billing_version_seen;













 
 
