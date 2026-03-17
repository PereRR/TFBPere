<?php
$host = getenv('DB_HOST') ?: 'db';
$db   = getenv('DB_NAME') ?: 'peretfb';
$user = getenv('DB_USER') ?: 'peretfb';
$pass = getenv('DB_PASSWORD') ?: 'peretfbpass';

$conn = new mysqli($host, $user, $pass, $db);

if ($conn->connect_error) {
    die("Database connection failed: " . $conn->connect_error);
}
?>