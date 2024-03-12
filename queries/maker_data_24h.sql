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
	, COUNT(DISTINCT maker) AS new_makers
  , COUNT(DISTINCT CASE WHEN is_internal THEN maker ELSE NULL END) AS new_internal_makers
	
FROM (
  SELECT
  o.maker
  , CASE
  		WHEN internal.address IS NOT NULL
  		THEN true
  		ELSE false
  	END AS is_internal
  , MIN(o.creation_date) AS creation_date
  , CAST(DATE_TRUNC('DAY', TO_TIMESTAMP(MIN(o.creation_date))) AS DATE) AS creation_day
  FROM sgd70.offer AS o
  LEFT JOIN internal
  	ON LOWER(encode(o.maker, 'hex')) = LOWER(internal.address)
  WHERE TO_TIMESTAMP(o.creation_date) >= CURRENT_TIMESTAMP - INTERVAL '24 hours'
  GROUP BY 1, 2
  ORDER BY 2
) AS subquery
GROUP BY 1
