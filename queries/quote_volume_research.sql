WITH volume AS (
  SELECT
      CAST(TO_TIMESTAMP(ord.creation_date) AS DATE) AS creation_date
      -- , ord.taker_got / POW(10, tkn.decimals)
      -- , ord.taker_gave / POW(10, tkn.decimals)
  		, TO_TIMESTAMP(ord.creation_date) > NOW() - INTERVAL '24' HOUR AS last_24h
      , CASE
          WHEN tkn.symbol = 'USDB'
          THEN taker_got / POW(10, tkn.decimals)
          ELSE taker_gave / POW(10, tkn.decimals)
      END AS quote_volume
  FROM sgd76.order ord
  LEFT JOIN sgd76.market mkt
      ON ord.market = mkt.id
  LEFT JOIN sgd76.token tkn
      ON mkt.outbound_tkn = tkn.id
  WHERE TRUE
  	AND UPPER(mkt.block_range) IS NULL
  	AND UPPER(tkn.block_range) IS NULL
    AND LOWER(ENCODE(ord.taker, 'hex')) = LOWER('4716accb346ddedcda859db0101a0e74bb686700')
 
  ORDER BY 1 ASC
)

SELECT
  creation_date
  , ROUND(SUM(quote_volume), 0) AS quote_volume
  , ROUND(SUM(CASE WHEN last_24h THEN quote_volume ELSE 0 END), 0) AS last_24h_volume
  , COUNT(quote_volume) AS n_transactions
  , SUM(CASE WHEN last_24h THEN 1 ELSE 0 END) AS last_24h_transactions
FROM volume
GROUP BY 1








