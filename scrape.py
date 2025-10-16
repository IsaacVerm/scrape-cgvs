#!/usr/bin/env python3
import os
import time
import re
import requests
import pandas as pd

OUTPUT_FILE = "test_py.csv"
MONTHS = [
    "januari", "februari", "maart", "april", "mei", "juni",
    "juli", "augustus", "september", "oktober", "november"
]  # no december because the december report summarises the entire year

# create empty CSV file with just a header if file doesn't exist
if not os.path.isfile(OUTPUT_FILE):
    header = [
        "month",
        "year",
        "count_applicants_international_protection",
        "top_10_nationalities_applicants_international_protection",
        "count_cgvs_decisions",
        "workload",
    ]
    pd.DataFrame(columns=header).to_csv(OUTPUT_FILE, index=False, encoding="utf-8")

# fetch page each month, extract required values and output the result to CSV
for YEAR in range(2020, 2026):
    for MONTH_INDEX in range(0, 11):
        # wait for 3 seconds (CGVS asks for 2 seconds at https://www.cgvs.be/robots.txt)
        time.sleep(5)

        # select month name in Dutch
        MONTH = MONTHS[MONTH_INDEX]

        # define the last month you want data for
        # for example if you launch the script in October 2025, you can't ask data for November 2025 yet
        # the MONTH_INDEX to provide is one less than what you'd expect so 8 for September for example
        if YEAR == 2025 and MONTH_INDEX > 8:
            break

        # create dynamic URL
        URL = f"https://www.cgvs.be/nl/actueel/asielstatistieken-{MONTH}-{YEAR}"

        # fetch page
        try:
            resp = requests.get(URL, timeout=15)
            HTML_CONTENT = resp.text
        except Exception:
            HTML_CONTENT = ""

        # extract values from page
        COUNT_APPLICANTS_INTERNATIONAL_PROTECTION = ""
        m = re.search(r'.*registreerde de DVZ.<strong>([0-9]*(\.[0-9]*)?).*', HTML_CONTENT)
        if m:
            COUNT_APPLICANTS_INTERNATIONAL_PROTECTION = m.group(1)

        TOP_10_NATIONALITIES_APPLICANTS_INTERNATIONAL_PROTECTION = ""
        m = re.search(r'<li>([A-Z].*)staan in .* bovenaan de top 10.*\. (.*)vervolledigen de top 10.*', HTML_CONTENT)
        if m:
            TOP_10_NATIONALITIES_APPLICANTS_INTERNATIONAL_PROTECTION = f'"{m.group(1)},{m.group(2)}"'

        COUNT_CGVS_DECISIONS = ""
        m = re.search(r'.*<strong>([0-9]*(\.[0-9]*)?)( )?<\/strong>( )?beslissingen.*', HTML_CONTENT)
        if m:
            COUNT_CGVS_DECISIONS = m.group(1)

        WORKLOAD = ""
        m = re.search(r'.*bedroeg de totale werklast <strong>([0-9]*(\.[0-9]*)?).*', HTML_CONTENT)
        if m:
            WORKLOAD = m.group(1)

        # save extracted values to CSV
        row = {
            "month": MONTH,
            "year": YEAR,
            "count_applicants_international_protection": COUNT_APPLICANTS_INTERNATIONAL_PROTECTION,
            "top_10_nationalities_applicants_international_protection": TOP_10_NATIONALITIES_APPLICANTS_INTERNATIONAL_PROTECTION,
            "count_cgvs_decisions": COUNT_CGVS_DECISIONS,
            "workload": WORKLOAD,
        }
        pd.DataFrame([row]).to_csv(OUTPUT_FILE, mode="a", header=False, index=False, encoding="utf-8")
