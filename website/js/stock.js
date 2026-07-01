const params =
    new URLSearchParams(
        window.location.search
    );

const symbol =
    params.get("symbol");

const country =
    params.get("country");


// Curated per-country data. USA and China include a real,
// live-fetched anchor stock — confirmed available on FMP's free
// tier after testing several candidates per market. Germany, UK,
// and Japan use fully curated/static data, since none of the
// non-US tickers tested for those markets (SAP, Siemens, AstraZeneca,
// Unilever, Toyota, Sony, Shell, Novartis, BP, Nintendo) were
// available on the free tier — FMP's free quote endpoint appears
// restricted to a specific allow-list weighted heavily toward
// US-listed companies.
const COUNTRY_DATA = {

    germany: {
        flag: "🇩🇪",
        liveSymbol: null,
        liveLabel: null,
        secondLiveSymbol: null,
        secondLiveName: null,
        staticStocks: [
            { name: "SAP SE", price: 152.51, change: -1.24 },
            { name: "Siemens AG", price: 185.62, change: -6.01 },
            { name: "Allianz SE", price: 332.40, change: -6.05 },
            { name: "Rheinmetall AG", price: 1276.00, change: -5.69 }
        ]
    },

    usa: {
        flag: "🇺🇸",
        liveSymbol: "AAPL",
        liveLabel: "Apple Inc.",
        secondLiveSymbol: "MSFT",
        secondLiveName: "Microsoft Corp.",
        staticStocks: [
            { name: "Tesla Inc.", price: 375.12, change: -0.04 },
            { name: "Nvidia Corp.", price: 195.74, change: -2.17 }
        ]
    },

    "united states": {
        flag: "🇺🇸",
        liveSymbol: "AAPL",
        liveLabel: "Apple Inc.",
        secondLiveSymbol: "MSFT",
        secondLiveName: "Microsoft Corp.",
        staticStocks: [
            { name: "Tesla Inc.", price: 375.12, change: -0.04 },
            { name: "Nvidia Corp.", price: 195.74, change: -2.17 }
        ]
    },

    uk: {
        flag: "🇬🇧",
        liveSymbol: null,
        liveLabel: null,
        secondLiveSymbol: null,
        secondLiveName: null,
        staticStocks: [
            { name: "AstraZeneca PLC", price: 185.68, change: 0.47 },
            { name: "Unilever PLC", price: 56.20, change: -1.85 },
            { name: "HSBC Holdings", price: 48.90, change: -0.92 },
            { name: "BP PLC", price: 32.15, change: -2.40 }
        ]
    },

    "united kingdom": {
        flag: "🇬🇧",
        liveSymbol: null,
        liveLabel: null,
        secondLiveSymbol: null,
        secondLiveName: null,
        staticStocks: [
            { name: "AstraZeneca PLC", price: 185.68, change: 0.47 },
            { name: "Unilever PLC", price: 56.20, change: -1.85 },
            { name: "HSBC Holdings", price: 48.90, change: -0.92 },
            { name: "BP PLC", price: 32.15, change: -2.40 }
        ]
    },

    japan: {
        flag: "🇯🇵",
        liveSymbol: null,
        liveLabel: null,
        secondLiveSymbol: null,
        secondLiveName: null,
        staticStocks: [
            { name: "Toyota Motor Corp.", price: 166.50, change: -0.45 },
            { name: "Sony Group Corp.", price: 88.40, change: -1.20 },
            { name: "SoftBank Group", price: 24.60, change: -3.05 },
            { name: "Nintendo Co.", price: 12.85, change: -0.65 }
        ]
    },

    china: {
        flag: "🇨🇳",
        liveSymbol: "BABA",
        liveLabel: "Alibaba Group Holding Ltd. (US-listed ADR)",
        secondLiveSymbol: null,
        secondLiveName: null,
        staticStocks: [
            { name: "Tencent Holdings", price: 62.30, change: 1.15 },
            { name: "PDD Holdings", price: 108.40, change: -0.85 },
            { name: "JD.com Inc.", price: 34.20, change: 0.62 }
        ]
    }

};


// Tracks state needed by both the range buttons and the trade modal,
// since both need to know which company's data is currently charted.
let currentChartLabel = "this stock";
let currentHistory = [];
let currentRange = "1D";

const BROWSE_SYMBOLS = [
    "AAPL", "TSLA", "NVDA", "MSFT", "AMZN", "GOOGL",
    "META", "JPM", "WMT"
];


if (country) {
    loadCountryView(country);
} else if (symbol) {
    loadStock();
} else {
    loadDefaultBrowseView();
}


