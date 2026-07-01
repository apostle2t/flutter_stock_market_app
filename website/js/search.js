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