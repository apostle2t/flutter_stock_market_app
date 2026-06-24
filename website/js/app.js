const currentDate = document.getElementById("currentDate");
const MARKETSTACK_KEY = "c8a4104f9d2ebb0c1b775e0a8bbbe293";
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


// Chart.js

const chartCanvas = document.getElementById("marketChart");

if (chartCanvas) {

    const ctx = chartCanvas.getContext("2d");

    new Chart(ctx, {
        type: "line",
        data: {
            labels: [
                "09:00",
                "10:00",
                "11:00",
                "12:00",
                "13:00",
                "14:00",
                "15:00",
                "16:00"
            ],
            datasets: [{
                label: "S&P 500",
                data: [
                    4650,
                    4680,
                    4670,
                    4700,
                    4720,
                    4710,
                    4750,
                    4780
                ],
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
                        color: "#ffffff"
                    }
                }
            },
            scales: {
                x: {
                    ticks: {
                        color: "#A0AEC0"
                    },
                    grid: {
                        color: "rgba(255,255,255,0.05)"
                    }
                },
                y: {
                    ticks: {
                        color: "#A0AEC0"
                    },
                    grid: {
                        color: "rgba(255,255,255,0.05)"
                    }
                }
            }
        }
    });
}
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

        const symbols = [
            "AAPL",
            "TSLA",
            "NVDA",
            "MSFT"
        ];

        container.innerHTML = "";

        for (const symbol of symbols) {

            const response = await fetch(
                `https://api.marketstack.com/v1/eod/latest?access_key=${MARKETSTACK_KEY}&symbols=${symbol}`
            );

            const data = await response.json();

            const stock = data.data?.[0];

            if (!stock) continue;

            const change =
                ((stock.close - stock.open) / stock.open * 100)
                .toFixed(2);

            const positive = change >= 0;

            container.innerHTML += `
                <div class="col-md-6 col-xl-3">

                    <div class="market-card">

                        <h6>${symbol}</h6>

                        <h3
                            class="stock-price"
                            data-usd="${stock.close}"
                        >
                            $${stock.close.toFixed(2)}
                        </h3>

                        <span class="${
                            positive ? "positive" : "negative"
                        }">

                            ${positive ? "+" : ""}${change}%

                        </span>

                    </div>

                </div>
            `;
        }

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

        console.log(data);

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
const searchInput =
    document.getElementById("searchInput");

if (searchInput) {

    searchInput.addEventListener(
        "keypress",
        function(e) {

            if (e.key !== "Enter") return;

            const query =
                this.value.trim();

            if (!query) return;

            const countries = [
                "germany",
                "usa",
                "united states",
                "uk",
                "united kingdom",
                "france",
                "spain",
                "italy",
                "canada",
                "japan",
                "china"
            ];

            if (
                countries.includes(
                    query.toLowerCase()
                )
            ) {

                window.location.href =
                    `stock.html?country=${encodeURIComponent(query)}`;

            } else {

                window.location.href =
                    `stock.html?symbol=${encodeURIComponent(query.toUpperCase())}`;

            }

        }
    );

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
