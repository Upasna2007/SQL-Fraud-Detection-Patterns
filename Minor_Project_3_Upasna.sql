-- =================================================================================================
--                                      MINOR PROJECT - 3 
-- =================================================================================================
-- Name : Upasna Sunil Bhostekar
-- Topic - RedFlag : The Fraud Files 
-- =================================================================================================

USE redflag;

SELECT COUNT(*) FROM redflag.transactions ;
-- op : count = 200594

-- -----------------------------------------------------------------------------

SELECT COUNT(DISTINCT user_id) AS unique_users
FROM redflag.transactions ; 
-- op : unique_users = 14755

-- -----------------------------------------------------------------------------

SELECT 
     MIN(txn_time) AS earliest_transaction,
     MAX(txn_time) AS latest_transaction 
FROM redflag.transactions ; 
-- op :     earliest_transaction = 2024-01-01  00:05:26
--          latest_transaction   = 2024-06-28  23:59:20 

-- -----------------------------------------------------------------------------
-- Let's see the structure of table first
DESCRIBE transactions ;

-- -----------------------------------------------------------------------------
-- Let's observe some data
SELECT * 
FROM transactions 
LIMIT 10 ;   -- to see 10 rows from table 

-- -----------------------------------------------------------------------------
-- Let's check different transaction types 
SELECT DISTINCT txn_type
FROM transactions ; 
-- op : Debit,  Refund,  Credit 

-- -----------------------------------------------------------------------------
-- Let's check different payment modes now 
SELECT DISTINCT payment_mode 
FROM transactions ; 
-- op : UPI,  Card,  Wallet,  NetBanking 

-- -----------------------------------------------------------------------------
-- Let's see transactions status now 
SELECT DISTINCT status 
FROM transactions ; 

-- -----------------------------------------------------------------------------
-- Let's go through basic amount statistics 
SELECT 
     MIN(amount) AS minimum_amount,
     MAX(amount) AS maximum_amount,
     AVG(amount) AS average_amount 
FROM transactions ; 

-- op : mininum = 1,  maximum = 99882.92,  avg = 3932.216


-- ==================================================================================================
--                                  TIER 1 - 5 patterns
-- ==================================================================================================
--   PATTERN - 1 : VELOCITY FRAUD 
-- --------------------------------------------------------------------------------------------------
--  Find users who performs unusually large number of transactions in a day 
-- --------------------------------------------------------------------------------------------------

SELECT 
      user_id, 
      DATE(txn_time) AS txn_date,
      COUNT(*) AS total_txn
FROM transactions 
GROUP BY 
      user_id, 
      DATE(txn_time) 
HAVING COUNT(*) >= 30 
ORDER BY total_txn DESC ;

/* op : 14556	2024-05-28	60
14569	2024-04-03	60
14559	2024-06-04	59
14564	2024-02-15	59
14566	2024-03-15	59
14557	2024-03-10	58
14567	2024-01-17	57
14571	2024-02-19	55
14527	2024-02-03	53
14514	2024-02-21	53
14572	2024-02-06	52
14526	2024-05-30	52
14575	2024-03-29	52
14523	2024-03-03	51
14507	2024-05-10	50
14530	2024-03-22	50
14573	2024-04-01	50
14520	2024-01-21	49
14521	2024-06-06	48
14518	2024-04-15	48
14508	2024-03-18	48
14529	2024-02-10	47
14525	2024-05-24	46
14513	2024-02-28	45
14565	2024-03-04	45
14519	2024-02-22	45
14510	2024-04-19	45
14511	2024-06-20	45
14512	2024-02-25	44
14504	2024-01-10	44
14574	2024-05-06	43
14503	2024-03-11	41
14524	2024-06-24	41
14558	2024-04-25	40
14517	2024-06-23	40
14516	2024-03-19	39
14506	2024-03-08	38
14502	2024-05-31	38
14501	2024-04-14	37
14505	2024-03-11	37
14515	2024-03-23	36
14570	2024-05-02	36
14509	2024-02-06	36
14528	2024-06-08	36
14561	2024-04-02	35
14522	2024-05-27	35
14568	2024-01-23	34
14562	2024-06-24	33
14560	2024-06-11	32
14563	2024-01-21	31    */ 

