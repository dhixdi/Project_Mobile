<?php
include 'koneksi.php';
$id_kurir_transit = $_GET['id_kurir_transit'] ?? '';
if (empty($id_kurir_transit)) {
    echo json_encode(["status" => "error", "message" => "ID Kurir Transit kosong"]);
    exit;
}
$sql = "SELECT p.*, w_asal.nama_gudang AS nama_gudang_asal, w_tujuan.nama_gudang AS nama_gudang_tujuan, w_tujuan.latitude AS lat_gudang_tujuan, w_tujuan.longitude AS lng_gudang_tujuan FROM paket p LEFT JOIN warehouse w_asal ON p.id_warehouse = w_asal.id LEFT JOIN warehouse w_tujuan ON p.id_warehouse_tujuan = w_tujuan.id WHERE p.id_kurir_transit = ? AND p.tipe = 'antargudang' AND p.status IN ('Di Gudang', 'Transit Antargudang', 'Di Gudang Tujuan')";
$stmt = $koneksi->prepare($sql);
$stmt->bind_param("s", $id_kurir_transit);
$stmt->execute();
$result = $stmt->get_result();
$data = [];
while ($row = $result->fetch_assoc()) $data[] = $row;
echo json_encode(["status" => "success", "data" => $data]);
?>
