  SELECT
      creation_date
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

    FROM sgd77.order AS o
    LEFT JOIN sgd77.market AS market
        ON o.market = market.id
    LEFT JOIN sgd77.token AS out_token
      ON market.outbound_tkn = out_token.id
     LEFT JOIN sgd77.token AS in_token
      ON market.inbound_tkn = in_token.id
    WHERE NOT (taker_gave = 0 AND taker_got = 0)
    ORDER BY creation_date ASC