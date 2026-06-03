<?php
include 'koneksi.php';
$no_resi = $_POST['no_resi'] ?? '';
$deskripsi = $_POST['deskripsi_barang'] ?? '';
$nama_pengirim = $_POST['nama_pengirim'] ?? '';
$nama_penerima = $_POST['nama_penerima'] ?? '';
$alamat_penerima = $_POST['alamat_penerima'] ?? '';
$lat = $_POST['lat_penerima'] ?? null;
$lng = $_POST['lng_penerima'] ?? null;
$id_warehouse = $_POST['id_warehouse'] ?? 1;
$id_kurir = !empty($_POST['id_kurir']) ? $_POST['id_kurir'] : null;
$tipe = $_POST['tipe'] ?? 'lokal';
$id_warehouse_tujuan = !empty($_POST['id_warehouse_tujuan']) ? $_POST['id_warehouse_tujuan'] : null;
$id_kurir_transit = !empty($_POST['id_kurir_transit']) ? $_POST['id_kurir_transit'] : null;

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