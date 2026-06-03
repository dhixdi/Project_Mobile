<?php
include 'koneksi.php';
$sql = "SELECT p.*, w.nama_gudang, wt.nama_gudang AS nama_gudang_tujuan FROM paket p LEFT JOIN warehouse w ON p.id_warehouse = w.id LEFT JOIN warehouse wt ON p.id_warehouse_tujuan = wt.id ORDER BY p.id DESC";
$result = mysqli_query($koneksi, $sql);
$data = array();
if (mysqli_num_rows($result) > 0) {
    while ($row = mysqli_fetch_assoc($result)) $data[] = $row;
}
echo json_encode(["status" => "success", "total_data" => count($data), "data" => $data]);
mysqli_close($koneksi);
?>