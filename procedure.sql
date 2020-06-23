/***************************************************************************************
 * Converts Treeplexus products.csv into Kassa items.csv
 * Steps:
 *   CSV 'products' -> no_head CSV  -> table 'products' -> table 'items' -> CSV 'items'
 * 12.03.2020   ZT
 * 23.06.2020   v. 1.0.0
 ***************************************************************************************/
\! echo "===== Creating database treeplexus ..."
CREATE DATABASE IF NOT EXISTS `treeplexus`;
USE `treeplexus`;

\! echo "===== Creating table PRODUCTS ..."
DROP TABLE if EXISTS products;
CREATE TABLE `treeplexus`.`products` (
  `id`         SMALLINT UNSIGNED NOT NULL,
  `sku`        VARCHAR(100) NOT NULL,
  `name`       VARCHAR(255) NOT NULL,
  `min_price`  DECIMAL(10,2) UNSIGNED DEFAULT 0.0,
  `price`      DECIMAL(10,2) UNSIGNED NOT NULL
) ENGINE=InnoDB COLLATE utf8_general_ci;

-- Remove header line in CSV file
\! sed '/Артикул/d' products.csv >products_no_header.csv 

\! echo "===== Loading table PRODUCTS ..."
LOAD DATA 
INFILE '/Users/zhenya/ZT_Lab/DB/Projects/Kassa/products_no_header.csv'
REPLACE
INTO TABLE `treeplexus`.`products`
  FIELDS TERMINATED BY ',' 
  ENCLOSED BY '"'
LINES TERMINATED BY '\n'
(id, sku, name,  @min_price, price)
set min_price = if(@min_price = '', 0.0, @min_price);

\! echo "===== Creating table ITEMS ..."
DROP TABLE if EXISTS `treeplexus`.`items`;
CREATE TABLE `treeplexus`.`items` (
  `название товара`       VARCHAR(255) NOT NULL,
  `код товара`            VARCHAR(50)  NOT NULL,
  `штрихкод`              VARCHAR(50)  NOT NULL,
  `цена товара`           DECIMAL(10,2) UNSIGNED NOT NULL,
  `единица измерения`     ENUM('шт', 'кг', 'час', 'л', 'м', 'кв.м', 'куб.м', 'другая') DEFAULT 'шт',
  `короткое наименование` VARCHAR(255) DEFAULT '',
  `группа`                VARCHAR(255) DEFAULT '',
  `НДС`                   ENUM('0', '10', '20', '-', '10/100', '20/100', '') DEFAULT '0',
  `СНО`                   ENUM ('ОСН', 'УСН-ДР', 'УСН-Д', 'ЕНВД', 'ПСН', 'ЕСХН', '') DEFAULT 'УСН-Д',
  `тип`                   ENUM ('Товар', 'Услуга', 'Страховая услуга', 'Аванс', 'Слабоалкогольный', 'Алкоголь', 'Табак', 'Акцизный', 'Работа', 'РИД') DEFAULT 'Товар',
  `минимальная цена`      DECIMAL(10,2) UNSIGNED DEFAULT 0.0,
  `маркированный товар`   ENUM ('Да', 'Нет', '') DEFAULT ''
);
\! echo "Inserting table ITEMS ..."
INSERT INTO `treeplexus`.`items` (`название товара`, `код товара`, `штрихкод`, `цена товара`, `минимальная цена`) 
SELECT `name`, `sku`, `sku`, `price`, `min_price` FROM `treeplexus`.`products`;
\! rm -f items.csv

\! echo "Creating output file ITEMS.CSV ..."
-- Field names below MUST BE in '' - not in ``
SELECT 'название товара', 'код товара', 'штрихкод', 'цена товара', 'единица измерения', 'короткое наименование', 'группа', 'НДС', 'СНО', 'тип', 'минимальная цена', 'маркированный товар'
UNION ALL
SELECT * 
  FROM treeplexus.items 
  INTO OUTFILE '/Users/zhenya/ZT_Lab/DB/Projects/Kassa/items.csv'
  FIELDS
    ENCLOSED BY "" 
    TERMINATED BY ',' 
    ESCAPED BY '"' 
  LINES
    TERMINATED BY '\r\n'; 

\! echo "Removing database treeplexus ..."
DROP DATABASE IF EXISTS `treeplexus`;
