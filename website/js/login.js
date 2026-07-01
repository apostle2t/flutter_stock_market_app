// login.js — sends the login form to login.php in the background
// (no page reload), then shows the server's validation result inline.

const loginForm = document.getElementById("loginForm");

if (loginForm) {

    loginForm.addEventListener("submit", async (event) => {

        // Stop the browser's default submit (which would reload the page).
        event.preventDefault();

        clearLoginErrors();

        const alertBox = document.getElementById("loginAlert");

        // Gather the field values into a FormData object, which sends
        // them to PHP exactly like a normal form POST (readable as
        // $_POST["email"] etc. on the server).
        const formData = new FormData(loginForm);

        try {

            const response = await fetch("login.php", {
                method: "POST",
                body: formData
            });

            const result = await response.json();

            if (result.success) {

                alertBox.classList.remove("d-none", "alert-danger");
                alertBox.classList.add("alert-success");
                alertBox.textContent = result.message;

                // Brief pause so the user sees the success message,
                // then continue into the app.
                setTimeout(() => {
                    window.location.href = "index.html";
                }, 1200);

            } else {

                // Show the top-level message.
                alertBox.classList.remove("d-none", "alert-success");
                alertBox.classList.add("alert-danger");
                alertBox.textContent = result.message || "Login failed.";

                // Show per-field errors underneath each input, if any.
                if (result.errors) {
                    showFieldError("email", result.errors.email);
                    showFieldError("password", result.errors.password);
                }

            }

        } catch (error) {

            // This fires if PHP isn't running (e.g. opened via Live
            // Server instead of XAMPP) or the network request failed.
            alertBox.classList.remove("d-none", "alert-success");
            alertBox.classList.add("alert-danger");
            alertBox.textContent =
                "Could not reach the server. Make sure the site is running through XAMPP (http://localhost/website/).";

            console.error(error);

        }

    });

}

function showFieldError(fieldId, message) {

    if (!message) return;

    const errorEl = document.getElementById(`${fieldId}Error`);

    if (errorEl) {
        errorEl.textContent = message;
        errorEl.classList.remove("d-none");
    }

}

function clearLoginErrors() {

    const alertBox = document.getElementById("loginAlert");
    alertBox.classList.add("d-none");
    alertBox.textContent = "";

    ["email", "password"].forEach(fieldId => {
        const errorEl = document.getElementById(`${fieldId}Error`);
        if (errorEl) {
            errorEl.textContent = "";
            errorEl.classList.add("d-none");
        }
    });

}