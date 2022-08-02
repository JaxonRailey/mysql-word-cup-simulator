SET FOREIGN_KEY_CHECKS = 0;

/*
 * Type: Table
 * Name: team
 * Purpose: teams participating in the league
 * --------------------------------
 */

DROP TABLE IF EXISTS `team`;
CREATE TABLE `team` (
    `id_team` INT(1) PRIMARY KEY AUTO_INCREMENT,
    `name` VARCHAR(255) DEFAULT NULL,
    `winner` INT(1) DEFAULT NULL
) ENGINE = InnoDB DEFAULT CHARSET = utf8;

INSERT INTO `team` (`name`) VALUES ('Qatar');
INSERT INTO `team` (`name`) VALUES ('Germania');
INSERT INTO `team` (`name`) VALUES ('Danimarca');
INSERT INTO `team` (`name`) VALUES ('Brasile');
INSERT INTO `team` (`name`) VALUES ('Belgio');
INSERT INTO `team` (`name`) VALUES ('Francia');
INSERT INTO `team` (`name`) VALUES ('Croazia');
INSERT INTO `team` (`name`) VALUES ('Spagna');
INSERT INTO `team` (`name`) VALUES ('Serbia');
INSERT INTO `team` (`name`) VALUES ('Inghilterra');
INSERT INTO `team` (`name`) VALUES ('Svizzera');
INSERT INTO `team` (`name`) VALUES ('Olanda');
INSERT INTO `team` (`name`) VALUES ('Argentina');
INSERT INTO `team` (`name`) VALUES ('Iran');
INSERT INTO `team` (`name`) VALUES ('Corea del Sud');
INSERT INTO `team` (`name`) VALUES ('Giappone');
INSERT INTO `team` (`name`) VALUES ('Arabia Saudita');
INSERT INTO `team` (`name`) VALUES ('Ecuador');
INSERT INTO `team` (`name`) VALUES ('Uruguay');
INSERT INTO `team` (`name`) VALUES ('Canada');
INSERT INTO `team` (`name`) VALUES ('Ghana');
INSERT INTO `team` (`name`) VALUES ('Senegal');
INSERT INTO `team` (`name`) VALUES ('Portogallo');
INSERT INTO `team` (`name`) VALUES ('Polonia');
INSERT INTO `team` (`name`) VALUES ('Marocco');
INSERT INTO `team` (`name`) VALUES ('Tunisia');
INSERT INTO `team` (`name`) VALUES ('Camerun');
INSERT INTO `team` (`name`) VALUES ('Messico');
INSERT INTO `team` (`name`) VALUES ('Stati Uniti');
INSERT INTO `team` (`name`) VALUES ('Galles');
INSERT INTO `team` (`name`) VALUES ('Australia');
INSERT INTO `team` (`name`) VALUES ('Costa Rica');


/*
 * Type: Table
 * Name: match
 * Purpose: each row a pair of teams with relative result
 * --------------------------------
 */

DROP TABLE IF EXISTS `match`;
CREATE TABLE `match` (
    `team_1` INT(1),
    `team_2` INT(1),
    `score_1` INT(1),
    `score_2` INT(1),
    `step` INT(1) DEFAULT 1,
    FOREIGN KEY(`team_1`) REFERENCES `team`(`id_team`)
        ON DELETE SET NULL
        ON UPDATE CASCADE,
    FOREIGN KEY(`team_2`) REFERENCES `team`(`id_team`)
        ON DELETE SET NULL
        ON UPDATE CASCADE
) ENGINE = InnoDB DEFAULT CHARSET = utf8;


/*
 * Type: Function
 * Name: score
 * Purpose: generate goals scored by the opposing team
 * --------------------------------
 */

DROP FUNCTION IF EXISTS `score`;
DELIMITER $$
CREATE FUNCTION `score`(`s1` INT(1))
    RETURNS INT(1)
    READS SQL DATA NOT DETERMINISTIC
    BEGIN
        DECLARE `val` INT(1);
        SET `val` = `s1`;
        WHILE `val` = `s1` DO
            SET `val` = FLOOR(RAND() * 5);
        END WHILE;
        RETURN `val`;
    END $$
