/* ==========================================================================
   project10_starter.sql
   CIS 4720 Database Management and SQL
   Project 10, A Front Door for club_db

   WHAT THIS FILE IS
   Project 9 finished, plus a numbered heading for every step of Project 10.
   Starting from this file means it does not matter how Project 9 went.

   WHAT IT ALREADY BUILDS
     1. member (100 to 103), payment (from 5000) and payment_log
     2. The member_total function
     3. The three triggers from Project 9
     4. The four payments from Project 9, with payment 5001 removed

   BEFORE YOU WRITE ANYTHING
   Check the totals: Noor 45.00, Caleb 45.00, Sofia 60.00, Desmond 0.00,
   and five rows in payment_log.

   HOW TO RUN IT
   One statement at a time. Put the cursor on it and press Ctrl + E twice.
   Anything that runs from CREATE down to END (a function, a trigger or a
   procedure) is ONE statement, however many semicolons are inside it.
   Select the whole block and run the selection. No DELIMITER lines.

   LABELING AND COMMENTING IS REQUIRED
   Above every statement you write, put a short comment in your own words
   saying what it does. The comments are graded.
   ========================================================================== */


-- =================================================================
-- SETUP. Run these three first, one at a time, while you are still
-- connected to information_schema.
-- =================================================================

-- every schema on this server. club_db will not be in the list yet.
show databases;

-- make yours. IF NOT EXISTS means it is safe to run twice.
create database if not exists club_db;

-- switch into it, so everything below lands in the right place.
use club_db;


-- ==================================================================
-- FROM PROJECT 9. member. member_id starts at 100.
-- ==================================================================
CREATE TABLE member (
    member_id  INT AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(30) NOT NULL,
    last_name  VARCHAR(30) NOT NULL,
    joined_on  DATE,
    total_paid DECIMAL(7,2) DEFAULT 0.00
) AUTO_INCREMENT = 100;
INSERT INTO member (first_name, last_name, joined_on) VALUES ('Noor','Haddad','2026-01-15');
INSERT INTO member (first_name, last_name, joined_on) VALUES ('Caleb','Ortiz','2026-02-03');
INSERT INTO member (first_name, last_name, joined_on) VALUES ('Sofia','Marchetti','2026-02-28');
INSERT INTO member (first_name, last_name, joined_on) VALUES ('Desmond','Blake','2026-03-11');

-- ==================================================================
-- FROM PROJECT 9 Step 2. payment, key starting at 5000.
-- ==================================================================
CREATE TABLE payment (
    payment_id INT AUTO_INCREMENT PRIMARY KEY,
    member_id  INT NOT NULL,
    amount     DECIMAL(7,2) NOT NULL,
    paid_on    DATE,
    method     VARCHAR(10),
    FOREIGN KEY (member_id) REFERENCES member(member_id)
) AUTO_INCREMENT = 5000;

-- ==================================================================
-- FROM PROJECT 9 Step 3. payment_log. No foreign key, on purpose.
-- ==================================================================
CREATE TABLE payment_log (
    log_id    INT AUTO_INCREMENT PRIMARY KEY,
    member_id INT,
    amount    DECIMAL(7,2),
    action    VARCHAR(20),
    logged_on DATETIME
);

-- ==================================================================
-- FROM PROJECT 9 Step 5. The member_total function. Select the whole block.
-- ==================================================================
CREATE FUNCTION member_total(p_member_id INT)
RETURNS DECIMAL(7,2)
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_total DECIMAL(7,2);

    SELECT SUM(amount)
    INTO v_total
    FROM payment
    WHERE member_id = p_member_id;

    RETURN IFNULL(v_total, 0.00);
END;

-- ==================================================================
-- FROM PROJECT 9 Step 6. Fills in a missing date and capitalizes the method.
-- ==================================================================
CREATE TRIGGER trg_payment_before_insert
BEFORE INSERT ON payment
FOR EACH ROW
BEGIN
    IF NEW.paid_on IS NULL THEN
        SET NEW.paid_on = CURDATE();
    END IF;
    SET NEW.method = UPPER(NEW.method);
END;

-- ==================================================================
-- FROM PROJECT 9 Step 7. Updates the total and writes ADDED to the log.
-- ==================================================================
CREATE TRIGGER trg_payment_after_insert
AFTER INSERT ON payment
FOR EACH ROW
BEGIN
    UPDATE member
    SET total_paid = member_total(NEW.member_id)
    WHERE member_id = NEW.member_id;

    INSERT INTO payment_log (member_id, amount, action, logged_on)
    VALUES (NEW.member_id, NEW.amount, 'ADDED', NOW());
END;

-- ==================================================================
-- FROM PROJECT 9 Step 8. Updates the total and writes REMOVED to the log.
-- ==================================================================
CREATE TRIGGER trg_payment_after_delete
AFTER DELETE ON payment
FOR EACH ROW
BEGIN
    UPDATE member
    SET total_paid = member_total(OLD.member_id)
    WHERE member_id = OLD.member_id;

    INSERT INTO payment_log (member_id, amount, action, logged_on)
    VALUES (OLD.member_id, OLD.amount, 'REMOVED', NOW());
END;

