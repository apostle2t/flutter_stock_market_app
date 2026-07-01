const currentDate = document.getElementById("currentDate");
const NEWS_API_KEY = "efcaeb0b8ef24f599f32b5668ae58716";

if (currentDate) {
    const today = new Date();

    currentDate.textContent =
        today.toLocaleDateString("en-US", {
            weekday: "long",
            year: "numeric",
            month: "long",
            day: "numeric"
        });
}


// Chart.js — Dashboard's main chart uses AAPL's real historical
// closes as a representative market-trend proxy (FMP's free tier
// doesn't expose a direct S&P 500 index quote), honestly labeled
// as such rather than pretending to be the literal S&P 500 index.

let dashboardChartInstance = null;
let dashboardHistory = [];
let dashboardRange = "1D";

async function loadDashboardChart() {

    const chartCanvas = document.getElementById("marketChart");

    if (!chartCanvas) return;

    try {

        dashboardHistory = await fetchHistoryCached("AAPL");
        setupDashboardRangeButtons();
        renderDashboardChartForRange();

    } catch (error) {

        console.error("Dashboard chart failed to load", error);

    }

}

function setupDashboardRangeButtons() {

    const buttons = document.querySelectorAll(".range-btn");

    buttons.forEach(btn => {

        btn.addEventListener("click", () => {

            buttons.forEach(b => {
                b.classList.remove("active", "btn-primary");
                b.classList.add("btn-outline-light");
            });

            btn.classList.add("active", "btn-primary");
            btn.classList.remove("btn-outline-light");

            dashboardRange = btn.dataset.range;
            renderDashboardChartForRange();

        });

    });

}

function renderDashboardChartForRange() {

    if (!dashboardHistory.length) return;

    const sliced = sliceHistoryRange(dashboardHistory, dashboardRange);

    const labels = sliced.map(point => point.date);
    const prices = sliced.map(point => point.close);

    const chartCanvas = document.getElementById("marketChart");

    if (dashboardChartInstance) {
        dashboardChartInstance.data.labels = labels;
        dashboardChartInstance.data.datasets[0].data = prices;
        dashboardChartInstance.update();
        return;
    }

    dashboardChartInstance = new Chart(chartCanvas, {
        type: "line",
        data: {
            labels: labels,
            datasets: [{
                label: "AAPL (market trend proxy)",
                data: prices,
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
                    labels: {
                        color: getChartTextColor()
                    }
                }
            },
            scales: {
                x: {
                    ticks: {
                        color: getChartTextColor()
                    },
                    grid: {
                        color: "rgba(255,255,255,0.05)"
                    }
                },
                y: {
                    ticks: {
                        color: getChartTextColor()
                    },
                    grid: {
                        color: "rgba(255,255,255,0.05)"
                    }
                }
            }
        }
    });

}

const DASHBOARD_SYMBOLS = ["AAPL", "TSLA", "NVDA", "MSFT"];

async function loadMarketOverview() {

    const container = document.getElementById("marketOverview");

    if (!container) return;

    container.innerHTML = `
        <div class="col-12">
            <div class="market-card">
                Loading market data...
            </div>
        </div>
    `;

    try {

        const quotes = await fetchQuoteCached(DASHBOARD_SYMBOLS.join(","));

        container.innerHTML = "";

        for (const symbol of DASHBOARD_SYMBOLS) {

            const stock = quotes.find(q => q.symbol === symbol);

            if (!stock) continue;

            const positive = stock.changePercentage >= 0;

            container.innerHTML += `
                <div class="col-md-6 col-xl-3">

                    <a
                        href="stock.html?symbol=${symbol}"
                        class="market-card text-decoration-none d-block"
                    >

                        <div class="d-flex align-items-center gap-2 mb-1">
                            ${stockIconHtml(symbol, 32)}
                            <h6 class="m-0">${symbol}</h6>
                        </div>

                        <h3
                            id="dashPrice-${symbol}"
                            class="stock-price"
                            data-usd="${stock.price}"
                        >
                            $${stock.price.toFixed(2)}
                        </h3>

                        <span
                            id="dashChange-${symbol}"
                            class="${positive ? "positive" : "negative"}"
                        >

                            ${positive ? "+" : ""}${stock.changePercentage.toFixed(2)}%

                        </span>

                        <div style="height: 40px; position: relative;" class="mt-2">
                            <canvas id="sparkline-${symbol}"></canvas>
                        </div>

                    </a>

                </div>
            `;
        }

        await Promise.all(
            DASHBOARD_SYMBOLS.map(symbol => {
                const stock = quotes.find(q => q.symbol === symbol);
                const isPositive = stock ? stock.changePercentage >= 0 : true;
                return drawSparkline(symbol, isPositive);
            })
        );

        startDashboardSimulation(quotes);

    } catch (error) {

        console.error(error);

        container.innerHTML = `
            <div class="col-12">
                <div class="market-card">
                    Failed to load market data.
                </div>
            </div>
        `;
    }
}


