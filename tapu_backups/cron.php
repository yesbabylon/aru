<?php

include_once '../helpers/cron-handler.php';
include_once '../helpers/env.php';

const BASE_DIR = __DIR__;
const CONTROLLERS_DIR = __DIR__ . '/controllers';
const TOKENS_DIR = __DIR__ . '/tokens';

$cron_jobs = [
    [
        'description'   => "Check for expired tokens every 5 minutes.",
        'crontab'       => '*/5 * * * *',
        'controller'    => 'release-expired-tokens'
    ],
    [
        'description'   => "Remove expired backup tokens once a day.",
        'crontab'       => '0 23 * * *',
        'controller'    => 'remove-expired-backups'
    ]
];

$results = handle_cron_jobs($cron_jobs);

echo json_encode($results, JSON_PRETTY_PRINT).PHP_EOL;