-- ==================================================================
-- FROM PROJECT 9 Step 9. The four payments. The triggers do the rest.
-- ==================================================================
INSERT INTO payment (member_id, amount, method) VALUES (100, 45.00, 'cash');
INSERT INTO payment (member_id, amount, paid_on, method) VALUES (100, 30.00, '2026-04-02', 'card');
INSERT INTO payment (member_id, amount, method) VALUES (101, 45.00, 'check');
INSERT INTO payment (member_id, amount, paid_on, method) VALUES (102, 60.00, '2026-03-15', 'card');

-- ==================================================================
-- FROM PROJECT 9 Step 9. Removing payment 5001.
-- ==================================================================
DELETE FROM payment WHERE payment_id = 5001;


-- ======================================================================
-- CHECKS. These only read, so they are safe to run again any time.
-- ======================================================================

SELECT * FROM member;
SELECT * FROM payment;
SELECT * FROM payment_log;


-- ######################################################################
-- YOUR PROJECT 10 WORK STARTS BELOW THIS LINE
--
-- LABELING AND COMMENTING IS REQUIRED. It is worth a full point.
--
-- You write Steps 2, 3, 7, 8, 9 and 10 yourself. Steps 4 and 5 are
-- skeletons with one statement for you to write. Step 6 is mostly yours.
-- ######################################################################


-- =================================================================
-- STEP 2. list_members
-- =================================================================

-- create a list_members with no parameters
CREATE PROCEDURE list_members()
BEGIN
    SELECT member_id, first_name, last_name, total_paid
    FROM member
    ORDER BY last_name;
END;

CALL list_members();


-- =================================================================
-- STEP 3. member_history, with an IN parameter
-- =================================================================

-- create a member_history with one IN parameter
CREATE PROCEDURE member_history(IN p_member_id INT)
BEGIN
    SELECT p.payment_id, p.amount, p.paid_on, p.method
    FROM payment p
    WHERE p.member_id = p_member_id;
END;

-- calling member_history with member_id 100 and 103
-- to see their payment history
CALL member_history(100);
CALL member_history(103);


-- =================================================================
-- STEP 4. add_member
--
-- Copy the skeleton from the handout and write the INSERT.
-- =================================================================

-- adds a new member
-- adds a new member, who joins today
CREATE PROCEDURE add_member(IN p_first VARCHAR(30),
IN p_last VARCHAR(30))
BEGIN
-- store the new member, with today as the joining date
    INSERT INTO member (first_name, last_name, joined_on)
    VALUES (p_first, p_last, CURDATE());
END;



-- =================================================================
-- STEP 5. make_payment
--
-- Copy the skeleton and write the INSERT.
-- =================================================================

-- adds a payment for a member
-- takes a payment. the triggers do the bookkeeping
CREATE PROCEDURE make_payment(IN p_member_id INT,
IN p_amount DECIMAL(7,2),
IN p_method VARCHAR(10))
BEGIN
-- store the payment and let the triggers do the rest
    INSERT INTO payment (member_id, amount, method)
    VALUES (p_member_id, p_amount, p_method);
END;    


-- =================================================================
-- STEP 6. refund_payment
--
-- Most of this one is yours. The handout walks you through it.
-- =================================================================

-- refunds a payment for a member
CREATE PROCEDURE refund_payment(IN p_payment_id INT)
BEGIN
    DELETE FROM payment 
    WHERE payment_id = p_payment_id;
END;

-- =================================================================
-- STEP 7. Change list_members to show the biggest payers first
-- =================================================================

-- change list_members 
--shows the biggest payers
--drop the list to create another one
DROP PROCEDURE IF EXISTS list_members;

CREATE PROCEDURE list_members()
BEGIN
    SELECT member_id, first_name, last_name, total_paid
    FROM member
    ORDER BY total_paid DESC;
END;

--shows the changes made to the list_members procedure
CALL list_members();

-- =================================================================
-- STEP 8. Run the club for a day
-- =================================================================

-- running the club by adding a new member
CALL add_member('Imani', 'Brooks');
CALL list_members();
-- making a payment
CALL make_payment(104, 50.00, 'card');
CALL member_history(104);
--and refunding a payment
CALL refund_payment(5000);
--calling list_members to see the changes
CALL list_members();
--selecting from payment_log to see the changes
SELECT *
FROM payment_log;


-- =================================================================
-- STEP 9. Three problems, left open on purpose
--
-- Under each call, a comment on what happened and what should have.
-- =================================================================

-- calling member_history with a non-existent member_id
CALL make_payment(999, 20.00, 'cash');
--this failed because there is no member with id 999
-- so the foreign key constraint prevented the payment from being added.

CALL make_payment(103, 10.00, 'cash');
--this worked because member 103 exists
--so the payment was added successfully.
CALL list_members();
--the total_paid for member 103 increased by 10.00

CALL refund_payment(7777);
--this failed because there is no payment with id 7777

--clean up Desmonds payment history
CALL member_history(103);
CALL make_payment(103, -10.00, 'cash');
call list_members();

-- =================================================================
-- STEP 10. List every routine in club_db
-- =================================================================

-- list every routine in club_db in order
SELECT routine_name, routine_type
FROM information_schema.routines
WHERE routine_schema = 'club_db'
ORDER BY routine_name;




-- =================================================================
-- STEP 11 and 12. Push to GitHub and submit the URL
--
-- Nothing to write here. Follow the handout.
-- =================================================================

-- your comment goes here
-- your statements go here
