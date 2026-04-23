import streamlit as st
import pandas as pd
import sqlite3
import os

# paths
DB_PATH = r"PATH_TO_DB"
SQL_PATH = r"PATH_TO_CLEANING_SCRIPT"

def run_pipeline(uploaded_file):
    df = pd.read_csv(uploaded_file, usecols=["DATE", "ITEM ID", "SIZE", "QTY SOLD (STD)", "PRICE", "AMOUNT TOTAL"])
    conn = sqlite3.connect(DB_PATH)
    df.to_sql('Bam', conn, if_exists='append', index=False)

    with open(SQL_PATH, 'r') as f:
        sql = f.read()

    cursor = conn.cursor()
    for statement in sql.split(';'):
        statement = statement.strip()
        if statement:
            try:
                cursor.execute(statement)
            except Exception as e:
                print(f"FAILED: {e}")
                print(f"STATEMENT: {statement[:100]}")

    conn.commit()
    conn.close()
    return len(df)

def get_beers():
    conn = sqlite3.connect(DB_PATH)
    beers = pd.read_sql("SELECT beer_name FROM beers ORDER BY beer_name", conn)
    conn.close()
    return beers['beer_name'].tolist()

# --- UI ---
st.title("Inventory Manager")

# --- SECTION 1: PIPELINE ---
st.header("Load New Sales Data")
uploaded_file = st.file_uploader("Upload Excel or CSV file", type=["csv", "xlsx"])
if uploaded_file:
    if st.button("Run Pipeline"):
        with st.spinner("Loading data..."):
            rows = run_pipeline(uploaded_file)
        st.success(f"Done — {rows} rows added")

st.divider()

# --- SECTION 2: REPLENISHMENT ---
st.header("New Batch Re-up")
beers = get_beers()
beer = st.selectbox("Select Beer", beers)
date = st.date_input("Date")
gallons = st.number_input("Gallons brewed", min_value=0.0, step=0.5)
notes = st.text_input("Notes (optional)", value="new batch")
if st.button("Submit Re-up"):
    conn = sqlite3.connect(DB_PATH)
    conn.execute("""
        INSERT INTO InventoryLog (beer_id, date, event_type, volume_gallons, notes)
        VALUES (
            (SELECT beer_id FROM beers WHERE beer_name = ?),
            ?, 'replenishment', ?, ?
        )
    """, (beer, str(date), gallons, notes))
    conn.commit()
    conn.close()
    st.success(f"Logged {gallons} gallons of {beer} on {date}")

st.divider()

# --- SECTION 3: ADD NEW BEER ---
st.header("Add New Beer")
new_beer = st.text_input("Beer Name")
lead_time = st.number_input("Lead Time (days)", min_value=0, step=1)
threshold = st.number_input("Brew Threshold (gallons)", min_value=0.0, step=0.5)
if st.button("Add Beer"):
    conn = sqlite3.connect(DB_PATH)
    conn.execute("""
        INSERT OR IGNORE INTO beers (beer_name, lead_time_days, brew_threshold)
        VALUES (?, ?, ?)
    """, (new_beer, lead_time, threshold))
    conn.commit()
    conn.close()
    st.success(f"{new_beer} added successfully")