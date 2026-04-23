ALTER TABLE Bam RENAME [DATE] TO [SaleDate];

ALTER TABLE Bam ADD COLUMN dates TEXT;

UPDATE Bam SET dates =
    substr(SaleDate, 7, 4) || '-' ||
    substr(SaleDate, 1, 2) || '-' ||
    substr(SaleDate, 4, 2);

UPDATE Bam SET dates = '20' || dates;

ALTER TABLE Bam DROP COLUMN SaleDate;

INSERT OR IGNORE INTO misc (date, item_name, size_label, quantity_sold, price_per_unit, total_amount)
SELECT dates, "ITEM ID", SIZE, "QTY SOLD (STD)", PRICE, "AMOUNT TOTAL"
FROM Bam
WHERE SIZE = 'Order'
OR "ITEM ID" IN ('1st Anniv Glass', '2nd Anniv Glass', 'EMPTY Pint Day Glass', '1st Anniv Mug');

INSERT OR IGNORE INTO beers (beer_name)
SELECT DISTINCT "ITEM ID" FROM Bam
WHERE SIZE != 'Order'
AND "ITEM ID" NOT IN ('1st Anniv Glass', '2nd Anniv Glass', 'EMPTY Pint Day Glass', '1st Anniv Mug');

INSERT OR IGNORE INTO sales (date, beer_id, pour_type_id, quantity_sold, price_per_unit, total_amount)
SELECT
    Bam.dates,
    beers.beer_id,
    PourTypes.pour_type_id,
    Bam."QTY SOLD (STD)",
    Bam.PRICE,
    Bam."Amount TOTAL"
FROM Bam
JOIN beers ON beers.beer_name = Bam."ITEM ID"
JOIN PourTypes ON PourTypes.label = Bam."SIZE"
WHERE Bam.SIZE != 'Order'
AND Bam."ITEM ID" NOT IN ('1st Anniv Glass', '2nd Anniv Glass', 'EMPTY Pint Day Glass', '1st Anniv Mug');

INSERT OR IGNORE INTO InventoryLog (beer_id, date, event_type, volume_gallons, notes)
SELECT
    b.beer_id,
    s.date,
    'consumption',
    -ROUND(SUM(s.quantity_sold * ps.volume_oz) / 128.0, 2),
    'auto from sales'
FROM sales s
JOIN beers b ON b.beer_id = s.beer_id
JOIN PourTypes pt ON pt.pour_type_id = s.pour_type_id
JOIN PourSizes ps ON ps.volume_oz = pt.volume_oz
GROUP BY b.beer_id, s.date;

SELECT *FROM InventoryLog  