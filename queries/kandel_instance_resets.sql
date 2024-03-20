SELECT
  kandel.vid AS reset_id
  , kandel.block_range
  , tkn_base.symbol AS base_token
  , ROUND(kandel.deposited_base / POW(10, tkn_base.decimals), 4) AS deposited_base
  , tkn_quote.symbol AS quote_token
  , ROUND(kandel.deposited_quote / POW(10, tkn_quote.decimals), 4) AS deposited_quote
FROM SGD78.kandel kandel
LEFT JOIN SGD78.token tkn_base
	ON tkn_base.id = kandel.base
LEFT JOIN SGD78.token tkn_quote
	ON tkn_quote.id = kandel.quote
WHERE TRUE
	AND UPPER(tkn_base.block_range) IS NULL
  AND UPPER(tkn_quote.block_range) IS NULL
  AND ENCODE(kandel.id, 'hex') = {instance}
	--AND vid = 2




