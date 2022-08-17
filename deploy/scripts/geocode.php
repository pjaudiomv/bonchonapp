<?php

$data = json_decode(file_get_contents("locations.json"), true);
$new_arr = array();

foreach ($data as $key => $value) {
    $full_address = $value['street'] . ", " . $value['city'] . " " . $value['state'] . " " . $value['zip'];
    $gecoded_result = geocode($full_address);
//    echo $gecoded_result['long'] . ", " . $gecoded_result['lat'];
    $new_arr[$key] = $value;
    $new_arr[$key]['long'] = $gecoded_result['long'];
    $new_arr[$key]['lat'] = $gecoded_result['lat'];
}

echo json_encode($new_arr);

function geocode($address) {
    $google_api_key = "";
    $coords = array();
    $map_details_response = get("https://maps.googleapis.com/maps/api/geocode/json?key=$google_api_key"
        . "&address="
        . urlencode($address));
    $map_details = json_decode($map_details_response);

    $coords['long'] = "";
    $coords['lat'] = "";

    if (count($map_details->results) > 0) {
        $geometry      = $map_details->results[0]->geometry->location;
        $coords['long'] = $geometry->lng;
        $coords['lat'] = $geometry->lat;
    }

    return $coords;
}

function get($url) {
    //error_log($url);
    $ch = curl_init();
    curl_setopt($ch, CURLOPT_URL, $url);
    curl_setopt($ch, CURLOPT_USERAGENT, 'Mozilla/4.0 (compatible; MSIE 5.01; Windows NT 5.0) +bmltgeo' );
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, 1);
    $data = curl_exec($ch);
    if(curl_errno($ch)){
        throw new Exception(curl_error($ch));
    }
    curl_close($ch);
    return $data;
}