-- op : There are total 50 users 
-- who performs more than 30 transations in a single day 
-- This may indicate Velocity Fraud 


-- ==================================================================================================
--   PATTERN - 2 : ROUND - AMOUNT CLUSTERING 
-- --------------------------------------------------------------------------------------------------
--  Find users who makes repeated round value transactions 
-- --------------------------------------------------------------------------------------------------

SELECT 
      user_id,
      COUNT(*) AS round_transaction_count
FROM transactions 
WHERE amount IN (100, 200, 500, 1000, 2000, 5000, 10000)
GROUP BY user_id
HAVING COUNT(*) >= 15
ORDER BY round_transaction_count DESC ;

/* op :  14533	30
14534	30
14535	30
14532	29
14539	29
14541	29
14549	29
14548	28
14531	27
14555	27
14538	26
14537	25
14544	25
14543	24
14545	24
14547	24
14551	24
14554	24
14536	22
14546	22
14550	21
14542	20
14552	19
14540	18
14553	18  */

-- op : Total users = 25
-- there are 25 users who has 15 or more transactions
-- with round amounts like 100, 200, 500,......10000

-- this round money leads to money withdrawls 
-- This is called Round - Amount Clustering 



-- ==================================================================================================
--   PATTERN - 3 : CARD TESTING  
-- --------------------------------------------------------------------------------------------------
--  Find frauds who usually check stolen cards by checking 1,2, 3 rupees transaction
-- --------------------------------------------------------------------------------------------------

SELECT 
      user_id,
      DATE(txn_time),
      COUNT(*) AS short_transaction_count
FROM transactions 
WHERE amount < 10
GROUP BY 
      user_id,
      DATE(txn_time)
HAVING COUNT(*) >= 30
ORDER BY short_transaction_count DESC ;

/*op :  14569	2024-04-03	60
14556	2024-05-28	60
14564	2024-02-15	59
14566	2024-03-15	59
14559	2024-06-04	59
14557	2024-03-10	58
14567	2024-01-17	57
14571	2024-02-19	55
14572	2024-02-06	52
14575	2024-03-29	52
14573	2024-04-01	50
14565	2024-03-04	45
14574	2024-05-06	43
14558	2024-04-25	40
14570	2024-05-02	36
14561	2024-04-02	35
14568	2024-01-23	34
14562	2024-06-24	33
14560	2024-06-11	32
14563	2024-01-21	31       */ 

-- op : Total suspects = 20
-- there are 20 users who has 30 or more transactions
-- with amount less than 10 rupees 

-- this gives hint of card checking that fraud persons do 
-- Here we done with Card Testing... 


-- ==================================================================================================
--   PATTERN - 4 : Failed-Then-Succeeded  
-- --------------------------------------------------------------------------------------------------
--  Find suspects who tried many attempts and failed several times 
-- --------------------------------------------------------------------------------------------------

SELECT 
     user_id,
     COUNT(*) AS failed_txn_count
FROM transactions 
WHERE status = 'FAILED'
GROUP BY user_id
HAVING COUNT(*) >= 20
ORDER BY failed_txn_count DESC ;  

/* op : 14595	35
14593	34
14576	33
14580	32
14581	32
14599	32
14585	31
14589	31
14590	31
14591	31
14594	31
14592	30
14597	29
14579	28
14600	28
14584	27
14598	27
14582	26
14583	26
14596	25
14586	23
14577	22
14587	21
14588	21
14578	20    */

-- op :  Total suspects = 25
-- Hence, 25 users were caught with 20 or more failed transactions 
-- The highest number of failed transactions was by user_id = 14595
-- This user had 35 failed transactions which is suspicious......alter



-- ==================================================================================================
--   PATTERN - 5 :  Odd-Hour Concentration  
-- --------------------------------------------------------------------------------------------------
--  Find users who perform transactions at midnight between 2am to 5am 
-- --------------------------------------------------------------------------------------------------

SELECT 
     user_id, 
     COUNT(*) AS total_txn_count
