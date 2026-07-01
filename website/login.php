<?php
// login.php — server-side handler for the login form.
// Receives the submitted email + password, validates them on the
// server (never trust the browser alone), and returns a JSON result
// the frontend reads via fetch(). No database here — this demonstrates
// server-side form processing and validation, which is the point.

header("Content-Type: application/json");

// Only accept POST — a GET request to this file is not a form submit.
if ($_SERVER["REQUEST_METHOD"] !== "POST") {
    http_response_code(405);
    echo json_encode([
        "success" => false,
        "message" => "Invalid request method. Please submit the form."
    ]);
    exit;
}

// Pull the submitted values, trimming stray whitespace. The null
// coalescing operator (??) gives an empty string if the field is
// missing entirely, so we never hit an undefined-index warning.
$email    = trim($_POST["email"] ?? "");
$password = $_POST["password"] ?? "";

// Collect any validation problems so we can report them all at once.
$errors = [];

// --- Email checks ---
if ($email === "") {
    $errors["email"] = "Email is required.";
} elseif (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
    // filter_var with FILTER_VALIDATE_EMAIL is PHP's built-in, robust
    // email format check — better than a hand-rolled regex.
    $errors["email"] = "Please enter a valid email address.";
}

// --- Password checks ---
if ($password === "") {
    $errors["password"] = "Password is required.";
} elseif (strlen($password) < 6) {
    $errors["password"] = "Password must be at least 6 characters.";
}

// If anything failed validation, report it and stop.
if (!empty($errors)) {
    http_response_code(422);
    echo json_encode([
        "success" => false,
        "message" => "Please fix the highlighted fields.",
        "errors"  => $errors
    ]);
    exit;
}

// Validation passed. In a real app this is where you'd check the
// credentials against a database. For this project we accept any
// well-formed login and return success, echoing back a safely
// escaped email so the frontend can greet the user.
echo json_encode([
    "success" => true,
    "message" => "Login successful. Redirecting to your dashboard...",
    "email"   => htmlspecialchars($email, ENT_QUOTES, "UTF-8")
]);