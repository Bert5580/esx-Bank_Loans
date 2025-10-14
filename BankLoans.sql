-- Tables (idempotent if executed once)
CREATE TABLE IF NOT EXISTS `player_loans` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `citizenid` VARCHAR(50) NOT NULL,
  `principal` INT NOT NULL DEFAULT 0,
  `interest_rate` DECIMAL(5,4) NOT NULL DEFAULT 0.0300,
  `total_debt` INT NOT NULL DEFAULT 0,
  `amount_paid` INT NOT NULL DEFAULT 0,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_citizenid` (`citizenid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `loan_history` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `citizenid` VARCHAR(50) NOT NULL,
  `action` VARCHAR(32) NOT NULL,
  `amount` INT DEFAULT 0,
  `meta` TEXT,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_citizenid` (`citizenid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
