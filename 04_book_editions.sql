-- Purpose: Identify works with multiple editions.
-- Method: Count unique book_ids for each work_id.
-- Findings: Some works have up to 55 editions in the dataset.
-- Next Step: Determine how to represent each work without counting multiple editions as separate opportunities.

SELECT
  work_id,
  COUNT(DISTINCT book_id) AS total_editions
FROM
  `goodreads-515120.goodreads_analysis.books` 
WHERE
  work_id IS NOT NULL
GROUP BY
  work_id
ORDER BY
  total_editions DESC
LIMIT 20;

-- Purpose: Find the highest rating count for each work.
-- Method: Group by work_id and use MAX(ratings_count). Also count editions per work.
-- Finding: Some works have millions of ratings on a single edition.
-- Next Step: Identify the most-rated edition of each work so I can evaluate marketing opportunities.

SELECT
  work_id,
  COUNT(DISTINCT book_id) AS total_editions,
  MAX(ratings_count) AS max_ratings_count
FROM
  `goodreads-515120.goodreads_analysis.books` 
WHERE
  work_id IS NOT NULL
GROUP BY
  work_id
ORDER BY
  max_ratings_count DESC
LIMIT 20;

-- Purpose: Remove duplicate editions of the same literary work.
-- Method: Use ROW_NUMBER() to rank editions by ratings_count.
-- Keep row 1 to select the most-rated edition for each work_id.
-- Findings: Popular works have multiple editions and translations.
-- Note: Excludes books with NULL work_id.
-- Next: Filter for highly rated works with 250-500 ratings.

WITH ranked_books AS (
    SELECT
        work_id,
        book_id,
        title,
        first_author,
        average_rating,
        ratings_count,
        publication_year,
        ROW_NUMBER() OVER (
            PARTITION BY SAFE_CAST(work_id AS INT64)
            ORDER BY ratings_count DESC, book_id
        ) AS row_num
    FROM
        `goodreads-515120.goodreads_analysis.books`
    WHERE
        work_id IS NOT NULL)
SELECT
    work_id,
    title,
    first_author,
    average_rating,
    ratings_count,
    publication_year
FROM
    ranked_books
WHERE
    row_num = 1
ORDER BY
    ratings_count DESC
LIMIT 20;

-- ANALYSIS SUMMARY & NEXT STEPS
-- I found that multiple book IDs could represent different editions of the same work.
-- To avoid counting these as separate candidates, I used work IDs to identify all editions and selected the edition with the highest ratings count as the representative.
-- Next, I applied this approach to analyze overlooked books across genres and publication periods.
