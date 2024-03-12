SELECT
	CASE 
  		WHEN symbol = 'USDB'
      THEN taker_got / POW(10, tkn.decimals)
      ELSE taker_gave / POW(10, tkn.decimals)
   END AS taken_volume
FROM sgd76.order ord
LEFT JOIN sgd76.market mkt
	ON ord.market = mkt.id
LEFT JOIN sgd76.token tkn
	ON mkt.outbound_tkn = tkn.id
WHERE TRUE
	AND UPPER(mkt.block_range) IS NULL
	AND ord.taker_got > 0