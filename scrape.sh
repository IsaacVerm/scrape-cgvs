#!/bin/bash

# Configuration
OUTPUT_FILE="cgvs-figures.csv"

# Dutch month names
MONTHS=("januari" "februari" "maart" "april" "mei" "juni" "juli" "augustus" "september" "oktober" "november" "december")

echo "Starting CGVS scraper."

# Create CSV header if file doesn't exist
if [ ! -f "$OUTPUT_FILE" ]; then
    echo "month,year,asylum_seekers" > "$OUTPUT_FILE"
    echo "Created new CSV file with headers"
fi

# Counter for successful scrapes
SUCCESS_COUNT=0
FAIL_COUNT=0

# Loop through years from 2020 to 2025
for YEAR in {2020..2025}; do
    # Loop through all months
    for MONTH_INDEX in {0..11}; do
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
        
        # Step 2: Extract the number of asylum seekers
        ASYLUM_COUNT=$(echo "$HTML_CONTENT" | sed -n "s/.*In $MONTH $YEAR registreerde de DVZ <strong>\([0-9.]*\)<\/strong> verzoekers.*/\1/p")
        
        # Check if we successfully extracted a number
        if [ -z "$ASYLUM_COUNT" ]; then
            echo "Warning: Could not extract asylum seeker count from HTML for ${MONTH} ${YEAR}"
            FAIL_COUNT=$((FAIL_COUNT + 1))
            continue
        fi
        
        echo "Extracted asylum seeker count: $ASYLUM_COUNT"
        
        # Step 3: Save to CSV
        echo "${MONTH},${YEAR},${ASYLUM_COUNT}" >> "$OUTPUT_FILE"
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