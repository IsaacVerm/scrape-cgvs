#!/bin/bash

# setup
OUTPUT_FILE="test.csv"
MONTHS=("januari" "februari" "maart" "april" "mei" "juni" "juli" "augustus" "september" "oktober" "november") # no december because the december report summarises the entire year

# create empty CSV file with just a header if file doesn't exist
if [ ! -f "$OUTPUT_FILE" ]; then
    echo "month,year,count_applicants_international_protection,top_10_nationalities_applicants_international_protection,count_cgvs_decisions" > "$OUTPUT_FILE"
fi

# fetch page each month, extract required values and output the result to CSV
for YEAR in {2020..2025}; do
    for MONTH_INDEX in {0..10}; do
        # wait for 3 seconds (CGVS asks for 2 seconds at https://www.cgvs.be/robots.txt)
        sleep 5

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

        # extract values from page
        COUNT_APPLICANTS_INTERNATIONAL_PROTECTION=$(echo "$HTML_CONTENT" | sed -En 's/.*registreerde de DVZ.<strong>([0-9]*(\.[0-9]*)?).*/\1/p')
        TOP_10_NATIONALITIES_APPLICANTS_INTERNATIONAL_PROTECTION=$(echo "$HTML_CONTENT" | sed -En 's/<li>([A-Z].*)staan in .* bovenaan de top 10.*\. (.*)vervolledigen de top 10.*/"\1,\2"/p')
        COUNT_CGVS_DECISIONS=$(echo "$HTML_CONTENT" | sed -En 's/.*<strong>([0-9]*(\.[0-9]*)?)( )?<\/strong>( )?beslissingen.*/\1/p')
                
        # save extracted values to CSV
        # make sure you output as many values as columns put in the header of the empty CSV above
        echo "${MONTH},${YEAR},${COUNT_APPLICANTS_INTERNATIONAL_PROTECTION},${TOP_10_NATIONALITIES_APPLICANTS_INTERNATIONAL_PROTECTION},${COUNT_CGVS_DECISIONS}" >> "$OUTPUT_FILE"
    done
done