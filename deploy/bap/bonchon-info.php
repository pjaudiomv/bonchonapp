<?php
include 'functions.php';

header("content-type: text/xml");
echo "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n";

?>
<Response>
    <?php
    echo "<Say voice=\"" . $voice . "\" language=\"" . $language . "\">"
        . "You know you want those soy garlic strips." . "</Say>";
    ?>
    <Hangup />
</Response>
