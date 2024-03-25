SELECT 
	DISTINCT
    ROUND(CASE
  		WHEN out_tkn.symbol = 'WETH'
      THEN POW(1.0001, off.tick)
      WHEN out_tkn.symbol = 'USDB'
      THEN 1 / POW(1.0001, off.tick)
    END, 4) AS price

FROM sgd79.offer off
LEFT JOIN sgd79.market mkt
	ON off.market = mkt.id
LEFT JOIN sgd79.token out_tkn
	ON mkt.outbound_tkn = out_tkn.id
LEFT JOIN sgd79.token in_tkn
	ON mkt.inbound_tkn = in_tkn.id
WHERE TRUE
    AND UPPER(mkt.block_range) IS NULL
    AND UPPER(out_tkn.block_range) IS NULL
    AND UPPER(in_tkn.block_range) IS NULL
	AND ENCODE(off.kandel, 'hex') = {instance}
    AND LOWER(off.block_range) = {block}
--GROUP BY 1
ORDER BY price