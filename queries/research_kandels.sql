SELECT
	ENCODE(address, 'hex') AS instance_address
  , COUNT(id) AS total_resets
  , TO_CHAR(MIN(CAST(TO_TIMESTAMP(creation_date) AS TIMESTAMP)), 'YYYY-MM-DD HH24:MI') AS creation_date
	, TO_CHAR(CAST(TO_TIMESTAMP(kpr.last_reset) AS TIMESTAMP), 'YYYY-MM-DD HH24:MI') AS last_reset
FROM SGD78.kandel kandel
LEFT JOIN (SELECT kandel, MAX(creation_date) AS last_reset FROM SGD78.kandel_populate_retract GROUP BY 1) AS kpr
	ON kandel.id = kpr.kandel
WHERE TRUE
	--AND UPPER(block_range) IS NULL
  AND ENCODE(deployer, 'hex') = {wallet}
GROUP BY 1, 4