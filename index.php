<?php
header("Cache-Control: no-store, no-cache, must-revalidate, max-age=0");
header("Cache-Control: post-check=0, pre-check=0", false);
header("Pragma: no-cache");
header("Content-Type: text/plain");

$USERAGENT = isset($_SERVER['HTTP_USER_AGENT']) ? $_SERVER['HTTP_USER_AGENT'] : "";
error_log("User agent: '$USERAGENT'");
$USERAGENT = strtolower($USERAGENT);

// shell => URL
$REDIRECTS = array(
    "pwsh" => "install.ps1",
    "bash" => "install.sh",
    "browser" => "https://github.com/qzind/qz.sh"
);

function get_redirect() {
    global $USERAGENT, $REDIRECTS;
    $detected = "browser";
    if(strpos($USERAGENT, "powershell") !== false) {
        $detected = "pwsh";
    }
    if(strpos($USERAGENT, "wget") !== false || strpos($USERAGENT, "curl") !== false) {
        $detected = "bash";
    }
    $redirect = $REDIRECTS[$detected];
    error_log("Answering: '$redirect'");
    if($detected == "browser") {
        header("Location: $redirect");
    }
    echo file_get_contents($redirect);
}

get_redirect();

?>