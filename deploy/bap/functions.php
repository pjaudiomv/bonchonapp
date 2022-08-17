<?php
include_once 'config.php';
$word_language = isset($GLOBALS['word_language']) ? $GLOBALS['word_language'] : 'en-US';
include_once 'lang/'.$word_language.'.php';

$google_maps_endpoint = "https://maps.googleapis.com/maps/api/geocode/json?key=" . trim($google_maps_api_key) . "&components=country:us&address=";
$timezone_lookup_endpoint = "https://maps.googleapis.com/maps/api/timezone/json?key" . trim($google_maps_api_key);
# BMLT uses weird date formatting, Sunday is 1.  PHP uses 0 based Sunday.
static $days_of_the_week = [1 => "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"];

class Coordinates {
    public $location;
    public $latitude;
    public $longitude;
}

class MeetingResults {
    public $originalListCount = 0;
    public $filteredList = [];
}

function word($name) {
    return isset($GLOBALS['override_' . $name]) ? $GLOBALS['override_' . $name] : $GLOBALS[$name];
}

function getCoordinatesForAddress($address) {
    $coordinates = new Coordinates();

    if (strlen($address) > 0) {
        $map_details_response = get($GLOBALS['google_maps_endpoint'] . urlencode($address));
        $map_details = json_decode($map_details_response);
        if (count($map_details->results) > 0) {
            $coordinates->location  = $map_details->results[0]->formatted_address;
            $geometry               = $map_details->results[0]->geometry->location;
            $coordinates->latitude  = $geometry->lat;
            $coordinates->longitude = $geometry->lng;
        }
    }

    return $coordinates;
}

function getProvince() {
    if (isset($GLOBALS['sms_bias_bypass']) && $GLOBALS['sms_bias_bypass']) {
        return "";
    } elseif (isset($_REQUEST['ToState']) && strlen($_REQUEST['ToState']) > 0) {
        return $_REQUEST['ToState']; // Retrieved from Twilio metadata
    } elseif ($GLOBALS['toll_free_province_bias'] != null) {
        return $GLOBALS['toll_free_province_bias']; // Override for Tollfree
    } else {
        return "";
    }
}

function getGatherLanguage() {
    return isset($GLOBALS["gather_language"]) ? $GLOBALS["gather_language"] : "en-US";
}

function getGatherHints() {
    return isset($GLOBALS["gather_hints"]) ? $GLOBALS["gather_hints"] : "";
}

function meetingSearch($meeting_results, $latitude, $longitude) {
	$meeting_search_radius = isset($GLOBALS['meeting_search_radius']) ? $GLOBALS['meeting_search_radius'] : -50;
    $bmlt_search_endpoint = $GLOBALS['bmlt_root_server'] . "/client_interface/json/?switcher=GetSearchResults&sort_results_by_distance=1&long_val={LONGITUDE}&lat_val={LATITUDE}&geo_width=" . $meeting_search_radius . "&weekdays=1";

    $search_url = str_replace("{LONGITUDE}", $longitude, str_replace("{LATITUDE}", $latitude, $bmlt_search_endpoint));
    try {
        $search_response = get($search_url);
    } catch (Exception $e) {
        if ($e->getMessage() == "Couldn't resolve host name") {
            throw $e;
        } else {
            $search_response = "[]";
        }
    }

    $search_results = json_decode($search_response);
    $meeting_results->originalListCount += count($search_results);

    $filteredList = $meeting_results->filteredList;
    if ($search_response !== "{}") {
        for ($i = 0; $i < count($search_results); $i++) {
            array_push($filteredList, $search_results[$i]);
        }
    } else {
        $meeting_results->originalListCount += 0;
    }

    $meeting_results->filteredList = $filteredList;
    return $meeting_results;
}

function getResultsString($filtered_list) {
    return array(
        str_replace("&", "&amp;", $filtered_list->meeting_name),
        str_replace("&", "&amp;", $filtered_list->location_street
            . ($filtered_list->location_municipality !== "" ? " " . $filtered_list->location_municipality : "")
            . ($filtered_list->location_province !== "" ? ", " . $filtered_list->location_province : "")));

}

function getMeetings($latitude, $longitude, $results_count) {
    $meeting_results = new MeetingResults();
    $meeting_results = meetingSearch($meeting_results, $latitude, $longitude);

    return $meeting_results;
}

function get($url) {
    error_log($url);
    $ch = curl_init();
    curl_setopt($ch, CURLOPT_URL, $url);
    curl_setopt($ch, CURLOPT_COOKIEFILE, 'cookie.txt');
    curl_setopt($ch, CURLOPT_COOKIEJAR, 'cookie.txt');
    curl_setopt($ch, CURLOPT_USERAGENT, 'Mozilla/4.0 (compatible; MSIE 5.01; Windows NT 5.0) +yap' );
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, 1);
    $data = curl_exec($ch);
    $errorno = curl_errno($ch);
    curl_close($ch);
    if ($errorno > 0) {
        throw new Exception(curl_strerror($errorno));
    }

    return $data;
}
