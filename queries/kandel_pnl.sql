WITH end_blocks AS (
  SELECT 
		off.kandel AS kandel
  	, offer_id
  	
  	--, off.*
  	, MAX(LOWER(block_range)) AS last_offer_block
	FROM sgd83.offer off
	WHERE TRUE
	--AND ENCODE(kandel, 'hex') = '4e44d45e57021c3ce22433c748669b6ca03f2d5c'
  --AND ENCODE(off.kandel, 'hex') = '4e44d45e57021c3ce22433c748669b6ca03f2d5c'
  --AND LOWER(block_range) = 1451539
  --AND is_open
  AND kandel IS NOT NULL
  
	GROUP BY 1, 2
)
, kdw AS (
  SELECT 
  	*
  FROM (
    SELECT
    	*
    , ROW_NUMBER() OVER(PARTITION BY kandel, token ORDER BY date DESC) AS rn
    FROM sgd83.kandel_deposit_withdraw 
  ) kdw
  WHERE TRUE
  	AND rn = 1
  
)

, live_balances AS (
  SELECT
    end_blocks.kandel
  	, tkn.id AS tkn
    , tkn.symbol
    , tkn.decimals
    --, end_blocks.offer_id
    , SUM(off.gives / POW(10, tkn.decimals)) AS end_balance
    --, off.*
  FROM end_blocks
  LEFT JOIN sgd83.offer off
  ON end_blocks.kandel = off.kandel
    AND LOWER(off.block_range) = end_blocks.last_offer_block
    AND off.offer_id = end_blocks.offer_id
  JOIN sgd83.market mkt
    ON mkt.id = off.market
  JOIN sgd83.token tkn
      ON tkn.id = mkt.outbound_tkn
  JOIN public.market_mapping mkt_map
    ON mkt.id = mkt_map.id
  --INNER JOIN sgd83.kandel	kandel
    --ON kandel.id = off.kandel
  WHERE TRUE
    AND UPPER(mkt.block_range) IS NULL
    AND UPPER(tkn.block_range) IS NULL
    AND off.kandel IS NOT NULL
    --AND ENCODE(off.kandel, 'hex') = 'ea44859fe05eaaeeff7002308876c06904ac69a5' 
    --AND off.is_open
  GROUP BY 1, 2, 3, 4
)

, end_balances AS (
  SELECT
    live_balances.kandel AS instance_address
    , tkn
    , symbol
    , COALESCE(is_deposit, TRUE) AS is_live
    , CASE 
        WHEN COALESCE(kdw.is_deposit, TRUE)
          THEN live_balances.end_balance
        ELSE
          kdw.amount / POW(10, live_balances.decimals)
      END AS end_balance
  FROM live_balances
  LEFT JOIN kdw
    ON ENCODE(kdw.kandel, 'hex') = ENCODE(live_balances.kandel, 'hex')
    AND kdw.token = live_balances.tkn
)

, kandel_instances AS (
    SELECT
      kandel AS instance_address
      , MAX(LOWER(block_range)) AS last_populate_block
    FROM sgd83.kandel_populate_retract
    WHERE TRUE
      AND NOT is_retract
    GROUP BY 1
)
 
, kandels AS (
  SELECT
  	--end_balances.instance_owner
  	 ENCODE(off.kandel, 'hex') AS instance_address
  	, off.kandel
  	, mkt_map.name AS mkt_name
  	, tkn.id AS tkn_id
    , tkn.symbol AS tkn
 		, ki.last_populate_block
  	, LOWER(fill.block_range) AS start_price_block
  	, mkt_map.outbound_is_base
  	, fill.maker_got
  	, fill.maker_gave
  	, tkn.decimals
  	, CASE 
  			WHEN mkt_map.outbound_is_base
  			THEN fill.maker_got / fill.maker_gave
  			ELSE fill.maker_gave / fill.maker_got
  		END AS start_price
  	, ROW_NUMBER() OVER(PARTITION BY ENCODE(off.kandel, 'hex'), mkt_map.name, tkn.symbol ORDER BY LOWER(fill.block_range) DESC) AS rn	
  	, SUM(off.gives) / POW(10, tkn.decimals) AS start_balance
  FROM sgd83.offer off
  JOIN kandel_instances ki
  	ON ki.instance_address = off.kandel
  		AND LOWER(off.block_range) = ki.last_populate_block
  JOIN sgd83.market mkt
  	ON mkt.id = off.market
  JOIN public.market_mapping mkt_map
  	ON mkt_map.id = off.market
  JOIN sgd83.token tkn
  	ON tkn.id = mkt.outbound_tkn
  JOIN sgd83.offer_filled fill
  	ON mkt_map.id = fill.market
  	AND LOWER(fill.block_range) <= ki.last_populate_block
  WHERE TRUE
  	--AND ENCODE(off.kandel, 'hex') = '4e44d45e57021c3ce22433c748669b6ca03f2d5c'
  	AND off.is_open
    AND UPPER(mkt.block_range) IS NULL
  	AND UPPER(tkn.block_range) IS NULL
  	GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11
)

, pnl AS (
  SELECT
  	kandels.mkt_name
  	, kandels.instance_address
  	, SUM(
      	CASE 
      		WHEN kandels.outbound_is_base
      		THEN start_balance * start_price
      		ELSE start_balance
      	END) AS start_balance_quote
  	, SUM(
      	CASE 
      		WHEN kandels.outbound_is_base
      		THEN end_balances.end_balance * start_price
      		ELSE end_balances.end_balance
      	END) AS end_balance_quote
	FROM kandels
  JOIN end_balances
    ON ENCODE(end_balances.instance_address, 'hex') = kandels.instance_address
      AND end_balances.tkn = kandels.tkn_id
  JOIN public.current_prices cp
    ON cp.mkt_name = kandels.mkt_name
  WHERE TRUE
    AND rn = 1
    --AND kandels.instance_address = '1a4118ffde996ca6a06c7912655b15d24c340e58'
  GROUP BY 1, 2
)


SELECT
  mkt_name
  , instance_address
  , start_balance_quote
  , end_balance_quote
  , end_balance_quote - start_balance_quote AS pnl_quote
  , (end_balance_quote - start_balance_quote) / start_balance_quote AS return_rate
FROM pnl
WHERE TRUE







