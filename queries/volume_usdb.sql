WITH txs AS (
  SELECT
 		mkt_map.name AS mkt_name
  	, DATE(TO_TIMESTAMP(fill.creation_date)) AS date
  	, TO_TIMESTAMP(fill.creation_date) > NOW() - INTERVAL '24' HOUR AS last_24h
  	, fill.creation_date
  	, LOWER(fill.block_range) AS block
  	, mkt_map.base AS base
  	, mkt_map.quote AS quote
  	, mkt_map.outbound_is_base AS outbound_is_base
  	, ENCODE(fill.transaction_hash, 'hex') AS tx_hash
  	, ENCODE(fill.taker, 'hex') AS taker
  	, ENCODE(fill.account, 'hex') AS taker_account
  	, ENCODE(off.maker, 'hex') AS maker
  	, ENCODE(off.owner, 'hex') AS maker_admin
  	, fill.maker_got
  	, fill.maker_gave
  	, off.total_got
  	, off.total_gave
  	
  FROM sgd83.offer_filled fill
  JOIN sgd83.offer off
    ON fill.offer = off.id
      AND fill.transaction_hash = off.latest_transaction_hash
  JOIN public.market_mapping mkt_map
    ON mkt_map.id = off.market
  WHERE TRUE
  	
)

SELECT
	mkt_name
  , DATE(TO_TIMESTAMP(creation_date)) AS date
  , eth_price.price
  , COUNT(tx_hash) AS n_transactions
  , SUM(
    	CASE
    		WHEN outbound_is_base AND mkt_name <> 'WETHUSDB'
    		THEN maker_got * eth_price.price
    		WHEN NOT outbound_is_base AND mkt_name <> 'WETHUSDB'
    		THEN maker_gave * eth_price.price
    		WHEN outbound_is_base
    		THEN maker_got
    		ELSE maker_gave
    	END
    ) / POW(10, 18) AS volume_usdb
   , SUM(
     	CASE
     		WHEN last_24h
     		THEN 1
     		ELSE 0
     	END) AS n_transactions_24h
   , SUM(
    	CASE
    		WHEN outbound_is_base AND mkt_name <> 'WETHUSDB' AND last_24h 
    		THEN maker_got * eth_price.price
    		WHEN NOT outbound_is_base AND mkt_name <> 'WETHUSDB' AND last_24h
    		THEN maker_gave * eth_price.price
    		WHEN outbound_is_base AND last_24h
    		THEN maker_got
    		WHEN NOT outbound_is_base AND last_24h
     		THEN maker_gave
     		ELSE 0
    	END
    ) / POW(10, 18) AS volume_usdb_24h
FROM txs
JOIN public.eth_close_price_per_day eth_price
	ON DATE(TO_TIMESTAMP(creation_date)) = eth_price.date
WHERE TRUE
	--AND maker_got <> total_got
GROUP BY 1, 2, 3







