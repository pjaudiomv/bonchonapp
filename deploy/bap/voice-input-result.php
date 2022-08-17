<?php
    include 'functions.php';
    header("content-type: text/xml");
    echo "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n";
    
    $province = $province_lookup ? $_REQUEST['Province'] : getProvince();
    $speechResult = $_REQUEST['SpeechResult'];
?>
<Response>
    <Redirect method="GET">address-lookup.php?Digits=<?php echo urlencode($speechResult . ", " . $province); ?></Redirect>
</Response>