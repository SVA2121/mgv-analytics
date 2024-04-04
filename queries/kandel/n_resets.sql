SELECT
	SUM(CASE 
      	WHEN is_retract
      	THEN 0
      	ELSE 1
      END) AS n_resets
FROM (SELECT * FROM sgd83.kandel_populate_retract ORDER BY creation_date DESC) kpr
WHERE TRUE
	AND ENCODE(kandel, 'hex') = 'ea44859fe05eaaeeff7002308876c06904ac69a5'
	

