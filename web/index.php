<?php
include('Authen.inc');
echo get_include_path();

require 'vendor/autoload.php';

use Prometheus\CollectorRegistry;
use Prometheus\Storage\InMemory;

$adapter = new InMemory();
$registry = new CollectorRegistry($adapter);

$counter = $registry->registerCounter('example', 'requests_total', 'help', ['method']);
$counter->incBy(1, ['GET']);

if ($_SERVER['REQUEST_URI'] === '/metrics') {
    header('Content-Type: text/plain');
    echo $registry->render();
    exit;
}

echo "Hello, World!";
