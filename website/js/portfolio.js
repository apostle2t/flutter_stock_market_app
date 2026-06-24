const portfolioCanvas =
    document.getElementById("portfolioChart");

if (portfolioCanvas) {

    new Chart(portfolioCanvas, {

        type: "line",

        data: {

            labels: [
                "Jan",
                "Feb",
                "Mar",
                "Apr",
                "May",
                "Jun"
            ],

            datasets: [{

                label: "Portfolio Value",

                data: [
                    95000,
                    101000,
                    108000,
                    112000,
                    118000,
                    125430
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