FROM transactions 
GROUP BY user_id
HAVING 
     COUNT(*) >= 30
     AND
	 SUM(
       CASE 
		  WHEN HOUR(txn_time) BETWEEN 2 AND 4
		  THEN 1
          ELSE 0
	   END
	 ) * 1.0 / COUNT(*) >= 0.80
ORDER BY total_txn_count DESC ;
          
/* op :  14608	63
14607	53
14606	52
14610	52
14617	52
14616	51
14618	51
14605	50
14609	48
14613	48
14611	47
14614	47
14604	46
14612	46
14615	45
14620	45
14601	42
14603	40
14602	35
14619	33   */

-- op : Total users suspected = 20
-- It means we caught 20 users who has minimum 80% of their transaction
-- between 2 to 5 and have at least 30 transations 

-- The most suspected user_id = 14608 
-- Observed that he had 63 transactions betwwen 2 to 5 which is very high



-- ==================================================================================================
--                                  TIER 2 - 5 patterns
-- ==================================================================================================
--   PATTERN - 6 :  Mule Accounts  
-- --------------------------------------------------------------------------------------------------
--  Find users who made 8 or more CREDIT transactions bcoz they may have mule accounts 
-- --------------------------------------------------------------------------------------------------
 
 SELECT 
      user_id, 
      COUNT(*) AS credit_txn_count
FROM transactions
WHERE txn_type = 'CREDIT'
GROUP BY user_id
HAVING COUNT(*)>= 8
ORDER BY credit_txn_count DESC ;

/* op :  14630	15
14637	15
14640	15
14643	15
14645	15
14628	14
14622	13
14632	13
14636	13
14646	13
14647	13
14621	12
14625	12
14631	12
14633	11
14644	11
14649	11
14626	10
14639	10
14650	10
14623	9
14627	9
14634	9
14635	9
14638	9
14624	8
14629	8
14641	8
14642	8
14648	8     */

-- op :  Total users = 30
-- 30 users caught with 8 or more CREDIT transactions 
-- such users may have Mule Accounts 




-- ==================================================================================================
--   PATTERN - 7 :  Refund Abuse  
-- --------------------------------------------------------------------------------------------------
--  Find users who have more than 20 transactions & more than 40% are Refund
-- --------------------------------------------------------------------------------------------------

 SELECT 
      user_id, 
      COUNT(*) AS total_txn_count
FROM transactions
GROUP BY user_id
HAVING 
      COUNT(*)>= 20
      AND
      SUM(
         CASE 
             WHEN txn_type = 'REFUND'
             THEN 1
             ELSE 0
		 END
	  ) * 1.0 / COUNT(*) > 0.40
ORDER BY total_txn_count DESC ;

/* op :  14651	26
14652	27
14653	55
14654	37
14655	53
14656	57
14657	60
14658	51
14659	60
14660	30
14661	36
14662	39
14664	42
14665	36
14666	52
14667	41
14668	47
14669	28
14670	50
14671	53
14672	39
14673	37
14674	40
14675	58     */

-- op : Total users = 24
-- So here i got 24 users who have 20 or more transactions
-- and their Refund ratio is > than 40% 




-- ==================================================================================================
--   PATTERN - 8 :  Merchant Collusion 
-- --------------------------------------------------------------------------------------------------
--  Find top 5 users who contributes more than 60% to merhcant's gain 
-- --------------------------------------------------------------------------------------------------

WITH Users_Total AS ( 
    SELECT
        merchant_id,
        user_id,
		SUM(amount) AS total_amt 
        FROM transactions
        GROUP BY
			 merchant_id,
			 user_id 
),

Ranked_Users AS (        
    SELECT 
        merchant_id, 
        user_id,
        total_amt,
        ROW_NUMBER() OVER(
		    PARTITION BY merchant_id
		    ORDER BY total_amt DESC 
	    ) AS rank_number 
    FROM Users_Total 
),

Merchant_total AS (
    SELECT 
		merchant_id, 
        SUM(amount) AS merchant_total
	FROM transactions
    GROUP BY merchant_id 
)

SELECT 
	 r.merchant_id,
    SUM(r.total_amt) AS top5_amount,
    m.merchant_total,
    ROUND((SUM(r.total_amt) * 100.0) / m.merchant_total,2) AS top5_percentage
