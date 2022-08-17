<?php
    include 'functions.php';
    
    $searchDescription = word('someone_to_talk_to');
    

    header("content-type: text/xml");
    echo "<?xml version=\"1.0\" encoding=\"UTF-8\"?>";
?>
<Response>
    <Gather numDigits="1" timeout="10" action="input-method-result.php" method="GET">
    
    	<?php 
			echo "<Say voice=\"" . $voice . "\" language=\"" . $language . "\">" . $GLOBALS['title'] . "</Say>";
		?>
       
        <Say voice="<?php echo $voice; ?>" language="<?php echo $language; ?>">
            <?php echo word('press') ?> <?php echo word('one') ?> <?php echo word('to_search_for') ?> <?php echo $searchDescription ?> <?php echo word ('by') ?> <?php echo word('city_or_county') ?>
        </Say>
        <Say voice="<?php echo $voice; ?>" language="<?php echo $language; ?>">
            <?php echo word('press') ?> <?php echo word('two') ?> <?php echo word('to_search_for') ?> <?php echo $searchDescription ?> <?php echo word ('by') ?> <?php echo word('zip_code') ?>
        </Say>
    </Gather>
</Response>