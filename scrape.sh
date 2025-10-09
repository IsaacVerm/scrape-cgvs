#!/bin/bash

# setup
OUTPUT_FILE="test.csv"
MONTHS=("januari" "februari" "maart" "april" "mei" "juni" "juli" "augustus" "september" "oktober" "november" "december")

# define CSV header fields
CSV_HEADER_FIELDS=(
    "month"
    "year"
    "count_applicants_international_protection"
    "top_10_nationalities_applicants_international_protection"
    "count_cgvs_decisions"
)

# define regex patterns for extracting values from page
# the patterns are in the same order as the CSV_HEADER_FIELDS (excluding month and year which are not extracted)
declare -A FIELD_REGEX_PATTERNS
FIELD_REGEX_PATTERNS[count_applicants_international_protection]='.*registreerde de DVZ.<strong>([0-9]*(\.[0-9]*)?).*/\1/p'
FIELD_REGEX_PATTERNS[top_10_nationalities_applicants_international_protection]='<li>([A-Z].*)staan in .* bovenaan de top 10.*\. (.*)vervolledigen de top 10.*/"\1,\2"/p'
FIELD_REGEX_PATTERNS[count_cgvs_decisions]='.*In .* nam het CGVS <strong>([0-9]*(\.[0-9]*)?) <\/strong>beslissingen.*/\1/p'

# create empty CSV file with just a header if file doesn't exist
if [ ! -f "$OUTPUT_FILE" ]; then
    IFS=','
    echo "${CSV_HEADER_FIELDS[*]}" > "$OUTPUT_FILE"
    unset IFS
fi

# fetch page each month, extract required values and output the result to CSV
for YEAR in {2020..2025}; do
    for MONTH_INDEX in {0..11}; do
        # wait for 2 seconds (asked for by CGVS at https://www.cgvs.be/robots.txt)
        sleep 2

        # select month name in Dutch
        MONTH="${MONTHS[$MONTH_INDEX]}"
        
        # define the last month you want data for
        # for example if you launch the script in October 2025, you can't ask data for November 2025 yet
        # the MONTH_INDEX to provide is one less than what you'd expect so 8 for September for example
        if [ "$YEAR" -eq 2025 ] && [ "$MONTH_INDEX" -gt 8 ]; then
            break
        fi
        
        # create dynamic URL
        URL="https://www.cgvs.be/nl/actueel/asielstatistieken-${MONTH}-${YEAR}"
        
        # fetch page
        HTML_CONTENT=$(curl -s "$URL")

        # extract values from page using configured regex patterns
        declare -A EXTRACTED_VALUES
        EXTRACTED_VALUES[month]="$MONTH"
        EXTRACTED_VALUES[year]="$YEAR"
        for field_name in "${!FIELD_REGEX_PATTERNS[@]}"; do
            EXTRACTED_VALUES[$field_name]=$(echo "$HTML_CONTENT" | sed -En "s/${FIELD_REGEX_PATTERNS[$field_name]}")
        done
                
        # save extracted values to CSV
        # dynamically build the CSV row from the field names
        CSV_ROW=""
        for field in "${CSV_HEADER_FIELDS[@]}"; do
            if [ -n "$CSV_ROW" ]; then
                CSV_ROW="${CSV_ROW},"
            fi
            CSV_ROW="${CSV_ROW}${EXTRACTED_VALUES[$field]}"
        done
        echo "$CSV_ROW" >> "$OUTPUT_FILE"
    done
done