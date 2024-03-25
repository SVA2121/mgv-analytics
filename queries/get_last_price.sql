SELECT
	CASE 
        WHEN tkn.symbol = 'USDB' 
        THEN taker.maker_gave / taker.maker_got
        WHEN tkn.symbol = 'WETH'
        THEN taker.maker_got / taker.maker_gave
    END AS price
FROM sgd79.offer_filled taker
LEFT JOIN sgd79.market mkt
	ON mkt.id = taker.market
LEFT JOIN sgd79.token tkn
	ON mkt.outbound_tkn = tkn.id
WHERE TRUE
    AND LOWER(taker.block_range) <= {block}
    AND UPPER(mkt.block_range) IS NULL
    AND UPPER(tkn.block_range) IS NULL
  --AND market = '0x9478fa0733344acd896e7f5ffa9ee03ccab653020a2898458323ddd6b53593df'
ORDER BY taker.block_range DESC
LIMIT 1