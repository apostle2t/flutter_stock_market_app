// Holdings: shares owned + the price each was bought at (cost basis).
// Gain/Performance below are calculated from these against live prices,
// not hardcoded — only the cost basis itself is an assumed starting point,
// same as any demo portfolio without real trade history. The mix is
// deliberately realistic: a couple of strong winners, a modest winner,
// and one position that's currently underwater (bought high, now down) —
// because a believable portfolio isn't green across the board.
const HOLDINGS = [
    { symbol: "AAPL", shares: 50, costBasis: 195.00 },
    { symbol: "TSLA", shares: 30, costBasis: 355.00 },
    { symbol: "NVDA", shares: 25, costBasis: 215.00 },
    { symbol: "MSFT", shares: 20, costBasis: 340.00 }
];


async function loadPortfolio() {

    const symbolsCsv = HOLDINGS.map(h => h.symbol).join(",");

    const liveStocks = await fetchQuoteCached(symbolsCsv);

    const rows = HOLDINGS.map(holding => {

        const live = liveStocks.find(s => s.symbol === holding.symbol);
        const price = live ? live.price : holding.costBasis;

        return { ...holding, basePrice: price };

    });

    renderHoldingsTable(rows);
    recalculateAndRender(rows.map(r => ({ ...r, price: r.basePrice })));

    // Each holding keeps its own walking price, starting at the real
    // fetched price. Every tick nudges that price up or down from its
    // *previous* value (a random walk) rather than recalculating from a
    // fixed anchor — so prices genuinely trend and vary independently
    // instead of jittering in place. A mild pull back toward basePrice
    // keeps the walk from wandering unrealistically far over time.
    const walkPrices = {};
    rows.forEach(r => { walkPrices[r.symbol] = r.basePrice; });

    startPriceSimulation((randomDrift) => {

        const simulatedRows = rows.map(r => {

            const prev = walkPrices[r.symbol];

            // Random step from the previous price (independent per symbol).
            let next = prev * (1 + randomDrift() / 100);

            // Gentle mean-reversion: pull ~5% of the way back toward the
            // real price so the walk stays anchored near reality.
            next += (r.basePrice - next) * 0.05;

            walkPrices[r.symbol] = next;

            return { ...r, price: next };

        });

        updateHoldingsDisplay(simulatedRows);
        recalculateAndRender(simulatedRows);

    }, 2000);

}


function recalculateAndRender(rows) {

    let totalValue = 0;
    let totalCost = 0;

    rows.forEach(row => {

        totalValue += row.price * row.shares;
        totalCost += row.costBasis * row.shares;

    });

    const totalGain = totalValue - totalCost;
    const performance = (totalGain / totalCost) * 100;

    renderSummary(totalValue, totalGain, performance);
    renderPortfolioChart(totalValue);

}


function renderSummary(totalValue, totalGain, performance) {

    const valueEl = document.getElementById("portfolioValue");
    const gainEl = document.getElementById("portfolioGain");
    const perfEl = document.getElementById("portfolioPerformance");

    const positive = totalGain >= 0;

    if (valueEl) valueEl.textContent =
        `$${totalValue.toLocaleString(undefined, { minimumFractionDigits: 0, maximumFractionDigits: 0 })}`;

    if (gainEl) {

        gainEl.textContent =
            `${positive ? "+" : ""}$${Math.abs(totalGain).toLocaleString(undefined, { minimumFractionDigits: 0, maximumFractionDigits: 0 })}`;

        gainEl.className = positive ? "positive" : "negative";

    }

    if (perfEl) {

        perfEl.textContent =
            `${positive ? "+" : ""}${performance.toFixed(2)}%`;

        perfEl.className = positive ? "positive" : "negative";

    }

}


function renderHoldingsTable(rows) {

    const container = document.getElementById("holdingsTable");

    if (!container) return;

    container.innerHTML = "";

    rows.forEach(row => {

        const changePercent =
            ((row.basePrice - row.costBasis) / row.costBasis) * 100;

        const positive = changePercent >= 0;
        const value = row.basePrice * row.shares;

        const div = document.createElement("div");
        div.className = "holding-row";

        div.innerHTML = `
            <div class="holding-symbol-block">

                ${stockIconHtml(row.symbol, 42)}

                <div class="holding-symbol-text">
                    <h6>${row.symbol}</h6>
                    <p>${row.shares} shares</p>
                </div>

            </div>

            <div class="holding-value-block">

                <div class="holding-value-text">
                    <h6 id="holdingValue-${row.symbol}">$${value.toLocaleString(undefined, { minimumFractionDigits: 0, maximumFractionDigits: 0 })}</h6>
                    <p id="holdingChange-${row.symbol}" class="${positive ? "positive" : "negative"}">
                        ${positive ? "+" : ""}${changePercent.toFixed(2)}%
                    </p>
                </div>

                <span class="holding-chevron">&rsaquo;</span>

            </div>
        `;

        div.addEventListener("click", () => {
            window.location.href = `stock.html?symbol=${row.symbol}`;
        });

        container.appendChild(div);

    });

}


function updateHoldingsDisplay(simulatedRows) {

    simulatedRows.forEach(row => {

        const valueEl = document.getElementById(`holdingValue-${row.symbol}`);
        const changeEl = document.getElementById(`holdingChange-${row.symbol}`);

        if (!valueEl || !changeEl) return;

        const changePercent =
            ((row.price - row.costBasis) / row.costBasis) * 100;

        const positive = changePercent >= 0;
        const value = row.price * row.shares;

        valueEl.textContent =
            `$${value.toLocaleString(undefined, { minimumFractionDigits: 0, maximumFractionDigits: 0 })}`;

        changeEl.textContent =
            `${positive ? "+" : ""}${changePercent.toFixed(2)}%`;

        changeEl.className = positive ? "positive" : "negative";

        valueEl.classList.add("price-pulse");
        setTimeout(() => valueEl.classList.remove("price-pulse"), 600);

    });

}


let portfolioChartInstance = null;

function renderPortfolioChart(totalValue) {

    const ctx = document.getElementById("portfolioChart");

    if (!ctx) return;

    // Anchors the final point to the real current total value;
    // earlier points are a plausible upward path toward it, the
    // same illustrative-history approach used on the single-stock
    // and country chart views elsewhere on the site.
    const startValue = totalValue * 0.88;

    const points = [
        startValue,
        startValue * 1.03,
        startValue * 1.08,
        startValue * 1.05,
        startValue * 1.12,
        totalValue
    ];

    // Update the existing chart's data in place on simulation ticks,
    // instead of destroying and recreating it each time — avoids
    // visible flicker/jank from rebuilding the canvas every 4 seconds.
    if (portfolioChartInstance) {
        portfolioChartInstance.data.datasets[0].data = points;
        portfolioChartInstance.update();
        return;
    }

    portfolioChartInstance = new Chart(ctx, {

        type: "line",

        data: {

            labels: ["Jan", "Feb", "Mar", "Apr", "May", "Jun"],

            datasets: [{

                label: "Portfolio Value",

                data: points,

                borderColor: "#4D8DFF",

                backgroundColor: "rgba(77,141,255,0.2)",

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


loadPortfolio();