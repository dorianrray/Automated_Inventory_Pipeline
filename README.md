PROBLEM TO SOLVE: 
Brewery owner approximates when to brew beer based on existing inventory; this means that re-ups of staple beers are sometimes mistimed, leaving taps unused and grumpy customers who can't drink their favorite beer. This also leads to downtimes between replacement beers for those that will never be made again; meaning less variety for the customer. Owner also sells entire kegs outside of the POS system, meaning that the POS system can't track all volume anyway.

SOLUTION:
Using the native POS system used to track sales, a backend datasheet can be obtained that gives pricing per beer per size (including promotions and happy hours). This gives SQL an opportunity to clean the data, categorize, and reference different tables to create a running inventory. 

METHOD:
New database and architecture script is created in SQL -> 
another script cleans and loads the data as necessary.

Xcel sheet is recognized by a Streamlit python app -> 
python drops unnecessary columns and adds data to the existing database -> 
python runs the "cleaning/loading" script to populate all tables ->
SQL views are pulled from the database into Metabase to visualize data.

Streamlit form takes Xcel sheet, but also has a live form that allows new beers to be added and inventory for existing or new beers to be updated. 

ANALYTICS:
Pleasant auxiliary benefits include a range of analytics. From volume of beer consumed to types of beer over time, analytics can help inform the owner what beers are popular, which ones to double down on, and how time/season affect consumption of certain types, to say the least. Some screenshots are attached to demonstrate.
