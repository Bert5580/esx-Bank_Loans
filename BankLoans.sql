-- ESX Legacy (mysql-async) compatible schema (clean baseline)
-- Import once into your target database (e.g., esxlegacy_af7a7d)

-- Ensure schema selected
-- USE `esxlegacy_af7a7d`;

-- USERS (minimal fields we touch)
CREATE TABLE IF NOT EXISTS `users` (
  `identifier` VARCHAR(60) NOT NULL,
  `accounts` LONGTEXT DEFAULT NULL,
  PRIMARY KEY (`identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Add index if missing (MySQL doesn’t support IF NOT EXISTS for indexes in all versions)
-- Safe to re-run; if it exists, MySQL will error—ignore or run manually once.
ALTER TABLE `users` ADD INDEX `idx_identifier` (`identifier`);

-- PLAYER LOANS
CREATE TABLE IF NOT EXISTS `player_loans` (
  `id` INT(11) NOT NULL AUTO_INCREMENT,
  `identifier` VARCHAR(60) NOT NULL,
  `loan_amount` DECIMAL(12,2) NOT NULL,
  `interest_rate` DECIMAL(5,4) NOT NULL DEFAULT 0.0500,
  `total_debt` DECIMAL(12,2) NOT NULL,
  `amount_paid` DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  `date_taken` DATETIME DEFAULT CURRENT_TIMESTAMP,
  `last_payment` DATETIME DEFAULT NULL,
  `status` ENUM('ACTIVE','PAID','DEFAULTED') NOT NULL DEFAULT 'ACTIVE',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Optional history table if you want to log actions
CREATE TABLE IF NOT EXISTS `loan_history` (
  `id` INT(11) NOT NULL AUTO_INCREMENT,
  `identifier` VARCHAR(60) NOT NULL,
  `loan_id` INT(11) DEFAULT NULL,
  `action_type` ENUM('GRANT','REPAY','ADJUST') NOT NULL,
  `amount` DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  `notes` VARCHAR(255) DEFAULT NULL,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Foreign keys (drop if they already exist before re-adding)
ALTER TABLE `player_loans`
  ADD CONSTRAINT `fk_player_loans_users`
  FOREIGN KEY (`identifier`) REFERENCES `users`(`identifier`)
  ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE `loan_history`
  ADD CONSTRAINT `fk_loan_history_users`
  FOREIGN KEY (`identifier`) REFERENCES `users`(`identifier`)
  ON UPDATE CASCADE ON DELETE CASCADE;

-- Useful index on status
CREATE INDEX `idx_loans_status` ON `player_loans`(`status`);
