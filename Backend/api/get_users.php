<?php
include 'koneksi.php';
$role_filter = $_GET['role'] ?? '';
$sql = "SELECT id, username, role, created_at FROM users";
if (!empty($role_filter)) {
    $sql .= " WHERE role = ?";
    $stmt = $koneksi->prepare($sql);
    $stmt->bind_param("s", $role_filter);
    $stmt->execute();
    $result = $stmt->get_result();
} else {
    $result = mysqli_query($koneksi, $sql);
}
$data = [];
while ($row = $result->fetch_assoc()) $data[] = $row;
echo json_encode(["status" => "success", "data" => $data]);
?>
