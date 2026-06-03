<?php
include 'koneksi.php';

// Support both FormData (from Flutter) and JSON (from Admin panel)
$input = $_POST;
if (empty($input) || (!isset($input['id']) && !isset($input['id_paket']))) {
    $json = json_decode(file_get_contents('php://input'), true);
    if ($json) $input = $json;
}

$id = $input['id'] ?? $input['id_paket'] ?? '';
$id_kurir_transit = $input['id_kurir_transit'] ?? '';
$id_warehouse_tujuan = $input['id_warehouse_tujuan'] ?? '';

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