FROM Ranked_Users r
JOIN Merchant_Total m
ON r.merchant_id = m.merchant_id
WHERE r.rank_number <= 5
GROUP BY
    r.merchant_id,
    m.merchant_total
HAVING
    (SUM(r.total_amt) * 1.0 / m.merchant_total) > 0.60
ORDER BY top5_percentage DESC;


/*  op :   12	2175353.42	2177212.35	99.91
8	1611603.39	1613683.91	99.87
13	1915648.42	1918510.08	99.85
2	1954904.43	1958233.33	99.83
10	1422198.57	1424759.64	99.82
3	1478049.01	1481098.40	99.79
15	1278701.46	1281399.80	99.79
4	1864404.64	1868675.99	99.77
9	2134602.31	2139820.91	99.76
11	1605254.31	1609203.38	99.75
1	1573131.69	1577167.72	99.74
7	1925429.68	1930505.18	99.74
6	1318203.35	1322017.55	99.71
14	1730924.72	1735925.41	99.71
5	2118932.93	2125209.64	99.70  */

-- op : Total users = 15
-- Most suspicious = merchant_id= 12  : 99.91% 
-- these all users have contribute to merchants more than 60% of their amount 
-- this look very suspicious 
-- these merchants can be involved in merchant collusion 

-- New concepts I learned while working on this pattern 
-- 1. Common Table Expression (CTE) - creates temporary result set that can be used later in the query 
-- 2. Window Function : ROW_NUMBER() - It assigns sequential numbers to rows 
-- 3. Partition by - splits data in separate groups before ranking 




-- ==================================================================================================
--   PATTERN - 9 :  Just-Under-Threshold (Structuring) 
-- --------------------------------------------------------------------------------------------------
--  Find users who have more than 10 transactions with amount 9,999 rupees 
-- Fraudster avoids transactions of 10k or more than it with amounts like 9,999
-- This is called as Structuring/ Smurfing 
-- --------------------------------------------------------------------------------------------------

SELECT 
     user_id,
     COUNT(*) AS txn_fix_amount
FROM transactions 
WHERE amount = 9999.00
GROUP BY user_id
HAVING COUNT(*) >= 10
ORDER BY txn_fix_amount DESC ; 

/* op :  14680	25
14690	25
14693	22
14684	21
14689	21
14691	20
14686	17
14695	17
14679	16
14676	15
14678	15
14677	14
14692	14
14694	13
14681	12
14685	12
14687	12
14682	11
14683	10
14688	10      */

-- op : Total suspects caught = 20
-- this 20 users have 10 or more transactions with exact amount 9999.00 rupees 
-- this may indicates smurfing to avoid KYC verifications process 




-- ==================================================================================================
--   PATTERN - 10 :  Dormant-Then-Active 
-- --------------------------------------------------------------------------------------------------
--  Find users who were inactive for 90 or 90+ days 
-- and suddenly get active with 15 or more transactions 
-- --------------------------------------------------------------------------------------------------

WITH Dormant_users AS (

    SELECT 
        user_id,
        txn_time,
     
        LAG(txn_time) OVER(
            PARTITION BY user_id
            ORDER BY txn_time
		) AS previous_txn_time, 
     
        DATEDIFF(
            txn_time,
            LAG(txn_time) OVER(
                PARTITION BY user_id
                ORDER BY txn_time 
		    )
		) AS days_gap 
     
	FROM transactions 
)    

SELECT 
     d.user_id,
     COUNT(t.txn_id) AS post_gap_txn 
FROM Dormant_Users d

JOIN transactions t
ON d.user_id = t.user_id 
AND t.txn_time >= d.txn_time 
 
WHERE d.days_gap >= 90  
GROUP BY d.user_id
HAVING COUNT(t.txn_id) >= 15
ORDER BY post_gap_txn DESC ; 

/* op  : 14526	55
14701	28
14708	28
14720	27
14707	26
14711	26
14714	26
14716	26
14698	25
14704	25
14696	24
14699	24
14710	24
14713	24
14715	24
14719	24
14703	23
14717	23
14705	22
14709	21
14706	19
14712	19
14697	18
14702	18
14718	18
14700	17     */

