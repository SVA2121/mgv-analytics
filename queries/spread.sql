WITH best_asks AS (
  SELECT 
    mkt_map.name AS mkt_name
    , LOWER(block_range) AS block
   	, 1 / MIN(POW(1.0001, tick)) AS best_ask

  FROM sgd83.offer off
  JOIN public.market_mapping mkt_map
    ON off.market = mkt_map.id
  WHERE TRUE
  	AND NOT outbound_is_base

  GROUP BY 1, 2
)

, best_bids AS (
  SELECT 
    mkt_map.name AS mkt_name
    , LOWER(block_range) AS block
   	, 1 / MAX(POW(1.0001, tick)) AS best_bid
  FROM sgd83.offer off
  JOIN public.market_mapping mkt_map
    ON off.market = mkt_map.id
  WHERE TRUE
  	AND NOT outbound_is_base

  GROUP BY 1, 2
)

SELECT
	ba.mkt_name
  , ba.block
  , ba.best_ask
  , bb.best_bid
  , (ba.best_ask - bb.best_bid) AS spread
  , (ba.best_ask - bb.best_bid) / 2 AS mid_price
FROM best_asks ba
JOIN best_bids bb
	ON bb.mkt_name = ba.mkt_name
  	AND bb.block = ba.block
WHERE TRUE
ORDER BY bb.block ASC




