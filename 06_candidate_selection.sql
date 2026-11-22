-- Purpose: Identify highly rated, low-engagement books for potential marketing.
-- Method: Select the highest-rated edition per work and combine genres across editions.
-- Criteria: Rating >= 4.0, 250-500 ratings, publication years 1950-2026.
-- Ranking: Review rate, followed by average rating.
-- Findings: 24 of the top 30 results were children's books, many being picture books. General fiction filters and review rate produced a distinct list.
-- Decision: Narrow the analysis to adult fiction to establish a clearer target audience and identify more comparable candidates for marketing.
-- Next: Revise Query 21 to focus on adult fiction and exclude children's/young adult genres.

WITH ranked_books AS (
    SELECT
        SAFE_CAST(work_id AS INT64) AS work_id,
        book_id,
        title,
        first_author,
        average_rating,
        ratings_count,
        publication_year,
        reviews_count,
        ROW_NUMBER() OVER (
            PARTITION BY SAFE_CAST(work_id AS INT64)
        ORDER BY
            ratings_count DESC, book_id) AS row_num
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
        ON b.book_id = bg.book_id
    WHERE
        b.work_id IS NOT NULL
        AND bg.genre IS NOT NULL)

SELECT
    rb.title,
    rb.first_author,
    rb.average_rating,
    rb.publication_year,
    rb.ratings_count,
    rb.reviews_count,
    ROUND(SAFE_DIVIDE(rb.reviews_count, rb.ratings_count) * 100, 2) AS review_rate,
    STRING_AGG(DISTINCT wg.genre, ', ' ORDER BY wg.genre) AS genres
FROM
    ranked_books AS rb
LEFT JOIN
    work_genres AS wg
    ON rb.work_id = wg.work_id
WHERE
    rb.row_num = 1
    AND rb.average_rating >= 4.0
    AND rb.ratings_count BETWEEN 250 AND 500
    AND rb.publication_year BETWEEN 1950 AND 2026
    AND EXISTS (
        SELECT 
            1
        FROM 
            work_genres 
        WHERE 
            work_genres.work_id = rb.work_id
          AND work_genres.genre IN (
              'Fiction',
              'Fantasy',
              'Romance',
              'Mystery',
              'Thriller',
              'Science Fiction',
              'Historical Fiction'))
GROUP BY
    rb.work_id,
    rb.title,
    rb.first_author,
    rb.average_rating,
    rb.publication_year,
    rb.ratings_count,
    rb.reviews_count
ORDER BY
    review_rate DESC,
    rb.average_rating DESC
LIMIT 100;

-- Purpose: Narrow the list to adult fiction for marketing.
-- Method: Keep the original criteria while excluding children's and young adult genres.
-- Criteria: Rating >= 4.0, 250-500 ratings, publication years 1950-2026.
-- Ranking: Review rate, followed by average rating.
-- Findings: Excluding children's/YA genres produced a broader selection of adult fiction with review rates reaching 27.11%. However, some manga, graphic novels, poetry, and nonfiction titles still appeared in the results.
-- Decision: Refine the genre exclusions to remove unrelated book types and improve the list.
-- Next: Create final query by adding genre exclusions before selecting marketing candidates.

-- Select the most-rated edition of each book.
WITH ranked_books AS (
    SELECT
        SAFE_CAST(work_id AS INT64) AS work_id,
        book_id,
        title,
        first_author,
        average_rating,
        ratings_count,
        publication_year,
        reviews_count,
        ROW_NUMBER() OVER (
            PARTITION BY SAFE_CAST(work_id AS INT64)
            ORDER BY
                ratings_count DESC,
                book_id) AS row_num
    FROM
        `goodreads-515120.goodreads_analysis.books`
    WHERE
        work_id IS NOT NULL),

-- Combine genre and work editions.
work_genres AS (
    SELECT DISTINCT
        SAFE_CAST(b.work_id AS INT64) AS work_id,
        bg.genre
    FROM
        `goodreads-515120.goodreads_analysis.books` AS b
    INNER JOIN
        `goodreads-515120.goodreads_analysis.book_genres` AS bg
        ON b.book_id = bg.book_id
    WHERE
        b.work_id IS NOT NULL
        AND bg.genre IS NOT NULL)

SELECT
    rb.title,
    rb.first_author,
    rb.average_rating,
    rb.publication_year,
    rb.ratings_count,
    rb.reviews_count,
    ROUND(SAFE_DIVIDE(rb.reviews_count, rb.ratings_count) * 100, 2) AS review_rate,
    STRING_AGG(DISTINCT wg.genre, ', ' ORDER BY wg.genre) AS genres
FROM
    ranked_books AS rb
LEFT JOIN
    work_genres AS wg
    ON rb.work_id = wg.work_id
WHERE
    rb.row_num = 1
    AND rb.average_rating >= 4.0
    AND rb.ratings_count BETWEEN 250 AND 500
    AND rb.publication_year BETWEEN 1950 AND 2026

