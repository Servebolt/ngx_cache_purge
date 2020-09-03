# vi:filetype=perl

use lib 'lib';
use Test::Nginx::Socket;

repeat_each(1);

plan tests => repeat_each() * blocks() * 4 + 1;

our $http_config = <<'_EOC_';
    proxy_cache_path  /tmp/ngx_cache_purge_cache keys_zone=test_cache:10m;
    proxy_temp_path   /tmp/ngx_cache_purge_temp 1 2;
_EOC_

our $config = <<'_EOC_';
    location /proxy {
        proxy_pass         $scheme://127.0.0.1:$server_port/etc/passwd;
        proxy_cache        test_cache;
        proxy_cache_key    "$request_method$scheme$host$request_uri";
        proxy_cache_valid  3m;
        add_header         X-Cache-Status $upstream_cache_status;

        proxy_cache_purge PURGE cache_key "GET$scheme$host$request_uri" "HEAD$scheme$host$request_uri" from 1.0.0.0/8 127.0.0.0/8 3.0.0.0/8;
    }


    location = /etc/passwd {
        root               /;
    }
_EOC_

worker_connections(128);
no_shuffle();
run_tests();

no_diff();

__DATA__

=== TEST 0: purge empty cache
--- http_config eval: $::http_config
--- config eval: $::config
--- request
PURGE /proxy/nosuchfile
--- error_code: 412
--- response_headers
Content-Type: text/html
--- response_body_like: Precondition Failed
--- timeout: 10
--- no_error_log eval
qr/\[(warn|error|crit|alert|emerg)\]/

=== TEST 1: prepare GET passwd
--- http_config eval: $::http_config
--- config eval: $::config
--- request
GET /proxy/passwd
--- error_code: 200
--- response_headers
Content-Type: text/plain
--- response_body_like: root
--- timeout: 10
--- no_error_log eval
qr/\[(warn|error|crit|alert|emerg)\]/


=== TEST 2: prepare HEAD passwd
--- http_config eval: $::http_config
--- config eval: $::config
--- request
HEAD /proxy/passwd
--- error_code: 200
--- response_headers
Content-Type: text/plain
--- timeout: 10
--- no_error_log eval
qr/\[(warn|error|crit|alert|emerg)\]/


=== TEST 3: get from cache passwd
--- http_config eval: $::http_config
--- config eval: $::config
--- request
GET /proxy/passwd
--- error_code: 200
--- response_headers
Content-Type: text/plain
X-Cache-Status: HIT
--- response_body_like: root
--- timeout: 10
--- no_error_log eval
qr/\[(warn|error|crit|alert|emerg)\]/


=== TEST 4: head from cache passwd
--- http_config eval: $::http_config
--- config eval: $::config
--- request
HEAD /proxy/passwd
--- error_code: 200
--- response_headers
Content-Type: text/plain
X-Cache-Status: HIT
--- timeout: 10
--- no_error_log eval
qr/\[(warn|error|crit|alert|emerg)\]/


=== TEST 5: purge from cache
--- http_config eval: $::http_config
--- config eval: $::config
--- request
PURGE /proxy/passwd
--- error_code: 200
--- response_headers
Content-Type: text/html
--- response_body_like: Successful purge
--- timeout: 10
--- no_error_log eval
qr/\[(warn|error|crit|alert|emerg)\]/


=== TEST 6: get from empty cache passwd
--- http_config eval: $::http_config
--- config eval: $::config
--- request
GET /proxy/passwd
--- error_code: 200
--- response_headers
Content-Type: text/plain
X-Cache-Status: MISS
--- response_body_like: root
--- timeout: 10
--- no_error_log eval
qr/\[(warn|error|crit|alert|emerg)\]/


=== TEST 7: head from empty cache passwd
--- http_config eval: $::http_config
--- config eval: $::config
--- request
HEAD /proxy/passwd
--- error_code: 200
--- response_headers
Content-Type: text/plain
X-Cache-Status: MISS
--- timeout: 10
--- no_error_log eval
qr/\[(warn|error|crit|alert|emerg)\]/


