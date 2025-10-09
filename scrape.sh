#!/bin/bash

# Configuration
OUTPUT_FILE="test.csv"

# Dutch month names
MONTHS=("januari" "februari" "maart" "april" "mei" "juni" "juli" "augustus" "september" "oktober" "november" "december")

echo "Starting CGVS scraper."

# Create CSV header if file doesn't exist
if [ ! -f "$OUTPUT_FILE" ]; then
    echo "month,year,count_applicants_international_protection,top_10_nationalities_applicants_international_protection,count_cgvs_decisions" > "$OUTPUT_FILE"
    echo "Created new CSV file with headers"
fi

# Counter for successful scrapes
SUCCESS_COUNT=0
FAIL_COUNT=0

# Loop through years from 2020 to 2025
for YEAR in {2020..2025}; do
    # Loop through all months
    for MONTH_INDEX in {0..11}; do
        # wait for 2 seconds (robots.txt CGVS asks for 2 seconds but 5 to be on the safe site)
        sleep 2

        MONTH="${MONTHS[$MONTH_INDEX]}"
        
        # Stop at September 2025 (month index 8)
        if [ "$YEAR" -eq 2025 ] && [ "$MONTH_INDEX" -gt 8 ]; then
            break
        fi
        
        URL="https://www.cgvs.be/nl/actueel/asielstatistieken-${MONTH}-${YEAR}"
        
        echo ""
        echo "Processing ${MONTH} ${YEAR}..."
        echo "Fetching HTML page from: ${URL}"
        
        # Step 1: Fetch HTML page
        HTML_CONTENT=$(curl -s "$URL")
        
        # Check if curl was successful and we got content
        if [ -z "$HTML_CONTENT" ]; then
            echo "Warning: Failed to fetch content from $URL"
            FAIL_COUNT=$((FAIL_COUNT + 1))
            continue
        fi

        # Step 2: extract values needed from HTML
        COUNT_APPLICANTS_INTERNATIONAL_PROTECTION=$(echo "$HTML_CONTENT" | sed -En 's/.*registreerde de DVZ.<strong>([0-9]*(\.[0-9]*)?).*/\1/p')
        TOP_10_NATIONALITIES_APPLICANTS_INTERNATIONAL_PROTECTION=$(echo "$HTML_CONTENT" | sed -En 's/<li>([A-Z].*)staan in .* bovenaan de top 10.*\. (.*)vervolledigen de top 10.*/"\1,\2"/p')
        COUNT_CGVS_DECISIONS=$(echo "$HTML_CONTENT" | sed -En 's/.*In .* nam het CGVS <strong>([0-9]*(\.[0-9]*)?) <\/strong>beslissingen.*/\1/p')
        
        # Check if we successfully extracted a number
        if [ -z "$COUNT_APPLICANTS_INTERNATIONAL_PROTECTION" ]; then
            echo "Warning: Could not extract count applicants international protection from HTML for ${MONTH} ${YEAR}"
            FAIL_COUNT=$((FAIL_COUNT + 1))
            continue
        fi
        
        echo "Extracted count applicants international protection: $COUNT_APPLICANTS_INTERNATIONAL_PROTECTION"
        
        # Step 3: Save to CSV
        echo "${MONTH},${YEAR},${COUNT_APPLICANTS_INTERNATIONAL_PROTECTION},${TOP_10_NATIONALITIES_APPLICANTS_INTERNATIONAL_PROTECTION},${COUNT_CGVS_DECISIONS}" >> "$OUTPUT_FILE"
        echo "Data saved to $OUTPUT_FILE"
        SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
    done
done

echo ""
echo "============================================"
echo "CGVS scraper completed!"
echo "Successfully scraped: $SUCCESS_COUNT records"
echo "Failed to scrape: $FAIL_COUNT records"
echo "Results saved to $OUTPUT_FILE"
echo "============================================"