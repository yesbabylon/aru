<?php

/**
 * Remove all expired backups (all accounts), based on current date and date present in backup filenames.
 *
 * @return array{code: string, body: string}
 */
function remove_expired_backups(): array {
    $current_time = time();

    $backups_path = getenv('BACKUPS_PATH') ?: false;
    if(!$backups_path) {
        throw new Exception("BACKUPS_PATH_not_configured", 500);
    }

    // Remove ending, if present
    $backups_path = rtrim($backups_path.'/', '/');

    if(!is_dir($backups_path)) {
        throw new Exception("BACKUPS_PATH_invalid", 500);
    }

    $instances_folders = glob($backups_path . '/*', GLOB_ONLYDIR);

    foreach($instances_folders as $path) {
        $files = glob($path . '/*.tar') + glob($path . '/*.tar.gpg');

        // #memo - never remove a standalone backup
        if(count($files) <= 1) {
            continue;
        }

        // remove backups whose TTL is expired (based on current time and date in filename)
        foreach($files as $filename) {
            $matches = [];
            $re = "/(([a-zA-Z0-9-]+\.)+[a-zA-Z]{2,})_([0-9]{4}[0-9]{2}[0-9]{2}[0-9]{0,5})_([0-9]{1,3}).*/";
            if(preg_match($re, $filename, $matches)) {
                $instance = intval($matches[1]);
                $date = intval($matches[3]);
                $ttl = intval($matches[4]);
                list($year, $month, $day) = [substr($date, 0, 4), substr($date, 4, 2), substr($date, 6, 2)];
                $file_time = mktime(0, 0, 0, $month, $day, $year);
                $diff = round( ($current_time - $file_time) / (60*60*24) );
                if($ttl < $diff) {
                    unlink($filename);
                }
            }
        }
    }

    return [
        'code' => 200,
        'body' => "expired_backups_removed"
    ];
}
