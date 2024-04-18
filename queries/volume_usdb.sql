SELECT
	mkt_map.name AS mkt_name
  , DATE_TRUNC('minute', TO_TIMESTAMP(creation_date)) AS date
  , eth_price.price
  , TO_TIMESTAMP(fill.creation_date) > NOW() - INTERVAL '24' HOUR AS last_24h
  , COUNT(DISTINCT transaction_hash) AS n_transactions
  , SUM(
    	CASE
    		WHEN outbound_is_base AND mkt_map.name <> 'WETHUSDB'
    		THEN maker_got * eth_price.price
    		WHEN NOT outbound_is_base AND mkt_map.name <> 'WETHUSDB'
    		THEN maker_gave * eth_price.price
    		WHEN outbound_is_base
    		THEN maker_got
    		ELSE maker_gave
    	END
    ) / POW(10, 18) AS volume_usdb
FROM sgd83.offer_filled fill
JOIN public.market_mapping mkt_map
	ON fill.market = mkt_map.id
JOIN public.eth_close_price_per_day eth_price
	ON DATE(TO_TIMESTAMP(creation_date)) = eth_price.date
WHERE TRUE
	AND mkt_map.name = 'WETHUSDB'
	
GROUP BY 1, 2, 3, 4









