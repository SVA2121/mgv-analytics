SELECT
	CASE 
  		WHEN symbol = 'USDB'
      THEN gives / POW(10, tkn.decimals)
      ELSE gives * POW(1.0001, off.tick) / POW(10, tkn.decimals)
   END AS offered_volume
FROM sgd77.offer off
LEFT JOIN sgd77.market mkt
	ON off.market = mkt.id
LEFT JOIN sgd77.token tkn
	ON mkt.outbound_tkn = tkn.id
WHERE TRUE
	AND UPPER(mkt.block_range) IS NULL
  AND off.gives > 0