-- op : Total users got = 26
-- It means 26 users were inactive for 90 or 90+ days 
-- Then they suddenly made 15 or 15+ transactions 
-- These users are suspicious to attack dormant accounts 





-- ==================================================================================================
--                                  TIER 3 - 2 patterns
-- ==================================================================================================
--   PATTERN - 11 :  Velocity Spike  
-- --------------------------------------------------------------------------------------------------
--  Find users whose peak monthly transaction is 5x more than avg monthly txns 
-- PLus busiest moneth has at least 20 transactions  
-- --------------------------------------------------------------------------------------------------

WITH Monthly_Count AS (

	SELECT 
		user_id,
        YEAR(txn_time) AS txn_year,
		MONTH(txn_time) AS txn_month,
        COUNT(*) AS monthly_txn
	FROM transactions 
    GROUP BY 
		user_id,
        YEAR(txn_time),
        MONTH(txn_time) 
),

-- let's calculate Average and Peak now 
User_Stats AS (
     SELECT 
         user_id,
         AVG(monthly_txn) AS avg_monthly_txn,
         MAX(monthly_txn) AS peak_monthly_txn
	 FROM Monthly_Count 
     GROUP BY user_id
)

-- let's check now 
-- Peak>=20 & Peak/avg >=5
SELECT 
     user_id,
     avg_monthly_txn,
     peak_monthly_txn,
     ROUND(peak_monthly_txn * 1.0 / avg_monthly_txn ,2) AS spike_ratio
FROM User_Stats
WHERE 
     peak_monthly_txn >= 20
     AND 
     (peak_monthly_txn * 1.0 / avg_monthly_txn) >= 5 
ORDER BY spike_ratio DESC ; 

/* op :  14517	8.0000	41	5.13
14504	8.8333	45	5.09
14528	7.6667	39	5.09   */ 

-- op : Users = 3
-- user_id = 14517, 14504, 14528 
-- this users have 5x more transaction that avg monthly txns 




-- ==================================================================================================
--   PATTERN - 12 :  Geographic Impossibility 
-- --------------------------------------------------------------------------------------------------
--  Find users who made two consecutive transactions in diff cities
-- within 60 minutes
-- --------------------------------------------------------------------------------------------------

WITH Geographic_Check AS (

	SELECT
        user_id,
        txn_time,
        city,
        LAG(city) OVER(
            PARTITION BY user_id 
            ORDER BY txn_time
		) AS previous_city,
        
        LAG(txn_time) OVER(
             PARTITION BY user_id 
            ORDER BY txn_time
		) AS previous_txn_time 
        
	 FROM transactions
)

-- let's check time diff
SELECT 
     user_id,
     previous_city,
     city,
     previous_txn_time,
     txn_time,
     TIMESTAMPDIFF(
         MINUTE,
         previous_txn_time,
         txn_time
	 ) AS time_diff 
FROM Geographic_Check 

-- let's compare cities now 
WHERE
     city <> previous_city
     AND 
     TIMESTAMPDIFF(
         MINUTE,
         previous_txn_time,
         txn_time
	 ) <= 60
ORDER BY user_id ;

