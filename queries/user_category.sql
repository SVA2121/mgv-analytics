WITH toto AS (
	SELECT DISTINCT
    CAST(TO_TIMESTAMP(acc.creation_date) AS DATE) AS creation_date
    , ENCODE(acc.address, 'hex') AS address
    , CASE 
  			WHEN ord.taker IS NOT NULL AND (off.maker IS NOT NULL OR off.owner IS NOT NULL) 
  			THEN 'taker_maker'
  			WHEN ord.taker IS NOT NULL AND off.maker IS NULL AND off.owner IS NULL
  			THEN 'taker'
  			WHEN ord.taker IS NULL AND (off.maker IS NOT NULL OR off.owner IS NOT NULL)
  			THEN 'maker'
  			ELSE 'unactive'
  	END AS category
  

  FROM sgd77.account acc
  LEFT JOIN sgd77.order ord
    ON acc.address = ord.taker
  LEFT JOIN sgd77.offer off
    ON acc.address = off.maker
      OR acc.address = off.owner
  WHERE TRUE
    AND UPPER(acc.block_range) IS NULL
  ORDER BY 1 ASC
)

SELECT 
	creation_date
  , address
  , MAX(category) AS category
FROM toto
GROUP BY 1, 2
ORDER BY 1 ASC