-- Include general-interest fiction.
    AND EXISTS (
        SELECT
            1
        FROM
            work_genres
        WHERE
            work_genres.work_id = rb.work_id
            AND work_genres.genre IN (
                'Fiction',
                'Fantasy',
                'Romance',
                'Mystery',
                'Thriller',
                'Science Fiction',
                'Historical Fiction'))

-- Exclude children's and young adult books.
    AND NOT EXISTS (
        SELECT
            1
        FROM
            work_genres
        WHERE
            work_genres.work_id = rb.work_id
            AND work_genres.genre IN (
                'Childrens',
                'Picture Books',
                'Middle Grade',
                'Young Adult',
                'Juvenile'))
GROUP BY
    rb.work_id,
    rb.title,
    rb.first_author,
    rb.average_rating,
    rb.publication_year,
    rb.ratings_count,
    rb.reviews_count
ORDER BY
    review_rate DESC,
    rb.average_rating DESC
LIMIT 100;

-- Purpose: Identify highly rated, overlooked adult fiction books
-- for potential targeted marketing campaigns.
-- Method: Select the highest-rated edition per work and combine genres across editions.
-- Criteria: Rating >= 4.0, 250-500 ratings, publication years 1950-2026.
-- Ranking: Review rate, followed by average rating.
-- Findings: To be completed after reviewing the results.
-- Decision: To be completed after reviewing the results.
-- Next: Manually select 10 books from the results based on average rating, review rate, and potential target audiences. (in Excel)

-- Select the most-rated edition of each book.
WITH ranked_books AS (
    SELECT
        SAFE_CAST(work_id AS INT64) AS work_id,
        book_id,
        title,
        first_author,
        average_rating,
        ratings_count,
        publication_year,
        reviews_count,
        ROW_NUMBER() OVER (
            PARTITION BY SAFE_CAST(work_id AS INT64)
            ORDER BY
                ratings_count DESC,
                book_id) AS row_num
    FROM
        `goodreads-515120.goodreads_analysis.books`
    WHERE
        work_id IS NOT NULL),

-- Combine genre information across editions.
work_genres AS (
    SELECT DISTINCT
        SAFE_CAST(b.work_id AS INT64) AS work_id,
        bg.genre
    FROM
        `goodreads-515120.goodreads_analysis.books` AS b
    INNER JOIN
        `goodreads-515120.goodreads_analysis.book_genres` AS bg
        ON b.book_id = bg.book_id
    WHERE
        b.work_id IS NOT NULL
        AND bg.genre IS NOT NULL)

SELECT
    rb.title,
    rb.first_author,
    rb.average_rating,
    rb.publication_year,
    rb.ratings_count,
    rb.reviews_count,
    ROUND(SAFE_DIVIDE(rb.reviews_count, rb.ratings_count) * 100, 2) AS review_rate,
    STRING_AGG(DISTINCT wg.genre, ', ' ORDER BY wg.genre) AS genres
FROM
    ranked_books AS rb
LEFT JOIN
    work_genres AS wg
    ON rb.work_id = wg.work_id
WHERE
    rb.row_num = 1
    AND rb.average_rating >= 4.0
    AND rb.ratings_count BETWEEN 250 AND 500
    AND rb.publication_year BETWEEN 1950 AND 2026
 -- Include books tagged with general-interest fiction genres.
    AND EXISTS (
        SELECT
            1
        FROM
            work_genres
        WHERE
            work_genres.work_id = rb.work_id
            AND work_genres.genre IN (
                'Fiction',
                'Fantasy',
                'Romance',
                'Mystery',
                'Thriller',
                'Science Fiction',
                'Historical Fiction'))
-- Exclude children's books and unrelated book types.
    AND NOT EXISTS (
        SELECT
            1
        FROM
            work_genres
        WHERE
            work_genres.work_id = rb.work_id
            AND work_genres.genre IN (
                'Childrens',
                'Picture Books',
                'Middle Grade',
                'Young Adult',
                'Juvenile',
                'Manga',
                'Comics',
                'Graphic Novels',
                'Poetry',
                'Art',
                'Reference',
                'Nonfiction'))
GROUP BY
    rb.work_id,
    rb.title,
    rb.first_author,
    rb.average_rating,
    rb.publication_year,
    rb.ratings_count,
    rb.reviews_count
ORDER BY
    review_rate DESC,
    rb.average_rating DESC
LIMIT 100;

-- FINAL ANALYSIS SUMMARY
-- My initial selection included many children's books, prompting me to refine the genre exclusions and focus more closely on adult fiction.
-- After additional filtering and reviewing the top 100 results, I selected 10 books based on ratings, written-review engagement, genre diversity, and marketing potential.
-- I then evaluated potential target audiences in Excel and developed genre-specific recommendations, which I presented through an interactive Tableau dashboard.
