const currencySelect =
    document.getElementById("currencySelect");

let currentCurrency = "USD";

const exchangeRates = {
    USD: 1,
    EUR: 0.86,
    GBP: 0.74
};

function convertDisplayedPrices(currency) {

    const prices =
        document.querySelectorAll(".stock-price");

    prices.forEach(price => {

        const usdValue =
            parseFloat(price.dataset.usd);

        if (!usdValue) return;

        const converted =
            usdValue * exchangeRates[currency];

        let symbol = "$";

        if (currency === "EUR") {
            symbol = "€";
        }

        if (currency === "GBP") {
            symbol = "£";
        }

        price.textContent =
            symbol + converted.toFixed(2);
    });
}

if (currencySelect) {

    currencySelect.addEventListener(
        "change",
        function() {

            currentCurrency =
                this.value;

            convertDisplayedPrices(
                currentCurrency
            );

        }
    );

}