
  SELECT
    mkt_map.name AS mkt_name
    , DATE_TRUNC('MINUTE', TO_TIMESTAMP(fill.creation_date)) AS date
    , ENCODE(fill.transaction_hash, 'hex') AS tx_hash
    , ENCODE(fill.account, 'hex') AS taker_owner
    , ENCODE(fill.taker, 'hex') AS taker
    , ENCODE(off.owner, 'hex') AS maker_owner
    , ENCODE(off.maker, 'hex') AS maker
    , ENCODE(off.kandel, 'hex') AS kandel
    , eth_price.price
    , SUM(
        CASE
          WHEN outbound_is_base AND mkt_map.name <> 'WETHUSDB'
          THEN fill.maker_got * eth_price.price
          WHEN NOT outbound_is_base AND mkt_map.name <> 'WETHUSDB'
          THEN fill.maker_gave * eth_price.price
          WHEN outbound_is_base
          THEN fill.maker_got
          ELSE fill.maker_gave
        END
      ) / POW(10, 18) AS volume_usdb
  FROM sgd83.offer_filled fill
  JOIN (SELECT DISTINCT id, latest_transaction_hash, maker, owner, kandel FROM sgd83.offer) off
    ON fill.transaction_hash = off.latest_transaction_hash
    AND off.id = fill.offer
  JOIN sgd83.order ord
    ON ord.transaction_hash = fill.transaction_hash
  JOIN public.market_mapping mkt_map
    ON mkt_map.id = fill.market
  JOIN public.eth_close_price_per_day eth_price
    ON DATE(TO_TIMESTAMP(fill.creation_date)) = eth_price.date

  WHERE TRUE
    AND mkt_map.name = 'WETHUSDB'
    --AND LOWER(fill.block_range) <= 1891925
    --AND ENCODE(fill.transaction_hash, 'hex') = '00036d34b60b4551385bd8279aef72798cb05f917ede2eaf4ab796284fb9b69d'
		AND DATE(TO_TIMESTAMP(fill.creation_date)) = {day}
  GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9








