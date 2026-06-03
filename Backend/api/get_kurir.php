<?php
// get_kurir.php — List semua kurir (reguler + transit) untuk admin panel
include 'koneksi.php';

$sql = "SELECT id, username, role FROM users WHERE role IN ('kurir', 'kurir_transit') ORDER BY role, username";
$result = mysqli_query($koneksi, $sql);
$data = [];
while ($row = mysqli_fetch_assoc($result)) {
    $data[] = $row;
}
echo json_encode(["status" => "success", "data" => $data]);
?>
