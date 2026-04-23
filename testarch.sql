CREATE TABLE beers (
	beer_id INTEGER PRIMARY KEY,
	beer_name TEXT NOT NULL UNIQUE,
	lead_time_days INTEGER,
	brew_threshold REAL
	);

CREATE TABLE PourSizes (
	size_id INTEGER PRIMARY KEY,
	volume_oz INTEGER NOT NULL UNIQUE 
	);

INSERT INTO PourSizes (volume_oz) VALUES
	(5),
	(10),
	(16),
	(20),
	(25),
	(32),
	(661);

CREATE TABLE PourTypes (
	pour_type_id INTEGER PRIMARY KEY,
	label TEXT NOT NULL UNIQUE,
	volume_oz INTEGER NOT NULL,
	category TEXT,
	FOREIGN KEY (volume_oz) REFERENCES PourSizes(volume_oz)
	);

INSERT INTO PourTypes (label, volume_oz, category) VALUES
	('5oz', 5, 'regular'),
	('MC5oz', 5, 'mug club'),
	('10oz', 10, 'regular'),
	('MC10oz', 10, 'mug club'),
	('16oz', 16, 'regular'),
	('HH Pint', 
	16, 'happy hour'),
	('25oz', 25, 'regular'),
	('20oz', 20, 'regular'),
	('MH2', 20, 'mug club happy hour'),
	('MC20oz', 20, 'mug club'),
	('32oz Crowler', 32, 'to-go'),
	('.16', 661, 'keg');

CREATE TABLE sales (
	sale_id INTEGER PRIMARY KEY,
	date TEXT NOT NULL,
	beer_id INTEGER NOT NULL,
	pour_type_id INTEGER NOT NULL,
	quantity_sold INTEGER NOT NULL,
	price_per_unit REAL,
	total_amount REAL,
	FOREIGN KEY (beer_id) REFERENCES beers (beer_id),
	FOREIGN KEY (pour_type_id) REFERENCES PourTypes(pour_type_id),
	UNIQUE (date, beer_id, pour_type_id)
	);

CREATE TABLE InventoryLog (
	log_id INTEGER PRIMARY KEY,
	beer_id INTEGER NOT NULL,
	date TEXT NOT NULL,
	event_type TEXT NOT NULL,
	volume_gallons REAL NOT NULL,
	notes TEXT,
	FOREIGN KEY (beer_id) REFERENCES beers(beer_id)
	);

-- need table separately for flights and pubpass = misc
CREATE TABLE misc (
	misc_id INTEGER PRIMARY KEY,
	date TEXT NOT NULL,
	item_name TEXT,
	size_label TEXT, 
	quantity_sold INTEGER,
	price_per_unit REAL,
	total_amount REAL
	);

CREATE VIEW DailySummary AS
SELECT 
	s.date,
	b.beer_name,
	pt.label,
	pt.category,
	ps.volume_oz,
	SUM(s.quantity_sold) as total_units_sold,
	SUM(s.quantity_sold * ps.volume_oz) as total_volume_oz,
	ROUND(SUM(s.quantity_sold * ps.volume_oz) / 128.0, 2) as total_volume_gallons,
	SUM (s.total_amount) as total_revenue
FROM Sales s
JOIN beers b ON b.beer_id = s.beer_id
JOIN PourTypes pt ON pt.pour_type_id = s.pour_type_id
JOIN PourSizes ps ON ps.volume_oz = pt.volume_oz
GROUP BY s.date, b.beer_name, pt.label, pt.category, ps.volume_oz;
-- SUCCESS


--Identical view to DailySummary but time now includes T16:00:00 for ISO stuff
CREATE VIEW Daily AS
SELECT 
    date || 'T16:00:00' as time,
    beer_name,
    label,
    category,
    volume_oz,
    total_units_sold,
    total_volume_oz,
    total_volume_gallons,
    total_revenue
FROM DailySummary;

CREATE VIEW InventoryTimeline AS
SELECT
    b.beer_name,
    b.brew_threshold,
    b.lead_time_days,
    il.date,
    il.event_type,
    il.volume_gallons,
    ROUND(SUM(il.volume_gallons) OVER (
        PARTITION BY b.beer_id 
        ORDER BY il.date
    ), 2) AS current_gallons,
    CASE
        WHEN SUM(il.volume_gallons) OVER (
            PARTITION BY b.beer_id 
            ORDER BY il.date
        ) <= b.brew_threshold THEN 'BREW NOW'
        WHEN SUM(il.volume_gallons) OVER (
            PARTITION BY b.beer_id 
            ORDER BY il.date
        ) <= b.brew_threshold * 1.25 THEN 'BREW SOON'
        ELSE 'OK'
    END AS brew_status
FROM InventoryLog il
JOIN beers b ON b.beer_id = il.beer_id
ORDER BY b.beer_name, il.date;


