WITH txs AS (
    SELECT
      *
      , ROW_NUMBER() OVER(PARTITION BY mkt_map.name, DATE(TO_TIMESTAMP(creation_date)) ORDER BY creation_date DESC) AS rn
    FROM sgd83.offer_filled fill
    JOIN public.market_mapping mkt_map
      ON fill.market = mkt_map.id
    WHERE TRUE
      AND mkt_map.name = 'WETHUSDB'
  )

  SELECT
    DATE(TO_TIMESTAMP(creation_date)) AS date
    , CASE
        WHEN outbound_is_base
        THEN maker_got / maker_gave
        ELSE maker_gave / maker_got
      END AS price
  FROM txs
  WHERE TRUE
    AND rn = 1