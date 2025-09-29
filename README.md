# Scrape CGVS

## Context

[CVGS site contains summary of asylum figures](https://www.cgvs.be/nl/cijfers).
The data is published by month.
For example the July 2025 data can be bound [here](https://www.cgvs.be/nl/actueel/asielstatistieken-juli-2025), the August data [here](https://www.cgvs.be/nl/actueel/asielstatistieken-augustus-2025),...

## Expected output

We want to extract the raw values and save them by month.

Fields: month, year, count_assignments, count_people_impacted_by_assignments,...

## CGVS figures

The CGVS figures cover data from 2010 up till now.
From 2010 up till 2015 the data were published on a yearly basis.
The url to fetch this data is `https://www.cgvs.be/nl/actueel/overzicht-asielstatistieken-{year}` (for example `https://www.cgvs.be/nl/actueel/overzicht-asielstatistieken-2010`).

From 2015 on the data are published on a monthly basis.
The url to fetch the data is `https://www.cgvs.be/nl/actueel/asielstatistieken-{month}-{year}` (for example `https://www.cgvs.be/nl/actueel/asielstatistieken-augustus-2016`).

Over time the layout of the summary page changed a couple of times.
The time period we're interested in, 2020 and later, always kept the same layout so that's the layout we'll focus on.

## Steps

The end goal is to go over all the monthly HTML pages of figures between January 2020 and September 2025 and extract a whole list of variables we're interested in.
For this first iteration we'll limit ourselves:

- only request the January 2020 page
- only extract the number of requests field

Steps:

- fetch HTML page
- extract value
- save values to CSV
- push and commit
- using the data

All of these steps are done in a GitHub Actions Workflow running on a monthly basis.

### Fetch HTML page

- create an array with the months from January to December in Dutch.
- create an array with the years from 2020 till 2025.
- create an array containing all the combinations of years and months
- `curl https://www.cgvs.be/nl/actueel/asielstatistieken-{month}-{year}.html`

### Extract values

`sed` to extract the number of requesters.

One line in the HTML page says "In augustus 2025 registreerde de DVZ 2.895 verzoekers om internationale bescherming.".
I want to extract the number (in this case 2.895) from this line.

### Save values in CSV

Redirection to `cgvs-figures.csv`.

### Push and commit

Push and commit data to `main` branch of GitHub repo.

### Using the data

Out of scope for now: use the Power BI web connector to fetch the data straight from GitHub.

## Rationale

### Why use `curl` + `sed` over `beautifulsoup` or `Playwright`?

The CVGS site doesn't dpeend on JavaScript.
When you ask for the HTML, the data is already baked into the HTML.
There's no need for additional browser API requests.
Just `curl` is enough to get the complete `HTML`.

Since the HTML is relatively simple, there's no need for complicated parsing.
Just some basic regular expressions are enough to extract the data we need.
`sed` is the best tool for this with [its simple pattern/replacement pattern](https://www.grymoire.com/Unix/Sed.html#uh-1).

### Why use `GitHub Coactions`?

- free
- can be run on a regular basis using `cron`
- no need to setup infrastructure
- public data so no GitHub privacy concerns