<?php
include 'koneksi.php';

// Support both FormData (from Flutter) and JSON (from Admin panel)
$input = $_POST;
if (empty($input) || !isset($input['no_resi'])) {
    $json = json_decode(file_get_contents('php://input'), true);
    if ($json) $input = $json;
}

$no_resi = $input['no_resi'] ?? '';
$deskripsi = $input['deskripsi_barang'] ?? '';
$nama_pengirim = $input['nama_pengirim'] ?? '';
$nama_penerima = $input['nama_penerima'] ?? '';
$alamat_penerima = $input['alamat_penerima'] ?? '';
$lat = !empty($input['lat_penerima']) ? $input['lat_penerima'] : null;
$lng = !empty($input['lng_penerima']) ? $input['lng_penerima'] : null;
$id_warehouse = $input['id_warehouse'] ?? 1;
$id_kurir = !empty($input['id_kurir']) ? $input['id_kurir'] : null;
$tipe = $input['tipe'] ?? 'lokal';
$id_warehouse_tujuan = !empty($input['id_warehouse_tujuan']) ? $input['id_warehouse_tujuan'] : null;
$id_kurir_transit = !empty($input['id_kurir_transit']) ? $input['id_kurir_transit'] : null;

if (empty($no_resi) || empty($nama_penerima) || empty($alamat_penerima)) {
    echo json_encode(["status" => "error", "message" => "Data tidak lengkap"]);
    exit();
}

$sql = "INSERT INTO paket (no_resi, deskripsi_barang, nama_pengirim, nama_penerima, alamat_penerima, lat_penerima, lng_penerima, id_warehouse, tipe, id_warehouse_tujuan, id_kurir, id_kurir_transit) VALUES (?,?,?,?,?,?,?,?,?,?,?,?)";
$stmt = $koneksi->prepare($sql);
$stmt->bind_param("sssssddisiii", $no_resi, $deskripsi, $nama_pengirim, $nama_penerima, $alamat_penerima, $lat, $lng, $id_warehouse, $tipe, $id_warehouse_tujuan, $id_kurir, $id_kurir_transit);

if ($stmt->execute()) {
    echo json_encode(["status" => "success", "message" => "Paket berhasil ditambahkan"]);
} else {
    echo json_encode(["status" => "error", "message" => "Gagal: " . $stmt->error]);
}
?>