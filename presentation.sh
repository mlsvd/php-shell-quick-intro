#!/usr/bin/php
<?php

/**
 * Start process
 *
 * @param string $cmd Command to execute
 * @param bool $wantinputfd Whether or not input fd (pipe) is required
 * @retun void
 */
function processStart($cmd, $wantinputfd = false)
{
    global $process, $pipes;

    $process = proc_open(
        $cmd,
        array(
            0 => ($wantinputfd) ? array('pipe', 'r') : STDIN, // pipe/fd from which child will read
            1 => STDOUT,
            2 => array('pipe', 'w'), // pipe to which child will write any errors
            3 => array('pipe', 'w') // pipe to which child will write any output
        ),
        $pipes
    );
}

/**
 * Stop process
 *
 * @return void
 */
function processStop()
{
    global $output, $pipes, $process, $ret;

    if (isset($pipes[0])) {
        fclose($pipes[0]);
        usleep(2000);
    }

    $output = '';
    while ($_ = fgets($pipes[3])) {
        $output .= $_;
    }

    $errors = '';
    while ($_ = fgets($pipes[2])) {
        fwrite(STDERR, $_);
        $errors++;
    }

    if ($errors) {
        fwrite(STDERR, "dialog output the above errors, giving up!\n");
        exit(1);
    }

    fclose($pipes[2]);
    fclose($pipes[3]);

    do {
        usleep(2000);
        $status = proc_get_status($process);
    } while ($status['running']);

    proc_close($process);
    $ret = $status['exitcode'];
}

function getPages(): array
{
    $pages = [];
    $path = dirname(__FILE__) . DIRECTORY_SEPARATOR . 'pages';
    $scannedDir = array_diff(scandir($path), ['..', '.']);

    foreach ($scannedDir as $dir) {
	$pages[$dir] = [];
	$contentPath = $path . DIRECTORY_SEPARATOR . $dir . DIRECTORY_SEPARATOR . 'content.txt';
	if (is_readable($contentPath)) {
	    $pages[$dir]['content'] = file_get_contents($contentPath);
	}
    }

    return $pages;
}


foreach (getPages() as $pageTitle => $page) {
    processStart(
	sprintf(
	    //'whiptail --yesno --title "%s" "%s" %d %d --no-button "Next" --yes-button "Prev"',
	    'whiptail --msgbox --title "%s" "%s" %d %d',
	    $pageTitle,
	    $page['content'] ?? '',
	    $page['width'] ?? 25,
	    $page['height'] ?? 80
	)
    );
    processStop();
}
