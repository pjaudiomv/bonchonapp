<?php
    include 'functions.php';
    header("content-type: text/xml");
    echo "<?xml version=\"1.0\" encoding=\"UTF-8\"?>";
    
    $latitude = $_REQUEST['Latitude'];
    $longitude = $_REQUEST['Longitude'];

    try {
        $results_count = $results_count = isset($GLOBALS['result_count_max']) ? $GLOBALS['result_count_max'] : 3;
        $meeting_results = getMeetings($latitude, $longitude, $results_count);
    } catch (Exception $e) {
        header("Location: fallback.php");
        exit;
    }

    $filtered_list = $meeting_results->filteredList;
    $sms_messages = [];

    $text_space = " ";
    $message = "";
?>
<Response>
<?php
    if (!isset($_REQUEST["SmsSid"])) {
        if ($meeting_results->originalListCount == 0) {
            echo "<Say voice=\"" . $voice . "\" language=\"" . $language . "\">" . word('no_results_found') . "... " . word('you_might_have_invalid_entry') . "... " . word('try_again') . "</Say><Redirect method=\"GET\">input-method.php?Digits=2</Redirect>";
        } elseif (count($filtered_list) == 0) {
            echo "<Say voice=\"" . $voice . "\" language=\"" . $language . "\">" . word('there_are_no_other_meetings_for_today') . ". " . word('thank_you_for_calling_goodbye') . "</Say>";
        } else {
            echo "<Say voice=\"" . $voice . "\" language=\"" . $language . "\">" . word('meeting_information_found_listing_the_top') . " " . word('results') . "</Say>";
        }
    } else {
        if ($meeting_results->originalListCount == 0) {
            echo "<Sms>" . word('no_results_found') . "... " . word('you_might_have_invalid_entry') . "..." . word('try_again') . "</Sms>";
        } elseif (count($filtered_list) == 0) {
            echo "<Sms>" . word('there_are_no_other_meetings_for_today') . "</Sms>";
        }
    }

    $results_counter = 0;
    for ($i = 0; $i < count($filtered_list); $i++) {
        $results = getResultsString($filtered_list[$i]);

        if (!isset($_REQUEST["SmsSid"])) {
            echo "<Pause length=\"1\"/>";
            echo "<Say voice=\"" . $voice . "\" language=\"" . $language . "\">" . word('number') . " " . ($results_counter + 1) . "</Say>";
            echo "<Say voice=\"" . $voice . "\" language=\"" . $language . "\">" . $results[1] . "</Say>";
        }

        if (isset($GLOBALS['include_map_link']) && $GLOBALS['include_map_link']) $results[1] .= " https://google.com/maps?q=" . $filtered_list[$i]->latitude . "," . $filtered_list[$i]->longitude;
        $message = "<Sms>" . $results[1] . "</Sms>";
        error_log($message);
        if (isset($GLOBALS["sms_ask"]) && $GLOBALS["sms_ask"] && !isset($_REQUEST["SmsSid"])) {
            array_push($sms_messages, $message);
        } else {
            echo $message;
        }
            
        $results_counter++;
        if ($results_counter == $results_count) break;
    }


    // Do not handle for the SMS gateway
    if (!isset($_REQUEST["SmsSid"]) && count($filtered_list) > 0) {
    	echo "<Pause length=\"2\"/>";
        if (count($sms_messages) > 0) { ?>
            <Say voice="<?php echo $voice ?>" language="<?php echo $language ?>">
                <?php echo word( 'press' ) ?><?php echo word( "one" ) ?> <?php echo word( 'if_you_would_like_these_results_texted_to_you' ) ?>
            </Say>
            <?php if ( isset( $GLOBALS['infinite_searching'] ) && $GLOBALS['infinite_searching'] ) { ?>
                <Say voice="<?php echo $voice ?>" language="<?php echo $language ?>">
                    <?php echo word( 'press' ) ?> <?php echo word( "two" ) ?> <?php echo word( 'if_you_would_like_to_search_again' ) ?>
                    . <?php echo word( 'press' ) ?> <?php echo word( "three" ) ?> <?php echo word( 'if_you_would_like_to_do_both' ) ?>
                </Say>
                <Gather numDigits="1" timeout="10"
                        action="post-call-action.php?Payload=<?php echo urlencode( json_encode( $sms_messages ) ) ?>"
                        method="GET"/>
            <?php }
        } elseif (isset($GLOBALS['infinite_searching']) && $GLOBALS['infinite_searching']) { ?>
            <Say voice="<?php echo $voice ?>" language="<?php echo $language ?>">
                <?php echo word('press')?> <?php echo word("two")?> <?php echo word('if_you_would_like_to_search_again') ?>.
            </Say>
            <Gather numDigits="1" timeout="10" action="post-call-action.php" method="GET"/>
        <?php } ?>

    <Say voice="<?php echo $voice ?>" language="<?php echo $language ?>">
        <?php echo word('thank_you_for_calling_goodbye')?>
    </Say>
    <?php } ?>
</Response>
