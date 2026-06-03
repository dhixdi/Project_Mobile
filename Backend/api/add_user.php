<?php
include 'koneksi.php';
$username = $_POST['username'] ?? '';
$password = $_POST['password'] ?? '';
$role = $_POST['role'] ?? 'kurir';
$allowed_roles = ['kurir', 'kurir_transit', 'admin'];
if (empty($username) || empty($password) || !in_array($role, $allowed_roles)) {
    echo json_encode(['status' => 'error', 'message' => 'Data tidak lengkap atau role tidak valid']);
    exit;
}
$check = $koneksi->prepare("SELECT id FROM users WHERE username = ?");
$check->bind_param("s", $username);
$check->execute();
if ($check->get_result()->num_rows > 0) {
    echo json_encode(['status' => 'error', 'message' => 'Username sudah digunakan']);
    exit;
}
$hashedPassword = password_hash($password, PASSWORD_BCRYPT);
$stmt = $koneksi->prepare("INSERT INTO users (username, password, role) VALUES (?, ?, ?)");
$stmt->bind_param("sss", $username, $hashedPassword, $role);
if ($stmt->execute()) {
    echo json_encode(['status' => 'success', 'message' => "User '$username' berhasil dibuat"]);
} else {
    echo json_encode(['status' => 'error', 'message' => 'Gagal menyimpan user']);
}
?>