function setupRangeButtons() {

    const buttons = document.querySelectorAll(".range-btn");

    buttons.forEach(btn => {

        btn.addEventListener("click", () => {

            buttons.forEach(b => {
                b.classList.remove("active", "btn-primary");
                b.classList.add("btn-outline-light");
            });

            btn.classList.add("active", "btn-primary");
            btn.classList.remove("btn-outline-light");

            currentRange = btn.dataset.range;
            renderChartForRange();

        });

    });

}


function renderChartForRange() {

    if (!currentHistory.length) return;

    const sliced = sliceHistoryRange(currentHistory, currentRange);

    const labels = sliced.map(point => point.date);
    const prices = sliced.map(point => point.close);

    drawChart(labels, prices, currentChartLabel);

}


async function loadCountryView(countryName) {

    const countryKey = countryName.toLowerCase();
    const countryInfo = COUNTRY_DATA[countryKey];

    const symbolEl = document.getElementById("stockSymbol");
    const priceEl = document.getElementById("stockPrice");
    const changeEl = document.getElementById("stockChange");
    const chartTitleEl = document.getElementById("chartTitle");

    const displayName =
        countryName.length <= 3
            ? countryName.toUpperCase()
            : countryName.charAt(0).toUpperCase() + countryName.slice(1).toLowerCase();

    if (!countryInfo) {

        if (symbolEl) symbolEl.textContent = displayName + " Market";
        if (priceEl) priceEl.textContent = "Not yet supported";
        if (changeEl) changeEl.textContent =
            "We don't have curated data for this country yet.";

        return;

    }

    if (symbolEl) symbolEl.textContent =
        `${countryInfo.flag} ${displayName}`;

    if (chartTitleEl) chartTitleEl.textContent =
        `Market Snapshot: ${displayName}`;

    setupRangeButtons();

    // Countries without a confirmed-working free-tier symbol skip
    // the live fetch entirely and show curated data only.
    if (!countryInfo.liveSymbol) {

        if (priceEl) priceEl.textContent = "—";
        if (changeEl) changeEl.textContent =
            "Curated market data (live quotes not available for this market on our current plan)";

        hideChartAndTradeControls();

        renderCountryStockList(countryInfo, null);
        return;

    }

    if (priceEl) priceEl.textContent = "Loading...";
    if (changeEl) changeEl.textContent = "";

    try {

        const symbolsToFetch = countryInfo.secondLiveSymbol
            ? `${countryInfo.liveSymbol},${countryInfo.secondLiveSymbol}`
            : countryInfo.liveSymbol;

        const quotes = await fetchQuoteCached(symbolsToFetch);

        const anchorStock = quotes.find(q => q.symbol === countryInfo.liveSymbol);

        const secondStock = countryInfo.secondLiveSymbol
            ? quotes.find(q => q.symbol === countryInfo.secondLiveSymbol)
            : null;

        if (anchorStock) {

            const positive = anchorStock.changePercentage >= 0;

            if (priceEl) {
                priceEl.id = "countryAnchorPrice";
                priceEl.textContent = `$${anchorStock.price.toFixed(2)}`;
            }

            if (changeEl) {

                changeEl.textContent =
                    `${countryInfo.liveLabel} · ${positive ? "+" : ""}${anchorStock.changePercentage.toFixed(2)}%`;

                changeEl.className =
                    positive ? "positive" : "negative";

            }

            currentChartLabel = countryInfo.liveLabel;
            currentHistory = await fetchHistoryCached(countryInfo.liveSymbol);
            renderChartForRange();

            startPriceSimulation((randomDrift) => {

                const simulatedPrice = anchorStock.price * (1 + randomDrift() / 100);

                if (priceEl) {
                    priceEl.textContent = `$${simulatedPrice.toFixed(2)}`;
                    priceEl.classList.add("price-pulse");
                    setTimeout(() => priceEl.classList.remove("price-pulse"), 600);
                }

            }, 2000);

        }

        renderCountryStockList(countryInfo, secondStock);

    } catch (error) {

        console.error(error);

        if (changeEl) changeEl.textContent =
            "Live data unavailable right now.";

        renderCountryStockList(countryInfo, null);

    }

}


