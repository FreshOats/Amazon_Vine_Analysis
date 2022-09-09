SELECT *
FROM vine_table
WHERE total_votes > 20
    AND CAST(helpful_votes AS FLOAT)/CAST(total_votes AS FLOAT) >= 0.5
GROUP BY vine
;