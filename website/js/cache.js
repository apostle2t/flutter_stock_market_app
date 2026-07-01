const FMP_KEY = "FsHNv0BXdqm82QHTLBOIt6wEAMuPdnv4";

const CACHE_TTL_MS = 60 * 1000; // 60 seconds


/**
 * Generic cached fetch helper. Checks localStorage first; if a fresh
 * entry exists (younger than CACHE_TTL_MS) it's returned without
 * touching the network. Otherwise fetches, caches, and returns the result.
 */
async function cachedFetch(cacheKey, url) {

    try {

        const cached = localStorage.getItem(cacheKey);

        if (cached) {

            const parsed = JSON.parse(cached);

            if (Date.now() - parsed.timestamp < CACHE_TTL_MS) {
                return parsed.data;
            }

        }

    } catch (error) {
        // Corrupted cache entry — ignore and fetch fresh.
    }

    try {

        const response = await fetch(url);

        if (!response.ok) {
            console.error(`Request failed (${response.status}): ${url}`);
            return [];
        }

        const text = await response.text();

        let data;

        try {
            data = JSON.parse(text);
        } catch (parseError) {
            console.error(`Non-JSON response from: ${url}`, text.slice(0, 200));
            return [];
        }

        localStorage.setItem(
            cacheKey,
            JSON.stringify({ timestamp: Date.now(), data: data })
        );

        return data;

    } catch (error) {

        console.error(error);
        return [];

    }

}


/**
 * Fetches live quotes for one or more symbols. Each symbol is
 * requested individually (rather than batched in one comma-separated
 * call), since FMP's free tier returns 402 Payment Required for
 * multi-symbol requests on /stable/quote. Each individual request is
 * cached for 60 seconds, so repeated calls for the same symbol within
 * that window cost nothing.
 * Returns a plain array of quote objects, same shape as before.
 */
async function fetchQuoteCached(symbolsCsv) {

    const symbols = symbolsCsv.split(",");

    const results = await Promise.all(
        symbols.map(symbol =>
            cachedFetch(
                "fmpQuote:" + symbol,
                `https://financialmodelingprep.com/stable/quote?symbol=${symbol}&apikey=${FMP_KEY}`
            )
        )
    );

    // Each individual call returns a 1-item array; flatten them together.
    return results.flat();

}


/**
 * Fetches full daily historical data for a single symbol (years of
 * data in one call). Callers slice the returned array client-side
 * for different time ranges (1D/1M/3M/1Y) rather than making a
 * separate request per range.
 * Returns a plain array, newest date first: { date, open, high, low, close, ... }
 */
async function fetchHistoryCached(symbol) {

    return await cachedFetch(
        "fmpHistory:" + symbol,
        `https://financialmodelingprep.com/stable/historical-price-eod/full?symbol=${symbol}&apikey=${FMP_KEY}`
    );

}


/**
 * Slices a full historical array down to a given time range.
 * Data is newest-first, so we slice from the start and then
 * reverse for chronological (oldest-to-newest) chart display.
 */
function sliceHistoryRange(history, range) {

    // FMP's free tier provides end-of-day data only (no intraday), so
    // a literal single-day "1D" would be just one point — not a usable
    // line. "1D" therefore shows the most recent ~8 closes so it still
    // renders as a real recent-trend line; the longer ranges scale up
    // from there.
    const counts = {
        "1D": 5,
        "1W": 10,
        "1M": 22,
        "3M": 65,
        "1Y": 252
    };

    const count = counts[range] || 22;

    return history.slice(0, count).reverse();

}


/**
 * Starts a client-side price simulation loop. Calls `onTick` every
 * `intervalMs` with a small, bounded random percentage nudge (no
 * network requests involved). The real fetched price/trend stays
 * the source of truth for color/direction — this only simulates the
 * minor tick-by-tick price flicker real trading UIs show between
 * actual data refreshes. Pauses while the tab isn't visible.
 */
/**
 * Starts a client-side price simulation loop. Calls `onTick` every
 * `intervalMs` with a `randomDrift()` function (no network requests
 * involved). Each call to `randomDrift()` returns a fresh, independent
 * random percentage in roughly -0.15% to +0.15% — callers should call
 * it once per stock/symbol, so each one drifts independently rather
 * than every stock moving by the same amount in the same direction.
 * The real fetched price/trend stays the source of truth for
 * color/direction — this only simulates the minor tick-by-tick price
 * flicker real trading UIs show between actual data refreshes.
 * Pauses while the tab isn't visible.
 */
