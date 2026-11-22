-- Purpose: Evaluate different minimum rating-counts to balance rating reliability with sample size.
-- Findings: Tested thresholds of 100, 250, 300, 500, and 1,000 ratings. A 250-rating minimum has 80,299 books (16.06% of the dataset), while 500 has 65,320 (13.06%).
-- Decision: Use 250 ratings as the baseline threshold and 500 ratings for a sensitivity analysis to determine whether a higher threshold changes the findings.
-- Next Step: Find books with average ratings of 4.0+ and compare their engagement within their genres.

SELECT
  COUNT(*) AS total_books,
  COUNTIF(ratings_count >= 250) AS books_above_threshold,
  ROUND(COUNTIF(ratings_count >= 250) * 100 / COUNT(*), 2) AS pct_above_threshold
FROM
  `goodreads-515120.goodreads_analysis.books`;

-- Purpose: Determining the sample of books that meet the 250 ratings minimum with a solid average rating of at least 4.0
-- Outcome: 32,786 books
-- Next Step: Compare these books against genre-specific engagement metrics to find potentially overlooked books.

SELECT
    COUNT(*) AS qualifying_books
FROM
    `goodreads-515120.goodreads_analysis.books`
WHERE
    ratings_count >= 250
    AND average_rating >= 4.0;

-- Purpose: Compare engagement across the top 20 genres for books rated 4.0+ with at least 250 ratings.
-- Method: Use median ratings to limit the impact of extremely popular books.
-- Findings: Audiobook, Literature, and Classics have the highest median engagement.
-- Limitation: Only includes books meeting the thresholds. Books can belong to multiple genres. Ratings do not equal sales.

SELECT
  bg.genre,
  ROUND(APPROX_QUANTILES(b.ratings_count, 100)[OFFSET(50)], 2)
    AS median_ratings_per_book
FROM
  `goodreads-515120.goodreads_analysis.book_genres` AS bg
INNER JOIN
  `goodreads-515120.goodreads_analysis.books` AS b
ON
  bg.book_id = b.book_id
WHERE 
  bg.genre IN (
    'Fiction',
    'Nonfiction',
    'History',
    'Classics',
    'Audiobook',
    'Fantasy',
    'Romance',
    'Childrens',
    'Historical Fiction',
    'Mystery',
    'Literature',
    'Novels',
    'Historical',
    'Biography',
    'Philosophy',
    'Young Adult',
    'Adventure',
    'Contemporary',
    'Reference',
    'Art'
) AND b.average_rating >= 4.0 AND b.ratings_count >= 250
GROUP BY
  bg.genre
ORDER BY
  median_ratings_per_book DESC;

-- Purpose: Find highly rated books with lower engagement across the top 20 genres.
-- Method: Count books rated 4.0+ with 250–500 ratings.
-- Findings: Nonfiction, Fiction, and History have the most qualifying books.
-- Limitation: Larger genres may have more qualifying books. Ratings do not equal readership.

SELECT
  bg.genre,
  COUNT(DISTINCT b.book_id) AS total_books
FROM
  `goodreads-515120.goodreads_analysis.book_genres` AS bg
INNER JOIN
  `goodreads-515120.goodreads_analysis.books` AS b
ON
  bg.book_id = b.book_id
WHERE 
  bg.genre IN (
    'Fiction',
    'Nonfiction',
    'History',
    'Classics',
    'Audiobook',
    'Fantasy',
    'Romance',
    'Childrens',
    'Historical Fiction',
    'Mystery',
    'Literature',
    'Novels',
    'Historical',
    'Biography',
    'Philosophy',
    'Young Adult',
    'Adventure',
    'Contemporary',
    'Reference',
    'Art'
)
  AND b.average_rating >= 4.0 
  AND b.ratings_count BETWEEN 250 AND 500
GROUP BY
  bg.genre
ORDER BY
  total_books DESC;

-- Purpose: Compare the percentage of potentially overlooked, highly rated books across 20 genres. To find marketing opportunities.
-- Method: Divide qualifying books by total books in each genre.
-- Findings: Reference (6.29%), Art (5.06%), and Biography (4.94%) have the highest percentages.
-- Limitation: Higher percentages does not necessarily mean more demand.

WITH genre_counts AS (
  SELECT
    bg.genre,
    COUNT(DISTINCT b.book_id) AS total_books,
    COUNTIF(b.average_rating >= 4.0 AND b.ratings_count BETWEEN 250 AND 500) AS qualifying_books
  FROM
    `goodreads-515120.goodreads_analysis.book_genres` AS bg
  INNER JOIN
    `goodreads-515120.goodreads_analysis.books` AS b
  ON
    bg.book_id = b.book_id
  WHERE 
    bg.genre IN (
      'Fiction',
      'Nonfiction',
      'History',
      'Classics',
      'Audiobook',
      'Fantasy',
      'Romance',
      'Childrens',
      'Historical Fiction',
      'Mystery',
      'Literature',
      'Novels',
      'Historical',
      'Biography',
      'Philosophy',
      'Young Adult',
      'Adventure',
      'Contemporary',
      'Reference',
      'Art')
  GROUP BY
    bg.genre)
SELECT
  genre,
  total_books,
  qualifying_books,
  ROUND(qualifying_books * 100.0 / total_books, 2) AS pct_qualifying
FROM
  genre_counts
ORDER BY
  pct_qualifying DESC;

-- Purpose: Identify highly rated books with relatively low Goodreads engagement.
-- Method: Select books with an average rating of at least 4.0 and between 250 and 500 ratings. Rank by highest rating first.
-- Findings: Several top results are different editions of the same work.
-- Next Step: Investigate work_id to avoid treating multiple edition of the same book as separate marketing opportunities.
-- Limitation: Low Goodreads engagement does not necessarily mean low sales.

SELECT
  title,
  first_author,
  average_rating,
  ratings_count,
  publication_year
FROM
  `goodreads-515120.goodreads_analysis.books` 
WHERE
  average_rating >= 4.0 AND ratings_count BETWEEN 250 AND 500
ORDER BY
  average_rating DESC,
  ratings_count
LIMIT 20;

-- ANALYSIS SUMMARY & NEXT STEPS
-- I explored different rating thresholds and engagement measures to establish criteria for identifying promising books. 
-- This helped narrow the analysis toward books with positive reader ratings but few ratings.
-- Next, I investigated whether multiple editions of the same book were affecting my results, so that each underlying work could be looked at more accurately.