function startDashboardSimulation(quotes) {

    // Tracks each stock's real fetched price/trend, plus its current
    // simulated display price. The simulation always nudges from the
    // real base price (not the previous simulated value), so it drifts
    // around the true price rather than wandering away from it.
    const state = {};

    DASHBOARD_SYMBOLS.forEach(symbol => {

        const stock = quotes.find(q => q.symbol === symbol);

        if (!stock) return;

        state[symbol] = {
            basePrice: stock.price,
            changePercentage: stock.changePercentage
        };

    });

    const walkPrices = {};
    DASHBOARD_SYMBOLS.forEach(symbol => {
        if (state[symbol]) walkPrices[symbol] = state[symbol].basePrice;
    });

    startPriceSimulation((randomDrift) => {

        DASHBOARD_SYMBOLS.forEach(symbol => {

            const info = state[symbol];

            if (!info) return;

            const priceEl = document.getElementById(`dashPrice-${symbol}`);

            if (!priceEl) return;

            let next = walkPrices[symbol] * (1 + randomDrift() / 100);
            next += (info.basePrice - next) * 0.05;
            walkPrices[symbol] = next;

            priceEl.textContent = `$${next.toFixed(2)}`;
            priceEl.dataset.usd = next;

            priceEl.classList.add("price-pulse");
            setTimeout(() => priceEl.classList.remove("price-pulse"), 600);

            // Scroll a new point onto the sparkline so movement is visible.
            pushSparklinePoint(symbol, next);

        });

    }, 2000);

}


async function loadNews() {

    const container = document.getElementById("newsContainer");

    if (!container) return;

    container.innerHTML = `
        <div class="col-12">
            <div class="news-card">
                Loading news...
            </div>
        </div>
    `;

    try {

        const response = await fetch(
            `https://newsapi.org/v2/everything?q=stock%20market&sortBy=publishedAt&pageSize=4&apiKey=${NEWS_API_KEY}`
        );

        const data = await response.json();

        container.innerHTML = "";

        data.articles.forEach(article => {

            container.innerHTML += `
                <div class="col-md-6">

                    <div class="news-card h-100">

                        <h5>${article.title}</h5>

                        <p>
                            ${article.description || "No description available."}
                        </p>

                        <a
                            href="${article.url}"
                            target="_blank"
                            class="btn btn-primary mt-2"
                        >
                            Read Article
                        </a>

                    </div>

                </div>
            `;
        });

    }
    catch(error) {

        console.error(error);

        container.innerHTML = `
            <div class="col-12">
                <div class="news-card">
                    Failed to load news.
                </div>
            </div>
        `;
    }
}

const userLocation =
    document.getElementById("userLocation");

if (navigator.geolocation && userLocation) {

    navigator.geolocation.getCurrentPosition(

        async function(position) {

            try {

                const lat =
                    position.coords.latitude;

                const lon =
                    position.coords.longitude;

                const response = await fetch(
                    `https://nominatim.openstreetmap.org/reverse?format=json&lat=${lat}&lon=${lon}`
                );

                const data =
                    await response.json();

                const country =
                    data.address.country;

                userLocation.textContent =
                    "Detected Country: " + country;

            } catch(error) {

                userLocation.textContent =
                    "Location unavailable";

            }

        },

        function() {

            userLocation.textContent =
                "Location permission denied";

        }

    );

}

loadNews();
loadMarketOverview();
loadDashboardChart();