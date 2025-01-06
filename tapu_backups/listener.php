<?php

include_once '../helpers/env.php';
include_once '../helpers/host-status.php';
include_once '../helpers/http-response.php';
include_once '../helpers/request-handler.php';

const BASE_DIR = __DIR__;
const CONTROLLERS_DIR = __DIR__ . '/controllers';
const TOKENS_DIR = __DIR__ . '/tokens';

$request = [
    'method'        => $_SERVER['REQUEST_METHOD'],
    'uri'           => $_SERVER['REQUEST_URI'],
    'content_type'  => $_SERVER['CONTENT_TYPE'],
    'data'          => file_get_contents("php://input"),
];

$routes = [
    'GET' => [
        '/status',                  /* @link status() */
        '/instance/backups',        /* @link instance_backups() */
    ],
    'POST' => [
        '/release-expired-tokens',  /* @link release_expired_tokens() */
        '/instance/create-token',   /* @link instance_create_token() */
        '/instance/release-token'   /* @link instance_release_token() */
    ]
];

['body' => $body, 'code' => $code] = handle_request($request, $routes);

send_http_response($body, $code);
