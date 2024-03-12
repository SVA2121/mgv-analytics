SELECT
	CASE 
  		WHEN symbol = 'USDB'
      THEN gives / POW(10, tkn.decimals)
      ELSE gives * POW(1.0001, off.tick) / POW(10, tkn.decimals)
   END AS offered_volume
FROM sgd76.offer off
LEFT JOIN sgd76.market mkt
	ON off.market = mkt.id
LEFT JOIN sgd76.token tkn
	ON mkt.outbound_tkn = tkn.id
WHERE TRUE
	AND UPPER(mkt.block_range) IS NULL
  AND off.gives > 0