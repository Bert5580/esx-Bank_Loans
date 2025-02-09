-- BankLoans.sql
-- SQL script to set up the database schema for the Bank Loans system with a credit system.

-- ===========================================
-- STEP 1: Add Missing Columns to `users`
-- ===========================================

-- Add a `debit` column to the `users` table for tracking loan debt
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS debit DECIMAL(10,2) DEFAULT 0.00;

-- Add a `credit_score` column to the `users` table for the credit system
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS credit_score INT DEFAULT 100;

-- Ensure `identifier` in the `users` table is indexed for references
ALTER TABLE users 
ADD UNIQUE INDEX IF NOT EXISTS idx_identifier (identifier);

-- ===========================================
-- STEP 2: Define `player_loans` Table
-- ===========================================

-- Create the `player_loans` table for detailed loan tracking
CREATE TABLE IF NOT EXISTS player_loans (
    id INT AUTO_INCREMENT PRIMARY KEY,                    -- Unique ID for each loan
    identifier VARCHAR(50) NOT NULL,                      -- Links to users.identifier
    loan_amount DOUBLE NOT NULL,                         -- Loan amount
    interest_rate DOUBLE NOT NULL DEFAULT 0.05,          -- Default interest rate: 5%
    total_debt DOUBLE NOT NULL,                          -- Total debt (loan + interest)
    amount_paid DOUBLE DEFAULT 0,                        -- Amount paid so far
    date_taken DATETIME DEFAULT CURRENT_TIMESTAMP,       -- Date when the loan was taken
    last_payment DATETIME DEFAULT NULL,                  -- Date of the last payment
    FOREIGN KEY (identifier) REFERENCES users(identifier) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- ===========================================
-- STEP 3: Add Test Data
-- ===========================================

-- Insert a test loan into the `player_loans` table (remove this after testing)
INSERT INTO player_loans (identifier, loan_amount, interest_rate, total_debt, amount_paid) 
VALUES ('TESTIDENTIFIER123', 5000, 0.05, 5250, 0);

-- ===========================================
-- STEP 4: Example Queries for Loan Management
-- ===========================================

-- Calculate the remaining debt for a player
SELECT total_debt - amount_paid AS remaining_debt 
FROM player_loans 
WHERE identifier = 'TESTIDENTIFIER123';

-- Update the credit when a player repays a loan
UPDATE users 
SET credit_score = credit_score + 50 
WHERE identifier = 'TESTIDENTIFIER123';

-- Deduct the credit for missed payments
UPDATE users 
SET credit_score = credit_score - 10 
WHERE identifier = 'TESTIDENTIFIER123';

-- ===========================================
-- STEP 5: Stored Procedures for Loan Validation
-- ===========================================

DELIMITER //
CREATE PROCEDURE sp_validate_loans()
BEGIN
    -- Check for missing users in player_loans (orphaned loans)
    SELECT * FROM player_loans WHERE identifier NOT IN (SELECT identifier FROM users);

    -- Check for negative debts (invalid entries)
    SELECT * FROM player_loans WHERE total_debt < 0 OR amount_paid < 0;

    -- Check for overpaid loans (paid more than required)
    SELECT * FROM player_loans WHERE amount_paid > total_debt;
END //
DELIMITER ;

-- ===========================================
-- STEP 6: Auto Credit Increase on Full Repayment
-- ===========================================

DELIMITER //
CREATE TRIGGER trg_credit_on_full_repayment
AFTER UPDATE ON player_loans
FOR EACH ROW
BEGIN
    IF NEW.amount_paid >= NEW.total_debt THEN
        UPDATE users SET credit_score = credit_score + 50 WHERE identifier = NEW.identifier;
    END IF;
END //
DELIMITER ;

-- ===========================================
-- STEP 7: Auto Deduct Loan Payments from Paychecks
-- ===========================================

DELIMITER //
CREATE PROCEDURE sp_auto_repay_loans(player_identifier VARCHAR(50), paycheck_amount DOUBLE)
BEGIN
    DECLARE remaining_debt DOUBLE;
    DECLARE repayment_amount DOUBLE;
    
    -- Get total debt
    SELECT SUM(total_debt - amount_paid) INTO remaining_debt FROM player_loans WHERE identifier = player_identifier;
    
    -- Calculate repayment (50% of paycheck)
    SET repayment_amount = paycheck_amount * 0.50;
    
    -- Deduct from the oldest loan first
    IF remaining_debt > 0 THEN
        UPDATE player_loans 
        SET amount_paid = amount_paid + LEAST(repayment_amount, total_debt - amount_paid) 
        WHERE identifier = player_identifier 
        ORDER BY date_taken ASC 
        LIMIT 1;
    END IF;
END //
DELIMITER ;

-- ===========================================
-- STEP 8: Auto Apply Interest on Loans
-- ===========================================

DELIMITER //
CREATE EVENT apply_interest_event
ON SCHEDULE EVERY 1 MONTH STARTS NOW()
DO
BEGIN
    UPDATE player_loans 
    SET total_debt = total_debt + (total_debt * interest_rate)
    WHERE total_debt > amount_paid;
END //
DELIMITER ;

-- ===========================================
-- STEP 9: Loan History Logging
-- ===========================================

CREATE TABLE IF NOT EXISTS loan_history (
    id INT AUTO_INCREMENT PRIMARY KEY,
    identifier VARCHAR(50) NOT NULL,
    loan_amount DOUBLE NOT NULL,
    interest_rate DOUBLE NOT NULL,
    date_taken DATETIME DEFAULT CURRENT_TIMESTAMP,
    action_type ENUM('GRANTED', 'REPAID') NOT NULL
);
