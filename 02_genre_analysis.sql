-- Purpose: Identify the 20 most common genre classifications based on the number of unique books in each category.
-- Fiction and Nonfiction have the most books, but genre size does not necessarily indicate reader engagement.

SELECT
  genre,
  COUNT(DISTINCT book_id) AS unique_books
FROM
  `goodreads-515120.goodreads_analysis.book_genres` 
GROUP BY
  genre
ORDER BY
  unique_books DESC
LIMIT 20;

-- Purpose: Compare average ratings and reviews per book across all genre classifications.
-- Popular franchises and authors had the most results, showing that factors beyond genre influence engagement.

SELECT
  bg.genre,
  COUNT(DISTINCT b.book_id) AS total_books,
  ROUND(AVG(b.ratings_count), 2) AS avg_ratings_per_book,
  ROUND(AVG(b.reviews_count), 2) AS avg_reviews_per_book
FROM
  `goodreads-515120.goodreads_analysis.book_genres` AS bg
INNER JOIN
  `goodreads-515120.goodreads_analysis.books` AS b
ON
  bg.book_id = b.book_id
GROUP BY
  bg.genre
ORDER BY
  avg_ratings_per_book DESC
LIMIT 20;

-- Purpose: Compare average ratings, median ratings, and average reviews per book from the 20 most common genres.
-- Averages are much higher than medians, telling me that highly popular books alter engagement averages upward.
-- Median ratings provide a better picture of typical engagement.

SELECT
  bg.genre,
  COUNT(DISTINCT b.book_id) AS total_books,
  ROUND(AVG(b.ratings_count), 2) AS avg_ratings_per_book,
  ROUND(AVG(b.reviews_count), 2) AS avg_reviews_per_book,
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
)
GROUP BY
  bg.genre
ORDER BY
  avg_ratings_per_book DESC
LIMIT 20;

-- Purpose: Compare average reader satisfaction across the 20 most common genres.
-- Excludes books with zero ratings to avoid treating missing reader feedback as negative ratings.
-- Findings: Art has the highest average rating (4.03).
-- Genre averages range from 3.76 to 4.03, showing a small difference in satisfaction.
-- High engagement does not necessarily mean higher average reader ratings.

SELECT
  bg.genre,
  COUNT(DISTINCT b.book_id) AS total_books,
  ROUND(AVG(b.average_rating), 2) AS avg_reader_rating
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
) AND b.ratings_count > 0
GROUP BY
  bg.genre
ORDER BY
  avg_reader_rating DESC;

-- ANALYSIS SUMMARY & NEXT STEPS
-- This initial exploration looked at how books were distributed across genres and compared their ratings and engagement.
-- These comparisons helped create a baseline for understanding reader activity across different categories.
-- Next, I shifted toward identifying highly rated books with relatively low engagement to evaluate potential marketing opportunities.
