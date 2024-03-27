CREATE VIEW price_per_block AS 
WITH RECURSIVE block_series AS (
    SELECT MIN(LOWER(block_range)) AS block
    FROM sgd82.order
    UNION ALL
    SELECT block + 1
    FROM block_series
    WHERE block < (SELECT MAX(LOWER(block_range)) FROM sgd82.order)
)
, prices AS (
  SELECT DISTINCT
      LOWER(o.block_range) AS block
      , CASE 
          WHEN out_token.symbol = 'USDB' AND in_token.symbol = 'WETH'
            AND taker_gave > 0 AND taker_got > 0
          THEN ROUND((taker_got / POW(10, out_token.decimals)) / (taker_gave / POW(10, in_token.decimals)), 3)
          WHEN out_token.symbol = 'WETH' AND in_token.symbol = 'USDB'
            AND taker_got > 0 AND taker_gave > 0
          THEN ROUND((taker_gave / POW(10, in_token.decimals)) / (taker_got / POW(10, out_token.decimals)), 3)
       END AS weth_usdb
      , CASE 
          WHEN out_token.symbol = 'WETH' AND in_token.symbol = 'mwstETH-WPUNKS:20'
            AND taker_gave > 0 AND taker_got > 0
          THEN ROUND((taker_got / POW(10, out_token.decimals)) / (taker_gave / POW(10, in_token.decimals)), 3)
          WHEN out_token.symbol = 'mwstETH-WPUNKS:20' AND in_token.symbol = 'WETH'
            AND taker_got > 0 AND taker_gave > 0
          THEN ROUND((taker_gave / POW(10, in_token.decimals)) / (taker_got / POW(10, out_token.decimals)), 3)
       END AS punks20weth
      , CASE 
          WHEN out_token.symbol = 'WETH' AND in_token.symbol = 'mwstETH-WPUNKS:40'
            AND taker_gave > 0 AND taker_got > 0
          THEN ROUND((taker_got / POW(10, out_token.decimals)) / (taker_gave / POW(10, in_token.decimals)), 3)
          WHEN out_token.symbol = 'mwstETH-WPUNKS:40' AND in_token.symbol = 'WETH'
            AND taker_got > 0 AND taker_gave > 0
          THEN ROUND((taker_gave / POW(10, in_token.decimals)) / (taker_got / POW(10, out_token.decimals)), 3)
       END AS punks40weth

    FROM sgd82.order AS o
    LEFT JOIN sgd82.market AS market
        ON o.market = market.id
    LEFT JOIN sgd82.token AS out_token
      ON market.outbound_tkn = out_token.id
     LEFT JOIN sgd82.token AS in_token
      ON market.inbound_tkn = in_token.id
    WHERE NOT (taker_gave = 0 AND taker_got = 0)
    --ORDER BY block_range ASC
)

SELECT
	block_series.block
  , prices.weth_usdb
  , prices.punks20weth
  , prices.punks40weth
FROM block_series
LEFT JOIN prices
	ON block_series.block = prices.block
ORDER BY 1 ASC








