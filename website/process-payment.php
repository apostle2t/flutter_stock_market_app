<?php
// process-payment.php — server-side handler for the Pro upgrade
// payment form. Validates the submitted plan + card details on the
// server and returns a JSON result the frontend reads via fetch().
// No real charge happens (and no card data is stored) — this
// demonstrates server-side form validation and processing.

header("Content-Type: application/json");

if ($_SERVER["REQUEST_METHOD"] !== "POST") {
    http_response_code(405);
    echo json_encode([
        "success" => false,
        "message" => "Invalid request method. Please submit the form."
    ]);
    exit;
}

// Submitted values.
$plan       = trim($_POST["plan"] ?? "");
$method     = trim($_POST["method"] ?? "");
$cardNumber = trim($_POST["cardNumber"] ?? "");
$expiry     = trim($_POST["expiry"] ?? "");
$cvv        = trim($_POST["cvv"] ?? "");
$cardName   = trim($_POST["cardName"] ?? "");

$errors = [];

// --- Plan must be one of the known options ---
$allowedPlans = ["Monthly Plan", "Annual Plan"];
if (!in_array($plan, $allowedPlans, true)) {
    $errors["plan"] = "Please choose a valid plan.";
}

// Card fields are only required when paying by card (not PayPal).
if ($method === "card") {

    // Strip spaces from the card number before checking, since users
    // often type "1234 5678 ...". Then confirm it's 13–19 digits, the
    // normal length range for real card numbers.
    $digitsOnly = preg_replace("/\s+/", "", $cardNumber);

    if ($digitsOnly === "") {
        $errors["cardNumber"] = "Card number is required.";
    } elseif (!preg_match("/^\d{13,19}$/", $digitsOnly)) {
        $errors["cardNumber"] = "Enter a valid card number (13–19 digits).";
    }

    // Expiry must look like MM/YY with a month of 01–12.
    if ($expiry === "") {
        $errors["expiry"] = "Expiry date is required.";
    } elseif (!preg_match("/^(0[1-9]|1[0-2])\/\d{2}$/", $expiry)) {
        $errors["expiry"] = "Use MM/YY format.";
    }

    // CVV is 3 or 4 digits.
    if ($cvv === "") {
        $errors["cvv"] = "CVV is required.";
    } elseif (!preg_match("/^\d{3,4}$/", $cvv)) {
        $errors["cvv"] = "CVV must be 3 or 4 digits.";
    }

    // Cardholder name required.
    if ($cardName === "") {
        $errors["cardName"] = "Cardholder name is required.";
    }
}

if (!empty($errors)) {
    http_response_code(422);
    echo json_encode([
        "success" => false,
        "message" => "Please fix the highlighted fields.",
        "errors"  => $errors
    ]);
    exit;
}

// All good. A real app would now securely charge via a payment
// provider — we simply confirm success and echo the chosen plan.
echo json_encode([
    "success" => true,
    "message" => "Payment confirmed. Welcome to AetherPro!",
    "plan"    => htmlspecialchars($plan, ENT_QUOTES, "UTF-8")
]);