DELIMITER ;


/*
 * Type: Procedure
 * Name: simulate
 * Purpose: simulation of match results, the winning team continues the league
 * --------------------------------
 */

DELIMITER $$
DROP PROCEDURE IF EXISTS `simulate`;
CREATE PROCEDURE `simulate`()
BEGIN
    DECLARE `totalRows` INT DEFAULT 0;
    DECLARE `i` INT DEFAULT 0;
    DECLARE `j` INT DEFAULT 1;
    DECLARE `k` INT DEFAULT 1;
    DECLARE `s1` INT DEFAULT 0;
    SET `k` = (SELECT COUNT(*) FROM `team`) / 2;
    UPDATE `team` SET `winner` = NULL;
    TRUNCATE TABLE `match`;
    WHILE `j` < `k` DO
        SET `totalRows` = (SELECT COUNT(*) FROM `team` WHERE `winner` IS NULL);
        SET `i` = 0;
        WHILE `i` < `totalRows` DO
            SET `s1` = FLOOR(RAND() * 5);

            -- generate a random match between two teams still competing
            INSERT INTO `match` (`team_1`, `team_2`, `score_1`, `score_2`, `step`)
            SELECT a.`id_team`, b.`id_team`, `s1`, score(`s1`), `j`
            FROM `team` a
            INNER JOIN `team` b ON a.`id_team` < b.`id_team`
            WHERE (a.`winner` IS NULL AND b.`winner` IS NULL)
            AND NOT EXISTS (
                SELECT *
                FROM `match` c
                WHERE c.`team_1` IN (a.`id_team`, b.`id_team`)
                AND `step` = `j`)
            AND NOT EXISTS (
                SELECT *
                FROM `match` c
                WHERE c.`team_2` IN (a.`id_team`, b.`id_team`)
                AND `step` = `j`)
            ORDER BY a.`id_team` * RAND()
            LIMIT 1;
            SET `i` = `i` + 1;
        END WHILE;

        -- mark team loser
        UPDATE `team`
        SET `winner` = 0
        WHERE `id_team` IN (
            SELECT `team_1`
            FROM `match`
            WHERE `score_1` <= `score_2`
        UNION
            SELECT `team_2`
            FROM `match`
            WHERE `score_2` < `score_1`);

        SET `j` = `j` + 1;
    END WHILE;

    -- mark the winner
    UPDATE `team` SET `winner` = 1 WHERE `winner` IS NULL;

    -- creates a temporary table with the sum of goals scored and conceded
    DROP TEMPORARY TABLE IF EXISTS `gol`;
    CREATE TEMPORARY TABLE `gol` AS
    SELECT
        `team`.`id_team` AS `id_team`,
        `team`.`name` AS `name`,
        `team`.`winner` AS `winner`,
        SUM(`score_1`) AS `scored`,
        SUM(`score_2`) AS `conceded`
    FROM `team`
    JOIN `match` ON `team`.`id_team` = `match`.`team_1`
    WHERE `match`.`team_1` = `team`.`id_team`
    GROUP BY `team`.`name`
    UNION
    SELECT
        `team`.`id_team` AS `id_team`,
        `team`.`name` AS `name`,
        `team`.`winner` AS `winner`,
        SUM(`score_2`) AS `scored`,
        SUM(`score_1`) AS `conceded`
    FROM `team`
    JOIN `match` ON `team`.`id_team` = `match`.`team_2`
    WHERE `match`.`team_2` = `team`.`id_team`
    GROUP BY `team`.`name`;

    -- view the competition report
    SELECT
        `id_team`,
        `name`,
        SUM(`scored`) AS `scored`,
        SUM(`conceded`) AS `conceded`,
        SUM(`scored`) - SUM(`conceded`) AS `diff`,
        `winner`
    FROM `gol`
    GROUP BY `id_team`
    ORDER BY `diff` DESC;
END $$
DELIMITER ;

CALL simulate();

SET FOREIGN_KEY_CHECKS = 1;