/*   op :  14741	Vadodara	Thiruvananthapuram	2024-03-13 12:33:23	2024-03-13 13:03:23	30
14741	Chandigarh	Pune	2024-03-27 17:06:21	2024-03-27 17:53:21	47
14741	Hyderabad	Delhi	2024-04-16 09:18:31	2024-04-16 09:57:31	39
14741	Jaipur	Pune	2024-05-20 11:43:20	2024-05-20 12:11:20	28
14742	Vadodara	Thiruvananthapuram	2024-01-23 18:56:17	2024-01-23 19:40:17	44
14742	Hyderabad	Thiruvananthapuram	2024-01-26 00:13:40	2024-01-26 00:42:40	29
14742	Surat	Chennai	2024-05-26 00:11:13	2024-05-26 00:29:13	18
14743	Kolkata	Ahmedabad	2024-01-10 14:39:17	2024-01-10 15:27:17	48
14743	Indore	Coimbatore	2024-02-12 20:32:56	2024-02-12 21:03:56	31
14743	Pune	Lucknow	2024-02-14 12:57:43	2024-02-14 13:38:43	41
14743	Kochi	Thiruvananthapuram	2024-02-28 01:14:05	2024-02-28 01:30:05	16
14743	Delhi	Thiruvananthapuram	2024-03-03 05:55:26	2024-03-03 06:24:26	29
14743	Delhi	Bengaluru	2024-05-16 22:06:09	2024-05-16 22:41:09	35
14743	Kochi	Nagpur	2024-06-22 08:13:25	2024-06-22 08:49:25	36
14744	Kochi	Delhi	2024-03-03 12:26:34	2024-03-03 13:01:34	35
14744	Delhi	Surat	2024-03-06 16:05:38	2024-03-06 16:23:38	18
14744	Vadodara	Lucknow	2024-04-22 14:20:55	2024-04-22 14:42:55	22
14745	Thiruvananthapuram	Kochi	2024-01-17 20:28:09	2024-01-17 20:47:09	19
14745	Thiruvananthapuram	Surat	2024-05-07 11:08:16	2024-05-07 11:25:16	17
14745	Surat	Thiruvananthapuram	2024-05-07 11:25:16	2024-05-07 11:34:40	9
14745	Nagpur	Visakhapatnam	2024-06-11 17:10:08	2024-06-11 17:25:08	15
14746	Mumbai	Lucknow	2024-01-01 19:43:05	2024-01-01 20:13:05	30
14746	Visakhapatnam	Surat	2024-01-21 10:21:54	2024-01-21 10:55:54	34
14746	Ahmedabad	Thiruvananthapuram	2024-02-09 19:42:44	2024-02-09 20:27:44	45
14746	Bhopal	Surat	2024-06-02 20:11:24	2024-06-02 20:54:24	43
14746	Delhi	Chandigarh	2024-06-10 14:59:03	2024-06-10 15:23:03	24
14746	Delhi	Coimbatore	2024-06-12 21:48:14	2024-06-12 22:37:14	49
14746	Ahmedabad	Lucknow	2024-06-19 08:34:01	2024-06-19 09:03:01	29
14747	Ahmedabad	Jaipur	2024-03-07 06:49:19	2024-03-07 07:38:19	49
14747	Surat	Chennai	2024-03-17 14:32:16	2024-03-17 14:51:16	19
14747	Hyderabad	Thiruvananthapuram	2024-05-20 11:12:42	2024-05-20 11:51:42	39
14747	Coimbatore	Bhopal	2024-06-17 21:20:47	2024-06-17 22:07:47	47
14748	Ahmedabad	Coimbatore	2024-01-27 11:57:51	2024-01-27 12:46:51	49
14748	Bhopal	Indore	2024-05-04 19:01:37	2024-05-04 19:37:37	36
14748	Jaipur	Chandigarh	2024-05-05 14:17:06	2024-05-05 14:36:06	19
14749	Chennai	Chandigarh	2024-01-09 20:06:13	2024-01-09 20:52:13	46
14749	Bengaluru	Surat	2024-03-26 19:45:55	2024-03-26 20:03:55	18
14749	Pune	Kochi	2024-05-03 12:23:51	2024-05-03 12:48:51	25
14749	Indore	Coimbatore	2024-06-25 11:01:36	2024-06-25 11:16:36	15
14750	Pune	Chennai	2024-01-04 19:38:17	2024-01-04 20:25:17	47
14750	Lucknow	Coimbatore	2024-01-11 16:57:10	2024-01-11 17:47:10	50
14750	Ahmedabad	Kolkata	2024-01-24 14:03:46	2024-01-24 14:28:46	25
14750	Visakhapatnam	Jaipur	2024-04-25 15:53:45	2024-04-25 16:39:45	46
14750	Pune	Visakhapatnam	2024-06-18 17:10:17	2024-06-18 17:52:32	42
14750	Visakhapatnam	Delhi	2024-06-18 17:52:32	2024-06-18 17:54:17	1
14751	Chennai	Thiruvananthapuram	2024-01-16 17:03:11	2024-01-16 17:28:11	25
14751	Visakhapatnam	Kolkata	2024-03-11 21:21:40	2024-03-11 21:45:40	24
14751	Nagpur	Lucknow	2024-03-21 11:35:22	2024-03-21 12:10:22	35
14751	Indore	Surat	2024-03-27 11:15:46	2024-03-27 12:04:46	49
14751	Hyderabad	Lucknow	2024-04-02 08:18:07	2024-04-02 08:37:07	19
14751	Visakhapatnam	Coimbatore	2024-04-07 18:17:54	2024-04-07 18:50:54	33
14751	Pune	Indore	2024-05-22 13:04:12	2024-05-22 13:22:12	18
14752	Bengaluru	Mumbai	2024-02-06 18:52:06	2024-02-06 19:12:06	20
14752	Nagpur	Bengaluru	2024-04-08 21:40:03	2024-04-08 22:00:03	20
14752	Nagpur	Jaipur	2024-04-09 18:12:32	2024-04-09 18:39:32	27
14752	Indore	Bengaluru	2024-05-07 20:09:59	2024-05-07 20:55:59	46
14752	Surat	Nagpur	2024-05-19 20:45:20	2024-05-19 21:18:20	33
14752	Indore	Pune	2024-06-09 14:56:57	2024-06-09 15:39:57	43
14752	Visakhapatnam	Indore	2024-06-19 09:40:01	2024-06-19 10:16:01	36
14753	Lucknow	Delhi	2024-01-17 22:17:13	2024-01-17 22:36:13	19
14753	Hyderabad	Thiruvananthapuram	2024-03-17 21:37:15	2024-03-17 22:08:15	31
14753	Bhopal	Lucknow	2024-04-16 15:40:10	2024-04-16 16:08:10	28
14753	Ahmedabad	Thiruvananthapuram	2024-05-03 09:13:46	2024-05-03 09:58:46	45
14753	Thiruvananthapuram	Delhi	2024-05-14 11:25:58	2024-05-14 12:05:58	40
14753	Thiruvananthapuram	Kochi	2024-06-14 21:48:16	2024-06-14 22:13:16	25
14753	Hyderabad	Nagpur	2024-06-17 09:30:01	2024-06-17 10:05:01	35
14754	Bhopal	Ahmedabad	2024-01-07 10:44:02	2024-01-07 11:02:02	18
14754	Nagpur	Hyderabad	2024-01-11 15:14:09	2024-01-11 15:48:09	34
14754	Delhi	Bhopal	2024-03-18 10:04:38	2024-03-18 10:54:38	50
14754	Ahmedabad	Indore	2024-04-09 16:29:39	2024-04-09 16:49:39	20
14754	Hyderabad	Indore	2024-04-28 12:07:42	2024-04-28 12:51:42	44
14754	Bhopal	Nagpur	2024-06-14 17:46:29	2024-06-14 18:23:29	37
14755	Pune	Chennai	2024-01-17 15:37:06	2024-01-17 16:22:06	45
14755	Chandigarh	Indore	2024-02-02 18:08:42	2024-02-02 18:38:42	30
14755	Kolkata	Delhi	2024-02-03 10:11:29	2024-02-03 11:01:29	50
14755	Indore	Chandigarh	2024-02-24 16:15:39	2024-02-24 16:56:39	41
14755	Kolkata	Visakhapatnam	2024-03-26 15:05:41	2024-03-26 15:51:41	46
14755	Bengaluru	Vadodara	2024-05-27 19:47:49	2024-05-27 20:14:33	26
14755	Vadodara	Surat	2024-05-27 20:14:33	2024-05-27 20:57:33	43
14755	Mumbai	Chandigarh	2024-06-21 16:40:32	2024-06-21 17:14:32	34    */ 

-- op : Suspects Caught = 15
-- These 15 users were caught to made transaction between diff cities
-- within 60 minutes
-- these are suspicious fraudsters 





-- ---------------   Project of Upasna Bhostekar   ----------------------------- 
-- I used AI in last 2-3 complex queries for my understanding and structuring purpose
-- but remaining is done by my own 













