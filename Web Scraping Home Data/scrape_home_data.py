import asyncio
import json
import math
import time
from datetime import datetime
from typing import List, Optional

import httpx
from parsel import Selector
from typing_extensions import TypedDict

city = "Bakersfield"
state = "CA"
bed = 3
bath = 2
home_type = "condo"

# establish a persistent HTTPX session
# with browser-like headers to avoid instant blocking
BASE_HEADERS = {
    "user-agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/96.0.4664.110 Safari/537.36",
    "accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8",
    "accept-language": "en-US;en;q=0.9",
    "accept-encoding": "gzip, deflate, br",
}
session = httpx.AsyncClient(headers=BASE_HEADERS, follow_redirects=True)

# Type hints for search results
class PropertyPreviewResult(TypedDict):
    property_id: str
    listing_id: str
    permalink: str
    list_price: int
    price_reduces_amount: Optional[int]
    description: dict
    location: dict
    photos: List[dict]
    list_date: str
    last_update_date: str
    tags: List[str]

# Type hint for search results of a single page
class SearchResults(TypedDict):
    count: int  # results on this page
    total: int  # total results for all pages
    results: List[PropertyPreviewResult]

def parse_search(response: httpx.Response) -> SearchResults:
    """Parse Realtor.com search for hidden search result data"""
    selector = Selector(text=response.text)
    data = selector.css("script#__NEXT_DATA__::text").get()
    if not data:
        print(f"page {response.url} is not a property listing page")
        return
    data = json.loads(data)
    return data["props"]["pageProps"]["searchResults"]["home_search"]

# scrapes first page and num of pages in query. Then scrapes remaining pages
# concurrently as a list of URLs
async def find_properties(state: str, city: str, bed: int, bath: int, home_type: str):
    """Scrape Realtor.com search for property preview data"""
    print(f"scraping first result page for {bed}br {bath}ba {type} in {city}, {state}")
    first_page = f"https://www.realtor.com/realestateandhomes-search/{city}_{state.upper()}/beds-{bed}/baths-{bath}/type-{home_type}/pg-1"
    first_result = await session.get(first_page)
    first_data = parse_search(first_result)
    results = first_data["results"]

    total_pages = math.ceil(first_data["total"] / first_data["count"])
    print(f"found {total_pages} total pages ({first_data['total']} total properties)")
    to_scrape = []
    for page in range(1, total_pages + 1):
        assert "pg-1" in str(first_result.url)  # prevents scraping duplicate pages
        page_url = str(first_result.url).replace("pg-1", f"pg-{page}")
        to_scrape.append(session.get(page_url))
    for response in asyncio.as_completed(to_scrape):
        parsed = parse_search(await response)
        results.extend(parsed["results"])
    print(f"scraped search of {len(results)} results for {city}, {state}")
    return results


async def run():
    results_search = await find_properties(state, city, bed, bath, home_type)
    current_datetime = datetime.today().strftime("%Y-%m-%d")
    filepath = "data/"
    filename = filepath+str(current_datetime)+"_homedata.json"
    #print(json.dumps(results_search, indent=2))
    with open(filename, 'w', encoding='utf-8') as f:
        json.dump(results_search, f, ensure_ascii=False, indent=4)


if __name__ == "__main__":
    asyncio.run(run())