# Scrape CGVS

## Context

[The CVGS site contains a summary of asylum figures](https://www.cgvs.be/nl/cijfers).

The CGVS figures cover data from 2010 up till now.
From 2010 up till 2015 the data were published on a yearly basis.
For example this is the data for [2010](https://www.cgvs.be/nl/actueel/overzicht-asielstatistieken-2010).
From 2015 on the data have been published on a monthly basis.
Take for example the data for [August 2016](https://www.cgvs.be/nl/actueel/asielstatistieken-augustus-2016).

Over time the layout of the summary page changed a couple of times.
The time period we're interested in, 2020 and later, always kept the same layout so that's the layout we'll focus on.

## Scraping approach

I chose a bare minimum approach to scrape the data.
This works because the site itself is not JavaScript heavy.
You can just fetch the page you need and don't need a browser to run JavaScript to fetch the data. The data is already baked-in server-side.

This allows us to avoid any parsing with [beautifulsoup](https://pypi.org/project/beautifulsoup4/) or running a browser like with [Playwright](https://playwright.dev/).

The current approach consists of these steps:

- fetch HTML page with a simple HTTP GET request (using [curl](https://curl.se/))
- extract the values we need from the HTML page (using [sed](https://www.gnu.org/software/sed/))
- save extracted values to CSV file
- commit the CSV file and push to the repo
- fetch the data straight from GitHub to Power BI Desktop (using the Power BI web connector)

The documentation for curl and sed can be a bit dense so [this tutorial for curl](https://www.digitalocean.com/community/tutorials/workflow-downloading-files-curl) and [this one for sed](https://www.digitalocean.com/community/tutorials/linux-sed-command) should help you out a lot already.

## How to run the script

The steps detailed above are executed in the `scrape.sh` file.
`scrape.sh` can be run in two different ways:

- you can run it yourself by running `./scrape.sh` at root in the terminal
- you can use the `.github/workflows/scrape.yml` GitHub Actions workflow so the script automatically runs on a regular basis

The `scrape.yml` GitHub Actions workflow allows us to run this script on a regular basis in a container automatically provisioned by GitHub for free (no need to setup any infrastructure yourself). 

## How does `scrape.sh` work?

The `scrape.sh` script is quite long but the `sed` part is the true heart of the script.
Take for example how we extract `count_applicants_international_protection`:

```
COUNT_APPLICANTS_INTERNATIONAL_PROTECTION=$(echo "$HTML_CONTENT" | sed -En 's/.*registreerde de DVZ.<strong>([0-9]*(\.[0-9]*)?).*/\1/p')
```

### `-E`: [extended regular expressions](https://www.gnu.org/software/sed/manual/html_node/Extended-regexps.html)

> The only difference between basic and extended regular expressions is in the behavior of a few characters: ‘?’, ‘+’, parentheses, and braces (‘{}’). While basic regular expressions require these to be escaped if you want them to behave as special characters, when using extended regular expressions you must escape them if you want them to match a literal character.

Using extended regular expressions allows us to just write `(` or `)` instead of `\(` or `\/`.
In itself this is nothing shocking, but lots of escaped parentheses one after another is simply unreadable.

### literal text part

The text part, "registreerde de DVZ..." in this case, isn't strictly necessary but I've added it to make clear what phrase we're aiming for. If not the regular expression becomes very generic and hard to debug.

### capturing group

The capturing group `([0-9]*(\.[0-9]*)?)` matches both numbers with and without a dot.
In this case for example both 300 and 3.000 will be matched.
This is required because for example sometimes the count of applicants drops to less than 1000 a month.

### substitution

`\1` is a reference to the captured group.
Together with the `-n` argument and the `p` option at the end we replace the entire matched line of HTML with the extracted value.

## CGVS scraping limitations

The [CGVS robots.txt file](https://www.cgvs.be/robots.txt) asks to respect a [crawl delay between requests](https://developers.google.com/search/docs/crawling-indexing/robots/robots_txt) of 2 seconds.