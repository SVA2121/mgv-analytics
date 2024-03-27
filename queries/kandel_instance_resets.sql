WITH exits AS (
  SELECT
    kandel.vid
    , LOWER(kandel.block_range) AS exit_block
    , ENCODE(kandel.kandel, 'hex') AS instance_address
    , DATE_TRUNC('MINUTE', TO_TIMESTAMP(kandel.creation_date)) AS exit_date
    , tkn.name AS tkn_name
    , ROUND(kpw.amount / POW(10, tkn.decimals), 4) AS withdrawn_amount

    --, tkn_base.symbol AS base_token
    --, ROUND(kandel.deposited_base / POW(10, tkn_base.decimals), 4) AS deposited_base
    --, tkn_quote.symbol AS quote_token
    --, ROUND(kandel.deposited_quote / POW(10, tkn_quote.decimals), 4) AS deposited_quote
  FROM sgd83.kandel_populate_retract kandel
  LEFT JOIN sgd83.kandel_deposit_withdraw kpw
    ON LOWER(kpw.block_range) = LOWER(kandel.block_range)
  LEFT JOIN sgd83.token tkn
    ON tkn.id = kpw.token--
  WHERE TRUE
    AND UPPER(tkn.block_range) IS NULL
    --AND ENCODE(kandel.kandel, 'hex') = {instance}
    AND is_retract
    --AND LOWER(kandel.block_range) >= 1101618
)

SELECT
	kandel.vid AS reset_id
	, LOWER(kandel.block_range) AS reset_block
  , ENCODE(kandel.kandel, 'hex') AS instance_address
  , DATE_TRUNC('MINUTE', TO_TIMESTAMP(kandel.creation_date)) AS reset_date
  , tkn.symbol AS tkn
  , ROUND(kpw.amount / POW(10, tkn.decimals), 4) AS deposited_amount
  , exits.exit_block
  , exits.exit_date
  , exits.withdrawn_amount
  --, tkn_base.symbol AS base_token
  --, ROUND(kandel.deposited_base / POW(10, tkn_base.decimals), 4) AS deposited_base
  --, tkn_quote.symbol AS quote_token
  --, ROUND(kandel.deposited_quote / POW(10, tkn_quote.decimals), 4) AS deposited_quote
FROM sgd83.kandel_populate_retract kandel
LEFT JOIN sgd83.kandel_deposit_withdraw kpw
	ON LOWER(kpw.block_range) = LOWER(kandel.block_range)
LEFT JOIN sgd83.token tkn
	ON tkn.id = kpw.token--
LEFT JOIN exits
	ON exits.exit_block >= LOWER(kandel.block_range)
  	AND ENCODE(kandel.kandel, 'hex') = exits.instance_address
    AND tkn.name = exits.tkn_name
    AND NOT EXISTS (
        SELECT 1
        FROM sgd83.kandel_populate_retract AS next_non_exit 
        WHERE next_non_exit.kandel = kandel.kandel 
            AND LOWER(next_non_exit.block_range) > LOWER(kandel.block_range)
            AND LOWER(next_non_exit.block_range) < exits.exit_block 
            AND next_non_exit.is_retract = FALSE
    )
WHERE TRUE
	AND UPPER(tkn.block_range) IS NULL
  AND ENCODE(kandel.kandel, 'hex') = {instance}
  AND NOT is_retract
  --AND ENCODE(kandel.kandel, 'hex') = '4e44d45e57021c3ce22433c748669b6ca03f2d5c'
 	
	--AND vid = 2
ORDER BY kandel.creation_date DESC