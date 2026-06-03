<?php
include 'koneksi.php';
$id = $_POST['id'] ?? '';
$id_kurir_transit = $_POST['id_kurir_transit'] ?? '';
$id_warehouse_tujuan = $_POST['id_warehouse_tujuan'] ?? '';
if (empty($id) || empty($id_kurir_transit) || empty($id_warehouse_tujuan)) {
    echo json_encode(["status" => "error", "message" => "Data tidak lengkap"]);
    exit;
}
$sql = "UPDATE paket SET id_kurir_transit = ?, id_warehouse_tujuan = ?, tipe = 'antargudang', status = 'Di Gudang' WHERE id = ?";
$stmt = $koneksi->prepare($sql);
$stmt->bind_param("iii", $id_kurir_transit, $id_warehouse_tujuan, $id);
if ($stmt->execute()) {
    echo json_encode(["status" => "success", "message" => "Kurir Transit berhasil di-assign"]);
} else {
    echo json_encode(["status" => "error", "message" => $stmt->error]);
}
?>
