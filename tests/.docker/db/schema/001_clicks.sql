USE activity;

DROP TABLE IF EXISTS `clicks`;
CREATE TABLE `clicks` (
  `id`            INT(8)       NOT NULL AUTO_INCREMENT COMMENT 'Primary Key',
  `identity`      VARCHAR(64)  NOT NULL COMMENT 'the user identity',
  `url`           VARCHAR(64)  NOT NULL COMMENT 'the site where the event occurred',
  `type`          VARCHAR(64)  NULL COMMENT 'usually left or right click, but can be other buttons',
  `timestamp`     VARCHAR(64)  NULL COMMENT 'when the click happened',
  `coordinates`   VARCHAR(64)  NULL COMMENT 'position of cursor on screen',
  `update_date`   TIMESTAMP    DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `created_date`  TIMESTAMP    DEFAULT CURRENT_TIMESTAMP,

  PRIMARY KEY (`id`)
)

ENGINE  = InnoDB
DEFAULT CHARSET = utf8
AUTO_INCREMENT = 1;
