<?php
include 'koneksi.php';
$no_resi = $_POST['no_resi'] ?? '';
$status_baru = $_POST['status'] ?? '';
$status_valid = ['Di Gudang', 'Transit Antargudang', 'Di Gudang Tujuan', 'Sedang Diantar', 'Selesai'];
if (empty($no_resi) || !in_array($status_baru, $status_valid)) {
    echo json_encode(["status" => "error", "message" => "Data tidak valid"]);
    exit;
}
$sql = "UPDATE paket SET status = ? WHERE no_resi = ?";
$stmt = $koneksi->prepare($sql);
$stmt->bind_param("ss", $status_baru, $no_resi);
if ($stmt->execute()) {
    echo json_encode(["status" => "success", "message" => "Status berhasil diupdate ke: $status_baru"]);
} else {
    echo json_encode(["status" => "error", "message" => "Gagal update status"]);
}
?>