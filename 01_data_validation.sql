-- Purpose: Validate the books and book_genres tables after importing them into BigQuery.
-- Confirmed 500,000 unique books and 1,074,176 book-genre combinations across 192,380 books with assigned genres.

SELECT 
  COUNT(*) AS total_books,
  COUNT(DISTINCT book_id) AS unique_books
FROM 
  `goodreads-515120.goodreads_analysis.books`;
SELECT
  COUNT(*) AS total_book_genres,
  COUNT(DISTINCT book_id) AS unique_books
FROM
  `goodreads-515120.goodreads_analysis.book_genres`
