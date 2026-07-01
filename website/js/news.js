const NEWS_API_KEY = "efcaeb0b8ef24f599f32b5668ae58716";

let currentCategory = "stock market";

async function loadNews(category = "stock market") {

    const container =
        document.getElementById("newsContainer");

    container.innerHTML =
        "<p>Loading news...</p>";

    try {

        const response = await fetch(
            `https://newsapi.org/v2/everything?q=${encodeURIComponent(category)}&sortBy=publishedAt&pageSize=12&apiKey=${NEWS_API_KEY}`
        );

        const data = await response.json();

        console.log(data);

        container.innerHTML = "";

        data.articles.forEach(article => {

            container.innerHTML += `
                <div class="col-md-6">

                    <div class="news-card h-100">

                        ${
                            article.urlToImage
                            ?
                            `<img src="${article.urlToImage}"
                                  class="img-fluid rounded mb-3">`
                            :
                            ""
                        }

                        <h5>${article.title}</h5>

                        <p>
                            ${article.description || ""}
                        </p>

                        <small class="text-secondary">
                            ${article.source.name}
                        </small>

                        <br><br>

                        <a
                            href="${article.url}"
                            target="_blank"
                            class="btn btn-primary"
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

        container.innerHTML =
            "<p>Failed to load news.</p>";
    }
}

document.querySelectorAll(".category-btn")
.forEach(button => {

    button.addEventListener("click", () => {

        document.querySelectorAll(".category-btn")
        .forEach(btn => {

            btn.classList.remove("btn-primary");

            btn.classList.add("btn-outline-light");

        });

        button.classList.remove("btn-outline-light");

        button.classList.add("btn-primary");

        currentCategory =
            button.dataset.category;

        loadNews(currentCategory);

    });

});

document.getElementById("newsSearch")
.addEventListener("keypress", e => {

    if (e.key === "Enter") {

        loadNews(e.target.value);

    }

});

loadNews(currentCategory);