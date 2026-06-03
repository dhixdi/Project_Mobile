<?php
include 'koneksi.php';
function generateNoResi($koneksi): string {
    $prefix = 'GPX';
    $date = date('Ymd');
    $sql = "SELECT COUNT(*) as total FROM paket WHERE no_resi LIKE ?";
    $pattern = "$prefix-$date-%";
    $stmt = $koneksi->prepare($sql);
    $stmt->bind_param("s", $pattern);
    $stmt->execute();
    $result = $stmt->get_result()->fetch_assoc();
    $sequence = str_pad($result['total'] + 1, 4, '0', STR_PAD_LEFT);
    return "$prefix-$date-$sequence";
}
echo json_encode(['status' => 'success', 'no_resi' => generateNoResi($koneksi)]);
?>