function startPriceSimulation(onTick, intervalMs) {

    function randomDrift() {
        return (Math.random() - 0.5) * 0.3;
    }

    const intervalId = setInterval(() => {

        if (document.hidden) return;

        onTick(randomDrift);

    }, intervalMs);

    return intervalId;

}


// Maps stock symbols to their Simple Icons slug (https://simpleicons.org),
// an open-source SVG icon set for popular brands. Not every public
// company has a clean match in this library — symbols without a
// mapping here fall back to a plain letter badge instead.
const STOCK_ICON_SLUGS = {
    AAPL: "apple",
    TSLA: "tesla",
    NVDA: "nvidia",
    MSFT: "microsoft",
    AMZN: "amazon",
    GOOGL: "google",
    META: "meta",
    WMT: "walmart",
    BABA: "alibabadotcom",
    DIS: "disney"
};


/**
 * Returns an HTML snippet for a stock's icon: a real brand icon from
 * Simple Icons CDN if one is mapped for this symbol, with an inline
 * onerror fallback that swaps to a plain letter badge if the icon
 * fails to load (e.g. network issue, or no icon exists for that slug).
 * `sizePx` controls the rendered tile size.
 */
function stockIconHtml(symbol, sizePx = 36) {

    const slug = STOCK_ICON_SLUGS[symbol];
    const initials = symbol.slice(0, 2);

    if (!slug) {

        return `
            <div class="stock-icon-badge" style="width:${sizePx}px;height:${sizePx}px;">
                ${initials}
            </div>
        `;

    }

    return `
        <div class="stock-icon-tile" style="width:${sizePx}px;height:${sizePx}px;">

            <img
                src="https://cdn.simpleicons.org/${slug}/ffffff"
                alt="${symbol}"
                style="width:${Math.round(sizePx * 0.55)}px;height:${Math.round(sizePx * 0.55)}px;"
                onerror="this.parentElement.outerHTML = '&lt;div class=&quot;stock-icon-badge&quot; style=&quot;width:${sizePx}px;height:${sizePx}px;&quot;&gt;${initials}&lt;/div&gt;'"
            >

        </div>
    `;

}


// Shared store of rendered sparkline Chart.js instances, keyed by
// symbol, so simulation ticks (in stock.js or app.js) can update an
// existing chart's last point in place rather than recreating it.
const sparklineCharts = {};


/**
 * Draws a small inline sparkline chart into a canvas with id
 * "sparkline-{symbol}", using the last month of real historical
 * closes. `isPositive` should reflect the same daily % change shown
 * in the price card next to this sparkline, so the line color always
 * agrees with the displayed number rather than reflecting a separately
 * computed (and potentially disagreeing) longer-term trend.
 * Shared between the Popular Stocks grid (stock.js) and the Dashboard
 * cards (app.js).
 */
async function drawSparkline(symbol, isPositive) {

    const canvas = document.getElementById(`sparkline-${symbol}`);

    if (!canvas) return;

    try {

        const history = await fetchHistoryCached(symbol);
        const recent = sliceHistoryRange(history, "1M");
        const prices = recent.map(point => point.close);

        const chart = new Chart(canvas, {

            type: "line",

            data: {
                labels: prices.map((_, i) => i),
                datasets: [{
                    data: prices,
                    borderColor: isPositive ? "#21D07A" : "#FF4D4D",
                    backgroundColor: "transparent",
                    borderWidth: 1.5,
                    pointRadius: 0,
                    tension: 0.3
                }]
            },

            options: {
                responsive: true,
                maintainAspectRatio: false,
                plugins: { legend: { display: false } },
                scales: {
                    x: { display: false },
                    y: { display: false }
                },
                elements: { line: { borderJoinStyle: "round" } }
            }

        });

        sparklineCharts[symbol] = { chart, basePrices: prices };

    } catch (error) {

        console.error(`Sparkline failed for ${symbol}`, error);

    }

}


/**
 * Pushes a new point onto a symbol's sparkline and drops the oldest,
 * so the line visibly scrolls left over time instead of only nudging
 * its final point (which is imperceptible at sparkline scale). Returns
 * the new latest price so callers can keep their walk in sync.
 */
function pushSparklinePoint(symbol, newPrice) {

    const sparkline = sparklineCharts[symbol];

    if (!sparkline) return;

    const data = sparkline.chart.data.datasets[0].data;

    data.push(newPrice);
    data.shift();

    sparkline.chart.data.labels = data.map((_, i) => i);
    sparkline.chart.update("none");

}