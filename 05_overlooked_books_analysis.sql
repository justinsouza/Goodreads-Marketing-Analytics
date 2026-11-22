-- Purpose: Find highly rated books with relatively low engagement.
-- Method: Select one edition per work using ROW_NUMBER().
-- Filter for ratings >= 4.0 and 250-500 ratings.
-- Sort by average_rating DESC to prioritize top-rated books.
-- Findings: Results include religious, academic, and niche titles.
-- Insight: High ratings alone don't indicate marketing potential.
-- Next: Analyze genres to identify more relevant opportunities.

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
            ORDER BY average_rating DESC, book_id
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
    AND average_rating >= 4.0
    AND ratings_count BETWEEN 250 AND 500
ORDER BY
    average_rating DESC
LIMIT 20;

-- Purpose: Identify genres with the most overlooked, highly rated works.
-- Method: Select one edition per work and join genre data. Filter for 4.0+ ratings and 250-500 ratings.
-- Count distinct works within each genre.
-- Findings: Nonfiction leads with 2,277 qualifying works. Fiction follows with 1,582, and History with 939.
-- Insight: Nonfiction has about 44% more candidates than Fiction.
-- Limitation: Genres overlap, and counts don't account for genre size.
-- Next: Calculate the percentage of overlooked works within each genre.

WITH ranked_books AS (
    SELECT
        SAFE_CAST(work_id AS INT64) AS work_id,
        book_id,
        title,
        average_rating,
        ratings_count,
        ROW_NUMBER() OVER (
            PARTITION BY SAFE_CAST(work_id AS INT64)
            ORDER BY ratings_count DESC, book_id
        ) AS row_num
    FROM
        `goodreads-515120.goodreads_analysis.books`
    WHERE
        work_id IS NOT NULL)
SELECT
    g.genre,
    COUNT(DISTINCT b.work_id) AS overlooked_works
FROM
    ranked_books AS b
LEFT JOIN
    `goodreads-515120.goodreads_analysis.book_genres` AS g
ON
    b.book_id = g.book_id
WHERE
    b.row_num = 1
    AND b.average_rating >= 4.0
    AND b.ratings_count BETWEEN 250 AND 500
GROUP BY
    g.genre
ORDER BY
    overlooked_works DESC;

-- Purpose: Measure missing genre information across all editions.
-- Method: LEFT JOIN books with genres and group by work_id. Use HAVING COUNT(genre) = 0 to find works with no genres.
-- Findings: 303,349 works have no genre information.
-- Only 15 fewer than the NULL group in Query 17.
-- Insight: Missing genre data is a major dataset limitation.
-- Next: Calculate overlooked-work percentages by genre.

WITH missing_genres AS (
    SELECT
        b.work_id
    FROM
        `goodreads-515120.goodreads_analysis.books` AS b
    LEFT JOIN
        `goodreads-515120.goodreads_analysis.book_genres` AS bg
    ON
        b.book_id = bg.book_id
    WHERE
        b.work_id IS NOT NULL
    GROUP BY
        b.work_id
    HAVING
        COUNT(bg.genre) = 0)
SELECT
    COUNT(*) AS works_without_genres
FROM
    missing_genres;

-- Purpose: Compare overlooked book counts and percentages by genre.
-- Method: Select most-rated edition per work, combine genres across editions, and calculate overlooked counts and percentages (min. 100 works per genre).
-- Findings: Nonfiction leads with 2,278 overlooked works (4.76%). Fiction has 1,582 (3.15%); Spirituality has a higher rate (10.62%).
-- Takeaway: Consider both volume and percentage when prioritizing genres.
-- Next: Analyze publication year to account for differences in book age.

WITH ranked_books AS (
    SELECT
        SAFE_CAST(work_id AS INT64) AS work_id,
        book_id,
        title,
        average_rating,
        ratings_count,
        ROW_NUMBER() OVER (
            PARTITION BY SAFE_CAST(work_id AS INT64)
            ORDER BY ratings_count DESC, book_id) AS row_num
    FROM
        `goodreads-515120.goodreads_analysis.books`
    WHERE
        work_id IS NOT NULL),
    
  work_genres AS (
    SELECT DISTINCT
        SAFE_CAST(b.work_id AS INT64) AS work_id,
        bg.genre
    FROM
        `goodreads-515120.goodreads_analysis.books` AS b
    INNER JOIN
        `goodreads-515120.goodreads_analysis.book_genres` AS bg
    ON
        b.book_id = bg.book_id
    WHERE
        b.work_id IS NOT NULL
        AND bg.genre IS NOT NULL),
  
  genre_counts AS (
    SELECT
        wg.genre,
        COUNT(DISTINCT rb.work_id) AS total_works,
        COUNTIF(rb.average_rating >= 4.0 
        AND rb.ratings_count BETWEEN 250 AND 500) AS overlooked_works
    FROM
        ranked_books AS rb
    INNER JOIN
        work_genres AS wg
    ON
        rb.work_id = wg.work_id
    WHERE
        rb.row_num = 1
    GROUP BY
        wg.genre HAVING COUNT(DISTINCT rb.work_id) >= 100)
SELECT
    genre,
    total_works,
    overlooked_works,
    ROUND(SAFE_DIVIDE(overlooked_works, total_works) * 100, 2) AS overlooked_percentage
FROM
    genre_counts
ORDER BY
    genre_counts.overlooked_works DESC;

-- Purpose: Analyze how overlooked book percentages vary by decade.
-- Method: Select the most-rated edition per work, group by decade, and calculate total works, overlooked works, and percentages.
-- Data Cleaning: Restrict publication years to 1950–2026.
-- Findings: The 2000s contain the most overlooked works (2,050). The 1950s have the highest overlooked percentage (1.52%). No consistent relationship between decade and overlooked percentage.
-- Limitation: Publication-year coverage varies. The dataset does not say whether this reflects actual publishing trends.
-- Next: Find specific books to make recommendations.

WITH ranked_books AS (
    SELECT
        SAFE_CAST(work_id AS INT64) AS work_id,
        book_id,
        title,
        average_rating,
        ratings_count,
        publication_year,
        ROW_NUMBER() OVER (
            PARTITION BY SAFE_CAST(work_id AS INT64)
              ORDER BY 
              ratings_count DESC, book_id) AS row_num
    FROM
        `goodreads-515120.goodreads_analysis.books`
    WHERE
        work_id IS NOT NULL),

decade_counts AS (
    SELECT
        FLOOR(publication_year / 10) * 10 AS decade,
        COUNT(*) AS total_works,
        COUNTIF(average_rating >= 4.0 AND ratings_count BETWEEN 250 AND 500) AS overlooked_works
    FROM
        ranked_books
    WHERE
        row_num = 1 AND publication_year BETWEEN 1950 AND 2026
    GROUP BY
        decade)

SELECT
    decade,
    total_works,
    overlooked_works,
    ROUND(SAFE_DIVIDE(overlooked_works, total_works) * 100, 2) AS overlooked_percentage
FROM
    decade_counts
ORDER BY
    decade;

-- ANALYSIS SUMMARY & NEXT STEPS
-- Using the refined data, I looked at how highly rated books with low Goodreads engagement were distributed across genres and publication decades.
-- I also considered the impact of missing genre information on these comparisons.
-- These findings helped narrow the project toward fiction, where I could develop more specific audience-based recommendations.
