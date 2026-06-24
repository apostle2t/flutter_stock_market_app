const MARKETSTACK_KEY = "c8a4104f9d2ebb0c1b775e0a8bbbe293";

const params = new URLSearchParams(window.location.search);

const symbol = params.get("symbol") || "AAPL";

const params =
    new URLSearchParams(
        window.location.search
    );

const symbol =
    params.get("symbol");

const country =
    params.get("country");
    
    if (country) {

    const companyName =
        document.getElementById("companyName");

    const companyPrice =
        document.getElementById("companyPrice");

    const companyChange =
        document.getElementById("companyChange");

    if (companyName)
        companyName.textContent =
            country + " Market";

    if (companyPrice)
        companyPrice.textContent =
            "Country Search";

    if (companyChange)
        companyChange.textContent =
            "Displaying market information for selected country";

}

async function loadStock() {

    try {

        const response = await fetch(
            `https://api.marketstack.com/v1/eod/latest?access_key=${MARKETSTACK_KEY}&symbols=${symbol}`
        );

        const data = await response.json();

        console.log(data);

        const stock = data.data?.[0];

        if (!stock) return;

        document.getElementById("stockSymbol").textContent =
            symbol;

        document.getElementById("stockPrice").textContent =
            `$${stock.close.toFixed(2)}`;

        document.getElementById("stockOpen").textContent =
            `$${stock.open.toFixed(2)}`;

        document.getElementById("stockClose").textContent =
            `$${stock.close.toFixed(2)}`;

        document.getElementById("stockHigh").textContent =
            `$${stock.high.toFixed(2)}`;

        document.getElementById("stockLow").textContent =
            `$${stock.low.toFixed(2)}`;

        const change =
            ((stock.close - stock.open) / stock.open * 100)
            .toFixed(2);

        const changeElement =
            document.getElementById("stockChange");

        changeElement.textContent =
            `${change > 0 ? "+" : ""}${change}%`;

        changeElement.className =
            change >= 0
                ? "positive"
                : "negative";

        createChart(stock);

    }
    catch(error){

        console.error(error);

    }
}

function createChart(stock){

    const ctx =
        document.getElementById("stockChart");

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

                label: symbol,

                data: [
                    stock.open,
                    stock.open * 1.01,
                    stock.open * 0.99,
                    stock.open * 1.02,
                    stock.open * 1.01,
                    stock.open * 1.03,
                    stock.open * 1.02,
                    stock.close
                ],

                borderColor: "#4D8DFF",

                backgroundColor:
                    "rgba(77,141,255,0.2)",

                fill: true,

                tension: 0.4

            }]
        },

        options: {

            responsive: true,

            maintainAspectRatio: false

        }

    });
}

loadStock();