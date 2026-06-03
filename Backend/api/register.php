<?php
include 'koneksi.php';
$username = $_POST['username'] ?? '';
$password = $_POST['password'] ?? '';
$role = $_POST['role'] ?? 'kurir';
if (empty($username) || empty($password)) {
    echo json_encode(['status' => 'error', 'message' => 'Data tidak lengkap']);
    exit();
}
$hashedPassword = password_hash($password, PASSWORD_BCRYPT);
$checkSql = "SELECT id FROM users WHERE username = ?";
$stmt = mysqli_prepare($koneksi, $checkSql);
mysqli_stmt_bind_param($stmt, "s", $username);
mysqli_stmt_execute($stmt);
if (mysqli_stmt_get_result($stmt)->num_rows > 0) {
    echo json_encode(['status' => 'error', 'message' => 'Username sudah dipakai']);
    exit();
}
$sql = "INSERT INTO users (username, password, role) VALUES (?, ?, ?)";
$stmt = mysqli_prepare($koneksi, $sql);
mysqli_stmt_bind_param($stmt, "sss", $username, $hashedPassword, $role);
if (mysqli_stmt_execute($stmt)) {
    echo json_encode(['status' => 'success', 'message' => 'Registrasi berhasil']);
} else {
    echo json_encode(['status' => 'error', 'message' => 'Gagal menyimpan data']);
}
mysqli_stmt_close($stmt);
mysqli_close($koneksi);
?>