async function loadDefaultBrowseView() {

    const symbolEl = document.getElementById("stockSymbol");
    const priceEl = document.getElementById("stockPrice");
    const changeEl = document.getElementById("stockChange");

    if (symbolEl) symbolEl.textContent = "Explore the Markets";
    if (priceEl) priceEl.textContent = "";
    if (changeEl) changeEl.textContent =
        "Search a company or country above, or pick a stock below.";

    hideChartAndTradeControls();

    const container = document.getElementById("countryStockList");

    if (!container) return;

    container.innerHTML = `
        <h4 class="mb-3">Popular Stocks</h4>
        <div class="row g-3" id="browseGrid"></div>
    `;

    const grid = document.getElementById("browseGrid");

    try {

        const quotes = await fetchQuoteCached(BROWSE_SYMBOLS.join(","));

        BROWSE_SYMBOLS.forEach(sym => {

            const stock = quotes.find(q => q.symbol === sym);

            if (!stock) return;

            const positive = stock.changePercentage >= 0;

            grid.innerHTML += `
                <div class="col-md-6 col-lg-4">

                    <a
                        href="stock.html?symbol=${sym}"
                        class="market-card text-decoration-none d-block"
                        id="browseCard-${sym}"
                    >

                        <div class="d-flex align-items-center gap-2 mb-1">
                            ${stockIconHtml(sym, 32)}
                            <h6 class="m-0">${sym}</h6>
                        </div>

                        <h4 id="browsePrice-${sym}">$${stock.price.toFixed(2)}</h4>

                        <span
                            id="browseChange-${sym}"
                            class="${positive ? "positive" : "negative"}"
                        >
                            ${positive ? "+" : ""}${stock.changePercentage.toFixed(2)}%
                        </span>

                        <div style="height: 50px; position: relative;">
                            <canvas id="sparkline-${sym}"></canvas>
                        </div>

                    </a>

                </div>
            `;

        });

        // Sparklines are drawn after all cards exist in the DOM,
        // fetched in parallel rather than one at a time. Each
        // sparkline's color is driven by the same daily % change
        // shown in the price card above it, not a separately
        // computed monthly trend, so the two never visually disagree.
        await Promise.all(
            BROWSE_SYMBOLS.map(sym => {
                const stockQuote = quotes.find(q => q.symbol === sym);
                const isPositive = stockQuote ? stockQuote.changePercentage >= 0 : true;
                return drawSparkline(sym, isPositive);
            })
        );

        startBrowseSimulation(quotes);

    } catch (error) {

        console.error(error);

        grid.innerHTML = `
            <div class="col-12">
                <div class="market-card">Unable to load stocks right now.</div>
            </div>
        `;

    }

}


function startBrowseSimulation(quotes) {

    // Tracks each stock's real fetched price, used as the anchor
    // point the simulation drifts around — keeps it plausible
    // without it wandering away from the true price over time.
    const state = {};

    BROWSE_SYMBOLS.forEach(sym => {

        const stock = quotes.find(q => q.symbol === sym);

        if (!stock) return;

        state[sym] = { basePrice: stock.price };

    });

    // Each browse stock keeps a walking price starting from its real
    // fetched price, so its card price and sparkline move believably
    // and independently.
    const walkPrices = {};
    BROWSE_SYMBOLS.forEach(sym => {
        if (state[sym]) walkPrices[sym] = state[sym].basePrice;
    });

    startPriceSimulation((randomDrift) => {

        BROWSE_SYMBOLS.forEach(sym => {

            const info = state[sym];

            if (!info) return;

            const priceEl = document.getElementById(`browsePrice-${sym}`);

            if (!priceEl) return;

            let next = walkPrices[sym] * (1 + randomDrift() / 100);
            next += (info.basePrice - next) * 0.05;
            walkPrices[sym] = next;

            priceEl.textContent = `$${next.toFixed(2)}`;

            priceEl.classList.add("price-pulse");
            setTimeout(() => priceEl.classList.remove("price-pulse"), 600);

            // Scroll a new point onto the sparkline so its movement is
            // actually visible, rather than nudging only the final point.
            pushSparklinePoint(sym, next);

        });

    }, 2000);

}


function hideChartAndTradeControls() {

    const chartCard = document.getElementById("stockChart")?.closest(".chart-card");
    const tradeRow = document.getElementById("buyBtn")?.closest(".row");

    if (chartCard) chartCard.style.display = "none";
    if (tradeRow) tradeRow.style.display = "none";

}


