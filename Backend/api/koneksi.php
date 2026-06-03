<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS, DELETE, PUT");
header("Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With");
header("Content-Type: application/json; charset=UTF-8");
if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') {
    http_response_code(200);
    exit();
}
$db_user = getenv('DB_USER') ?: 'root';
$db_pass = getenv('DB_PASS') ?: '';
$db_name = getenv('DB_NAME') ?: 'db_gudangpintar';
$cloud_sql_connection = getenv('CLOUD_SQL_CONNECTION_NAME');
if ($cloud_sql_connection) {
    $socket = '/cloudsql/' . $cloud_sql_connection;
    $koneksi = new mysqli('localhost', $db_user, $db_pass, $db_name, null, $socket);
} else {
    $koneksi = new mysqli('localhost', $db_user, $db_pass, $db_name);
}
if ($koneksi->connect_error) {
    echo json_encode(["status" => "error", "message" => "Koneksi gagal: " . $koneksi->connect_error]);
    exit();
}
?>