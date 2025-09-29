#!/bin/bash

# Configuration
MONTH="januari"
YEAR="2020"
OUTPUT_FILE="cgvs-figures.csv"
URL="https://www.cgvs.be/nl/actueel/asielstatistieken-${MONTH}-${YEAR}"

echo "Starting CGVS scraper for ${MONTH} ${YEAR}..."

# Step 1: Fetch HTML page
echo "Fetching HTML page from: ${URL}"
HTML_CONTENT=$(curl -s "$URL")

# Check if curl was successful and we got content
if [ -z "$HTML_CONTENT" ]; then
    echo "Error: Failed to fetch content from $URL"
    exit 1
fi

echo "Successfully fetched HTML content"

# Step 2: Extract the number of asylum seekers
echo "Extracting asylum seeker count..."

ASYLUM_COUNT=$(echo "$HTML_CONTENT" | sed -n "s/<li>In $MONTH registreerde de DVZ <strong>\([0-9]\{1,3\}\.[0-9]\{1,3\}\) <\/strong>verzoekers om internationale bescherming. Elke persoon (ook kinderen) wordt apart geteld.<\/li>/\1/p")

# Check if we successfully extracted a number
if [ -z "$ASYLUM_COUNT" ]; then
    echo "Error: Could not extract asylum seeker count from HTML"
    exit 1
fi

echo "Extracted asylum seeker count: $ASYLUM_COUNT"

# Step 3: Save to CSV
echo "Saving data to $OUTPUT_FILE..."

# Create CSV header if file doesn't exist
if [ ! -f "$OUTPUT_FILE" ]; then
    echo "month,year,asylum_seekers" > "$OUTPUT_FILE"
    echo "Created new CSV file with headers"
fi

# Append the new data
echo "${MONTH},${YEAR},${ASYLUM_COUNT}" >> "$OUTPUT_FILE"
echo "Data saved to $OUTPUT_FILE"

# Step 4: Commit and push changes
echo "Committing and pushing changes to git..."

# Configure git if needed (for GitHub Actions)
git config --global user.email "action@github.com"
git config --global user.name "GitHub Action"

# Add the CSV file to git
git add "$OUTPUT_FILE"

# Check if there are changes to commit
if git diff --staged --quiet; then
    echo "No changes to commit"
else
    # Commit the changes?
    git commit -m "Add asylum statistics for ${MONTH} ${YEAR}"
    
    # Push to main branch
    git push origin main
    echo "Changes committed and pushed successfully"
fi

echo "CGVS scraper completed successfully!"
echo "Results: ${MONTH} ${YEAR} - ${ASYLUM_COUNT} asylum seekers"