function renderCountryStockList(countryInfo, secondStock) {

    const container = document.getElementById("countryStockList");

    if (!container) return;

    const heading = countryInfo.liveSymbol
        ? "Other stocks in this market"
        : "Stocks in this market";

    container.innerHTML = `
        <h4 class="mb-3">${heading}</h4>
    `;

    if (secondStock) {

        const positive = secondStock.changePercentage >= 0;

        container.innerHTML += `
            <div class="market-card mb-3">

                <h6>${countryInfo.secondLiveName} <span class="text-secondary" style="font-size:11px;">LIVE</span></h6>

                <h4 id="countrySecondPrice">$${secondStock.price.toFixed(2)}</h4>

                <span class="${positive ? "positive" : "negative"}">
                    ${positive ? "+" : ""}${secondStock.changePercentage.toFixed(2)}%
                </span>

            </div>
        `;

        startPriceSimulation((randomDrift) => {

            const secondPriceEl = document.getElementById("countrySecondPrice");

            if (!secondPriceEl) return;

            const simulatedPrice = secondStock.price * (1 + randomDrift() / 100);

            secondPriceEl.textContent = `$${simulatedPrice.toFixed(2)}`;
            secondPriceEl.classList.add("price-pulse");
            setTimeout(() => secondPriceEl.classList.remove("price-pulse"), 600);

        }, 2000);

    }

    countryInfo.staticStocks.forEach(stock => {

        const positive = stock.change >= 0;

        container.innerHTML += `
            <div class="market-card mb-3">

                <h6>${stock.name}</h6>

                <h4>$${stock.price.toFixed(2)}</h4>

                <span class="${positive ? "positive" : "negative"}">
                    ${positive ? "+" : ""}${stock.change}%
                </span>

            </div>
        `;

    });

}


async function loadStock() {

    const chartTitleEl = document.getElementById("chartTitle");
    if (chartTitleEl) chartTitleEl.textContent = "Price Trend";

    setupRangeButtons();

    try {

        const quotes = await fetchQuoteCached(symbol);
        const stock = quotes[0];

        if (!stock) return;

        document.getElementById("stockSymbol").textContent =
            symbol;

        document.getElementById("stockPrice").textContent =
            `$${stock.price.toFixed(2)}`;

        const positive = stock.changePercentage >= 0;

        const changeElement =
            document.getElementById("stockChange");

        changeElement.textContent =
            `${positive ? "+" : ""}${stock.changePercentage.toFixed(2)}%`;

        changeElement.className =
            positive ? "positive" : "negative";

        currentChartLabel = symbol;
        currentHistory = await fetchHistoryCached(symbol);
        renderChartForRange();

        // Simulate live price ticks on the detail page too, so the
        // big price number updates like the cards do elsewhere.
        const basePrice = stock.price;

        startPriceSimulation((randomDrift) => {

            const priceEl = document.getElementById("stockPrice");

            if (!priceEl) return;

            const simulatedPrice = basePrice * (1 + randomDrift() / 100);

            priceEl.textContent = `$${simulatedPrice.toFixed(2)}`;

            priceEl.classList.add("price-pulse");
            setTimeout(() => priceEl.classList.remove("price-pulse"), 600);

        }, 2000);

    }
    catch(error){

        console.error(error);

    }
}


function drawChart(labels, data, label) {

    const ctx =
        document.getElementById("stockChart");

    if (!ctx) return;

    const existing = Chart.getChart(ctx);
    if (existing) existing.destroy();

    new Chart(ctx, {

        type: "line",

        data: {

            labels: labels,

            datasets: [{

                label: label,

                data: data,

                borderColor: "#4D8DFF",

                backgroundColor:
                    "rgba(77,141,255,0.2)",

                fill: true,

                tension: 0.4

            }]
        },

        options: {

            responsive: true,

            maintainAspectRatio: false,

            plugins: {
                legend: {
                    labels: { color: getChartTextColor() }
                }
            },

            scales: {
                x: { ticks: { color: getChartTextColor() } },
                y: { ticks: { color: getChartTextColor() } }
            }

        }

    });
}


function showTradeMessage(action) {

    const messageEl = document.getElementById("tradeMessage");
    const titleEl = document.getElementById("tradeModalTitle");
    const iconEl = document.getElementById("tradeIcon");

    const isBuy = action === "Buy";

    if (titleEl) titleEl.textContent = `${action} Order Placed`;

    if (messageEl) messageEl.textContent =
        `Your ${action.toLowerCase()} order for ${currentChartLabel} has been placed.`;

    if (iconEl) {
        iconEl.className = isBuy
            ? "success-icon-circle"
            : "success-icon-circle sell-icon-circle";
    }

    const modalEl = document.getElementById("tradeModal");

    if (modalEl) {
        const modal = new bootstrap.Modal(modalEl);
        modal.show();
    } else {
        alert(`${action} order placed for ${currentChartLabel}`);
    }

}

const buyBtn = document.getElementById("buyBtn");
const sellBtn = document.getElementById("sellBtn");

if (buyBtn) buyBtn.addEventListener("click", () => showTradeMessage("Buy"));
if (sellBtn) sellBtn.addEventListener("click", () => showTradeMessage("Sell"));