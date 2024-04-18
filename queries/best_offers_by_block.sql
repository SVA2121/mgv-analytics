WITH blocks AS (
  SELECT
		GENERATE_SERIES({start_block} , {end_block}, 1) AS block
)

, asks AS (
  SELECT
    blocks.block
    , POW(1.0001, MIN(tick)) AS best_ask
  FROM sgd83.offer off
  JOIN public.market_mapping mkt_map
    ON off.market = mkt_map.id
  CROSS JOIN blocks
  WHERE TRUE
    AND COALESCE(UPPER(off.block_range), blocks.block + 1) > blocks.block
    AND LOWER(off.block_range) <= blocks.block
  	AND outbound_is_base
    AND is_open
    AND mkt_map.name = 'WETHUSDB'
    AND off.maker = '792219f2b751d0D81A11caf816D12e446838D214'
  GROUP BY 1
)

, bids AS (
  SELECT
    blocks.block
    , 1 / POW(1.0001, MIN(tick)) AS best_bid

  FROM sgd83.offer off
  JOIN public.market_mapping mkt_map
    ON off.market = mkt_map.id
  CROSS JOIN blocks
  WHERE TRUE
    AND COALESCE(UPPER(off.block_range), blocks.block + 1) > blocks.block
    AND LOWER(off.block_range) <= blocks.block
  	AND NOT outbound_is_base
    AND is_open
    AND mkt_map.name = 'WETHUSDB'
    AND off.maker = '792219f2b751d0D81A11caf816D12e446838D214'

  GROUP BY 1
)

SELECT *
FROM asks
JOIN bids
	ON asks.block = bids.block









