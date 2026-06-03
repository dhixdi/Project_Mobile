<?php
include 'koneksi.php';
$GEOCODING_API_KEY = getenv('GEOCODING_API_KEY') ?: 'AIzaSyClLJ_2VxaMYtb0j03PGqP4tQV-srciKKs';
$address = $_GET['address'] ?? '';
if (empty($address)) {
    echo json_encode(['status' => 'error', 'message' => 'Alamat kosong']);
    exit;
}
$encoded = urlencode($address);
$url = "https://maps.googleapis.com/maps/api/geocode/json?address=$encoded&key=$GEOCODING_API_KEY&region=id";
$ch = curl_init($url);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
$response = curl_exec($ch);
curl_close($ch);
$data = json_decode($response, true);
if ($data['status'] === 'OK') {
    $loc = $data['results'][0]['geometry']['location'];
    echo json_encode(['status' => 'success', 'lat' => $loc['lat'], 'lng' => $loc['lng'], 'alamat_formatted' => $data['results'][0]['formatted_address']]);
} else {
    echo json_encode(['status' => 'error', 'message' => 'Alamat tidak ditemukan']);
}
?>
