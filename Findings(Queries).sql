-- Total number of books in the library.
SELECT COUNT(*) FROM books;

-- Average number of days members keep a book before returning it.
SELECT AVG(DATEDIFF(return_date, issued_date)) AS avg_due_day
FROM issued_status i
JOIN return_status r USING (issued_id);

-- Months with the highest number of books issued/borrowed.
SELECT MONTHNAME(issued_date) AS month,
	  COUNT(MONTHNAME(issued_date)) AS count_borrowed_books
FROM issued_status
GROUP BY month
ORDER BY count_borrowed_books DESC;

-- Number of employees in each branch.
SELECT b.branch_id, count(e.emp_id) as num_of_employees
FROM branch b
JOIN employees e USING (branch_id)
GROUP BY b.branch_id
ORDER BY num_of_employees;

-- employees and managers they report to
WITH manager_name AS ((
						SELECT b.manager_id, e.emp_name 
						FROM employees e
                        JOIN branch b USING (branch_id)
						WHERE b.manager_id = e.emp_id
                        ))
SELECT e.emp_id, 
	   e.emp_name, 
       b.manager_id,
       m.emp_name AS manager_name
FROM branch b
JOIN employees e USING (branch_id)
LEFT JOIN manager_name m on b.manager_id=m.manager_id
WHERE e.emp_id <> b.manager_id;


-- Top 10 books with the highest rental price.
SELECT * 
FROM books
ORDER BY rental_price DESC
LIMIT 10;

-- Top 5 members who borrowed the most books.
SELECT i.issued_member_id, m.member_name, COUNT(*) AS num_of_issued_books
FROM issued_status i
JOIN members m ON i.issued_member_id=m.member_id
GROUP BY i.issued_member_id, m.member_name
ORDER BY num_of_issued_books DESC
LIMIT 5;

-- List of all book categories and the number of books in each.
SELECT category, COUNT(*) AS num_of_books
FROM books
GROUP BY category
ORDER BY num_of_books DESC;

-- Top 3 most preferred book categories among members.
SELECT category,
		num_of_issued_books
FROM  (
		SELECT category, COUNT(issued_book_isbn) AS num_of_issued_books,
			   DENSE_RANK() OVER(ORDER BY COUNT(issued_book_isbn) DESC)  as rnk
		FROM issued_status i
		JOIN books b ON i.issued_book_isbn=b.isbn
		GROUP BY category		
	  ) as t1
WHERE rnk<=3;

-- For each month, identify the category with the highest number of books issued/borrowed.
WITH cte1 AS (SELECT MONTHNAME(issued_date) AS issued_month, 
	   category, COUNT(issued_book_isbn) as num_of_issued_books,
       DENSE_RANK() OVER(PARTITION BY MONTHNAME(issued_date) ORDER BY COUNT(issued_book_isbn) DESC ) as rnk
FROM issued_status
JOIN books on issued_book_isbn=isbn
GROUP BY issued_month, category)
SELECT issued_month, category, num_of_issued_books
FROM cte1
WHERE rnk=1;

-- Top 3 publishers based on the number of books in the library.
SELECT publisher, COUNT(*) as numI_of_books
FROM books
GROUP BY publisher
ORDER BY numI_of_books DESC
LIMIT 3;

-- Top 3 authors based on the number of books in the library.
SELECT author, COUNT(*) as numI_of_books
FROM books
GROUP BY author
ORDER BY numI_of_books DESC
LIMIT 3;

-- Identify members with overdue books (assuming a 30-day return period). Display the member's name, book title, issue date, and days overdue.
with cte1 as (
			SELECT issued_date, (DATEDIFF(return_date, issued_date)- 30) as over_due_days
			FROM issued_status
			LEFT JOIN return_status using(issued_id)
            ),
cte2 As (
		SELECT member_id, member_name book_title, issued_date
		FROM issued_status i 
		JOIN members m ON i.issued_member_id=m.member_id
		JOIN books b ON i.issued_book_isbn= b.isbn
	)
SELECT member_id, book_title, issued_date,
      (
	   CASE 
       WHEN over_due_days > 30 OR over_due_days IS NULL THEN '30+'
       ELSE over_due_days
       END) as over_due_day
FROM cte2
JOIN cte1 USING(issued_date);


-- performance report for each branch, showing the number of books issued, the number of books returned, and the total revenue generated from book rentals.
SELECT br.branch_id,
	   COUNT(i.issued_id) as num_of_issued_books,
       COUNT(r.return_id) as num_of_returned_books,
       SUM(b.rental_price) as revenue
FROM branch br
JOIN employees e USING(branch_id)
JOIN issued_status i ON e.emp_id=i.issued_emp_id
LEFT JOIN return_status r ON i.issued_id=r.issued_id
JOIN books b ON i.issued_book_isbn=b.isbn
GROUP BY branch_id;

-- Identify books that have been borrowed the most.
SELECT b.isbn, b.book_title, COUNT(issued_id) AS num_of_borrowed_books
FROM books b
JOIN issued_status i on b.isbn=i.issued_book_isbn
GROUP BY b.isbn, b.book_title
ORDER BY num_of_borrowed_books DESC
LIMIT 5;

-- Determine which days of the week see the most book rentals.
SELECT DAYNAME(issued_date) AS days, COUNT(*) AS num_of_borrowed_books
FROM issued_status
GROUP BY days
ORDER BY num_of_borrowed_books DESC;

-- Which employees issue the most books?
SELECT emp_id, emp_name, position, issued_emp_id, COUNT(issued_id) AS num_of_issued_books
FROM issued_status i
RIGHT JOIN employees e ON i.issued_emp_id=e.emp_id
GROUP BY  emp_id, emp_name, position, issued_emp_id
ORDER BY num_of_issued_books DESC;
