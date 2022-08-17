<?php

$server = "";
$user = "";
$pass = "";

$base_url = "$server/local_server/server_admin/json.php?c_comdef_admin_login=$user&c_comdef_admin_password=$pass&admin_action=";
print_r(get($base_url . "login"));

$data = json_decode(file_get_contents("geocoded_locations.json"), true);

foreach ($data as $location) {
    $name = $location['location'];
    $link = $location['link'];
    $street = $location['street'];
    $city = $location['city'];
    $state = $location['state'];
    $zip = $location['zip'];
    $long = $location['long'];
    $lat = $location['lat'];
    $phone = $location['phone'];


    echo "\n\nLink: $link\n";
    echo "Street: $street\n";
    echo "City: $city\n";
    echo "State: $state\n";
    echo "Zip: $zip\n";
    echo "Long: $long\n";
    echo "Lat: $lat\n";
    echo "\n";

    $create = get($base_url . "add_meeting&meeting_field=meeting_name," . urlencode($name));
    $meeting_id = json_decode($create, true)['newMeeting']['id']; #"159";

    $nation = modify_meeting($meeting_id, "location_nation", "US");
    print_r($nation);
    sleep(1);

    $weekday = modify_meeting($meeting_id, "weekday_tinyint", "1");
    print_r($weekday);
    sleep(1);

    $start_time = modify_meeting($meeting_id, "start_time", "23:00:00");
    print_r($start_time);
    sleep(1);

    $formats = modify_meeting($meeting_id, "formats", "O,WC");
    print_r($formats);
    sleep(1);

    $street_address = modify_meeting($meeting_id, "location_street", urlencode($street));
    print_r($street_address);
    sleep(1);

    $city = modify_meeting($meeting_id, "location_municipality", urlencode($city));
    print_r($city);
    sleep(1);

    $state = modify_meeting($meeting_id, "location_province", $state);
    print_r($state);
    sleep(1);

    $zip = modify_meeting($meeting_id, "location_postal_code_1", $zip);
    print_r($zip);
    sleep(1);

    $longitude = modify_meeting($meeting_id, "longitude", $long);
    print_r($longitude);
    sleep(1);

    $latitude = modify_meeting($meeting_id, "latitude", $lat);
    print_r($latitude);
    sleep(1);

    $info = modify_meeting($meeting_id, "location_info", urlencode($link));
    print_r($info);
    sleep(1);

    $publish = modify_meeting($meeting_id, "published", "1");
    print_r($publish);

    $phone_meeting_number = modify_meeting($meeting_id, "comments", urlencode($phone));
    print_r($phone_meeting_number);
}


function modify_meeting($id, $field, $value) {
    $server = "";
    $user = "";
    $pass = "";
    $modify_url = "$server/local_server/server_admin/json.php?c_comdef_admin_login=$user&c_comdef_admin_password=$pass&admin_action=modify_meeting&meeting_id=$id&meeting_field=$field,$value";

    error_log($modify_url);
    $ch = curl_init();

    curl_setopt($ch, CURLOPT_URL, $modify_url);
    curl_setopt($ch, CURLOPT_COOKIEFILE, 'master_cookie.txt');
    curl_setopt($ch, CURLOPT_COOKIEJAR, 'master_cookie.txt');
    curl_setopt($ch, CURLOPT_USERAGENT, 'Mozilla/4.0 (compatible; MSIE 5.01; Windows NT 5.0) +bmltform');
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, 1);
    $data = curl_exec($ch);
    $errorno = curl_errno($ch);
    curl_close($ch);
    if ($errorno > 0) {
        throw new Exception(curl_strerror($errorno));
    }

    return $data;
}

function get($url)
{
    error_log($url);
    $ch = curl_init();

    curl_setopt($ch, CURLOPT_URL, $url);
    curl_setopt($ch, CURLOPT_COOKIEFILE, 'master_cookie.txt');
    curl_setopt($ch, CURLOPT_COOKIEJAR, 'master_cookie.txt');
    curl_setopt($ch, CURLOPT_USERAGENT, 'Mozilla/4.0 (compatible; MSIE 5.01; Windows NT 5.0) +bonchonupdate');
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, 1);
    $data = curl_exec($ch);
    $errorno = curl_errno($ch);
    curl_close($ch);
    if ($errorno > 0) {
        throw new Exception(curl_strerror($errorno));
    }

    return $data;
}
