<?php
include 'koneksi.php';

// Support both FormData (from Flutter) and JSON (from Admin panel)
$input = $_POST;
if (empty($input) || !isset($input['id'])) {
    $json = json_decode(file_get_contents('php://input'), true);
    if ($json) $input = $json;
}

// Accept both 'id' and 'id_paket' for backwards compatibility
$id = $input['id'] ?? $input['id_paket'] ?? '';
$id_kurir = $input['id_kurir'] ?? '';

if (empty($id) || empty($id_kurir)) {
    echo json_encode(["status" => "error", "message" => "Data tidak lengkap"]);
    exit();
}

$sql = "UPDATE paket SET id_kurir = ? WHERE id = ?";
$stmt = $koneksi->prepare($sql);
$stmt->bind_param("ii", $id_kurir, $id);

if ($stmt->execute()) {
    echo json_encode(["status" => "success", "message" => "Kurir berhasil di-assign"]);
} else {
    echo json_encode(["status" => "error", "message" => "Gagal: " . $stmt->error]);
}
?>