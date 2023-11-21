<?php
$USERAGENT = isset($_SERVER['HTTP_USER_AGENT']) ? strtolower($_SERVER['HTTP_USER_AGENT']) : "";

// shell => URL
$REDIRECTS = array(
    "pwsh" => "install.ps1",
    "bash" => "install.sh"
);

function get_redirect() {
    global $USERAGENT, $REDIRECTS;
    $shell = "bash";
    if($USERAGENT == "" || strpos($USERAGENT, "powershell") !== false) {
        $shell = "pwsh";
    }
    if(strpos($USERAGENT, "wget") !== false || strpos($USERAGENT, "curl") !== false) {
        $shell = "bash";
    }
    return $REDIRECTS[$shell];
}

header("Cache-Control: no-store, no-cache, must-revalidate, max-age=0");
header("Cache-Control: post-check=0, pre-check=0", false);
header("Pragma: no-cache");
header("Content-Type: text/plain");

echo file_get_contents(get_redirect());

?>