<?php
// get_paket.php — List semua paket dengan JOIN warehouse + users (kurir)
include 'koneksi.php';

$sql = "SELECT p.*, 
               w.nama_gudang, 
               wt.nama_gudang AS nama_gudang_tujuan,
               u.username AS kurir_username,
               ut.username AS kurir_transit_username
        FROM paket p 
        LEFT JOIN warehouse w ON p.id_warehouse = w.id 
        LEFT JOIN warehouse wt ON p.id_warehouse_tujuan = wt.id 
        LEFT JOIN users u ON p.id_kurir = u.id
        LEFT JOIN users ut ON p.id_kurir_transit = ut.id
        ORDER BY p.id DESC";

$result = mysqli_query($koneksi, $sql);
$data = array();
if (mysqli_num_rows($result) > 0) {
    while ($row = mysqli_fetch_assoc($result)) {
        $data[] = $row;
    }
}
echo json_encode(["status" => "success", "total_data" => count($data), "data" => $data]);
mysqli_close($koneksi);
?>