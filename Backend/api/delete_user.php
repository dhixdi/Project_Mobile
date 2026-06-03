<?php
include 'koneksi.php';
$id = $_POST['id'] ?? '';
if (empty($id)) {
    echo json_encode(['status' => 'error', 'message' => 'ID user tidak ada']);
    exit;
}
$sql = "DELETE FROM users WHERE id = ? AND role != 'admin'";
$stmt = $koneksi->prepare($sql);
$stmt->bind_param("i", $id);
if ($stmt->execute() && $stmt->affected_rows > 0) {
    echo json_encode(['status' => 'success', 'message' => 'User berhasil dihapus']);
} else {
    echo json_encode(['status' => 'error', 'message' => 'Gagal hapus / tidak bisa hapus admin']);
}
?>
