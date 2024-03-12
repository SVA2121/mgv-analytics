WITH internal(id, address, name, is_kandel, is_collaborator, is_advisor) AS (
    VALUES 
        (0, '4716accb346ddedcda859db0101a0e74bb686700', 'researchMainAccount', 0, 1, 0)
        , (1, 'c852df6f5aB7F22A18388D821093f74e5F0992D0', 'HeKBotAccount', 0, 1, 0)
        , (2, 'F6681cb5f5A5804b159Eb4fdAAe222286c61F6FF', 'MetaStreetAccount', 0, 1, 0)
        , (3, '4e44d45e57021C3ce22433C748669b6ca03F2D5C', 'Kandle_WETH_USDB_1', 1, 1, 0)
        , (4, 'bFa472A82cE3b0f12a890AF735F63860493E0494', 'Kandle_WETH_USDB_2', 1, 1, 0)
        , (5, '0Ce773E17755B00f3E17b87C5C666c9511751261', 'Kandle_WETH_PUNKS20', 1, 1, 0)
  			, (6, '0f0210181f7dac6307878C8EeD6A851b3EF1d3a7', 'Kandle_WETH_PUNKS40', 1, 1, 0)
  
)

SELECT
	creation_day
  , COUNT(DISTINCT taker) AS new_takers
  , SUM(COUNT(DISTINCT taker)) OVER (ORDER BY creation_day) AS cumulative_takers
  , COUNT(DISTINCT CASE WHEN is_internal THEN taker ELSE NULL END) AS new_internal_takers
  , SUM(COUNT(DISTINCT CASE WHEN is_internal THEN taker ELSE NULL END)) OVER (ORDER BY creation_day) AS cumulative_internal_takers
	
FROM (
  SELECT
  o.account AS taker
  , CASE
  		WHEN internal.address IS NOT NULL
  		THEN true
  		ELSE false
  	END AS is_internal
  , MIN(o.creation_date) AS creation_date
  , CAST(DATE_TRUNC('DAY', TO_TIMESTAMP(MIN(o.creation_date))) AS DATE) AS creation_day
  FROM sgd70.offer_filled AS o 
  LEFT JOIN internal
  	ON LOWER(encode(o.account, 'hex')) = LOWER(internal.address)
  GROUP BY 1, 2
  ORDER BY 2
) AS subquery


GROUP BY 1
ORDER BY 1 ASC
