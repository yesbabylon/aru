<?php

include_once '../helpers/env.php';
include_once '../helpers/host-status.php';
include_once '../helpers/http-response.php';
include_once '../helpers/request-handler.php';
include_once '../seru_admin/helpers/instances.php';

const BASE_DIR = __DIR__;
const CONTROLLERS_DIR = __DIR__ . '/controllers';
const SCRIPTS_DIR = __DIR__ . '/scripts';

$request = [
    'method'        => $_SERVER['REQUEST_METHOD'],
    'uri'           => $_SERVER['REQUEST_URI'],
    'content_type'  => $_SERVER['CONTENT_TYPE'],
    'data'          => file_get_contents("php://input"),
];

$allowed_routes = [
    '/status',                          /* @link status() */
    '/instances',                       /* @link instances() */
    '/instance/create',                 /* @link instance_create() */
    '/instance/delete',                 /* @link instance_delete() */
    '/instance/status',                 /* @link instance_status() */
    '/instance/enable-maintenance',     /* @link instance_enable_maintenance() */
    '/instance/disable-maintenance'     /* @link instance_disable_maintenance() */
];

['body' => $body, 'code' => $code] = handle_request($request, $allowed_routes);

send_http_response($body, $code);
