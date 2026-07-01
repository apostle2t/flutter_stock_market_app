const planMonthly = document.getElementById("planMonthly");
const planAnnual = document.getElementById("planAnnual");

const methodCard = document.getElementById("methodCard");
const methodPaypal = document.getElementById("methodPaypal");
const cardFields = document.getElementById("cardFields");
const paypalFields = document.getElementById("paypalFields");

const summaryPlanLabel = document.getElementById("summaryPlanLabel");
const summaryPlanPrice = document.getElementById("summaryPlanPrice");
const summaryTax = document.getElementById("summaryTax");
const summaryTotal = document.getElementById("summaryTotal");

const paymentForm = document.getElementById("paymentForm");
const successModalEl = document.getElementById("successModal");
const successPlanLabel = document.getElementById("successPlanLabel");
const doneBtn = document.getElementById("doneBtn");

const TAX_FLAT = 1.00;

// Track the current plan + method so we can send them to PHP on submit.
let selectedPlanLabel = "Annual Plan";
let selectedMethod = "card";

function selectPlan(selected) {

    [planMonthly, planAnnual].forEach((el) => {
        el.classList.remove("plan-selected");
    });

    selected.classList.add("plan-selected");

    const price = parseFloat(selected.dataset.price);
    const isYearly = selected === planAnnual;

    selectedPlanLabel = selected.dataset.label;

    summaryPlanLabel.textContent = `AetherPro (${isYearly ? "yearly" : "monthly"})`;
    summaryPlanPrice.textContent = `€${price.toFixed(2)}`;
    summaryTax.textContent = `€${TAX_FLAT.toFixed(2)}`;
    summaryTotal.textContent = `€${(price + TAX_FLAT).toFixed(2)}`;

    successPlanLabel.textContent = isYearly ? "Annual" : "Monthly";

}

if (planMonthly && planAnnual) {

    planMonthly.addEventListener("click", () => selectPlan(planMonthly));
    planAnnual.addEventListener("click", () => selectPlan(planAnnual));

}

function selectMethod(method) {

    selectedMethod = method;

    if (method === "card") {

        methodCard.classList.add("method-selected");
        methodPaypal.classList.remove("method-selected");
        cardFields.classList.remove("d-none");
        paypalFields.classList.add("d-none");

    } else {

        methodPaypal.classList.add("method-selected");
        methodCard.classList.remove("method-selected");
        paypalFields.classList.remove("d-none");
        cardFields.classList.add("d-none");

    }

}

if (methodCard && methodPaypal) {

    methodCard.addEventListener("click", () => selectMethod("card"));
    methodPaypal.addEventListener("click", () => selectMethod("paypal"));

}

if (paymentForm) {

    paymentForm.addEventListener("submit", async function (e) {

        e.preventDefault();

        clearPaymentErrors();

        const alertBox = document.getElementById("paymentAlert");

        // Build the payload. We add the plan + method (which live in
        // clickable divs, not form inputs) alongside the card fields.
        const formData = new FormData(paymentForm);
        formData.append("plan", selectedPlanLabel);
        formData.append("method", selectedMethod);

        try {

            const response = await fetch("process-payment.php", {
                method: "POST",
                body: formData
            });

            const result = await response.json();

            if (result.success) {

                // Server confirmed — show the existing success modal.
                const modal = new bootstrap.Modal(successModalEl);
                modal.show();

            } else {

                alertBox.classList.remove("d-none", "alert-success");
                alertBox.classList.add("alert-danger");
                alertBox.textContent = result.message || "Payment failed.";

                if (result.errors) {
                    Object.keys(result.errors).forEach(field => {
                        showPaymentFieldError(field, result.errors[field]);
                    });
                }

            }

        } catch (error) {

            alertBox.classList.remove("d-none", "alert-success");
            alertBox.classList.add("alert-danger");
            alertBox.textContent =
                "Could not reach the server. Make sure the site is running through XAMPP (http://localhost/website/).";

            console.error(error);

        }

    });

}

function showPaymentFieldError(fieldId, message) {

    if (!message) return;

    const errorEl = document.getElementById(`${fieldId}Error`);

    if (errorEl) {
        errorEl.textContent = message;
        errorEl.classList.remove("d-none");
    }

}

function clearPaymentErrors() {

    const alertBox = document.getElementById("paymentAlert");

    if (alertBox) {
        alertBox.classList.add("d-none");
        alertBox.textContent = "";
    }

    ["cardNumber", "expiry", "cvv", "cardName"].forEach(fieldId => {
        const errorEl = document.getElementById(`${fieldId}Error`);
        if (errorEl) {
            errorEl.textContent = "";
            errorEl.classList.add("d-none");
        }
    });

}

if (doneBtn) {

    doneBtn.addEventListener("click", function () {

        window.location.href = "profile.html";

    });

}