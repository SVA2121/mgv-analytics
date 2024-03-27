SELECT
	take.id
  , take.creation_date
  , mkt.id AS market_id
  , out_tkn.symbol AS out_tkn
  , out_tkn.decimals AS out_tkn_decimals
  , in_tkn.symbol AS in_tkn
  , in_tkn.decimals AS in_tkn_decimals
  , ENCODE(make.owner, 'hex') AS owner
  , ENCODE(make.maker, 'hex') AS maker
  , ENCODE(make.kandel, 'hex') AS kandel
  , ENCODE(take.account, 'hex') AS account
  , ENCODE(take.taker, 'hex') AS taker
  , CASE 
  	WHEN out_tkn.symbol = 'WETH'
    THEN SUM(maker_got) / POW(10, in_tkn.decimals)
    ELSE SUM(maker_gave) / POW(10, out_tkn.decimals) END AS volume_traded
FROM sgd83.offer_filled take
LEFT JOIN sgd83.offer make
	ON take.offer = make.id
	AND LOWER(take.block_range) >= LOWER(make.block_range)
  AND LOWER(take.block_range) < UPPER(make.block_range)
LEFT JOIN sgd83.market mkt
	ON make.market = mkt.id
LEFT JOIN sgd83.token out_tkn
	ON mkt.outbound_tkn = out_tkn.id
LEFT JOIN sgd83.token in_tkn
	ON mkt.inbound_tkn = in_tkn.id
WHERE TRUE
	AND UPPER(mkt.block_range) IS NOT NULL
	-- AND ENCODE(make.kandel, 'hex') = {instance}
    AND LOWER(take.block_range) >= {start_block}
    AND LOWER(take.block_range) < {end_block}
GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12