SELECT
	CASE 
  		WHEN symbol = 'USDB'
      THEN gives / POW(10, tkn.decimals)
      ELSE gives * POW(1.0001, off.tick) / POW(10, tkn.decimals)
   END AS offered_volume
FROM sgd82.offer off
LEFT JOIN sgd82.market mkt
	ON off.market = mkt.id
LEFT JOIN sgd82.token tkn
	ON mkt.outbound_tkn = tkn.id
LEFT JOIN public.market_mapping mkt_map
	ON mkt.id = mkt_map.id
WHERE TRUE
	AND UPPER(mkt.block_range) IS NULL
	AND off.gives > 0
	AND mkt_map.name NOT IN ('PUNKS20WETH', 'PUNKS40WETH')