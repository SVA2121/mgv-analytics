WITH active_users AS(
  SELECT DISTINCT
	    CAST(TO_TIMESTAMP(creation_date) AS DATE) AS creation_date
  	  , maker AS user
  FROM sgd79.offer
  WHERE 
  UNION ALL
  SELECT DISTINCT
  	CAST(TO_TIMESTAMP(creation_date) AS DATE) AS creation_date
    , taker AS user
  FROM sgd79.order
  ORDER BY 2
)
SELECT 
	creation_date
  , COUNT(user)
FROM active_users
GROUP BY 1
ORDER BY 1 ASC