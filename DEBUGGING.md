How to build and debug the module in gdb:
```
$ cd nginx-1.18.0
$ make && make install
$ db /opt/nginx/bin/nginx
(gdb) break ngx_http_cache_purge_conf
(gdb) run -g 'daemon off'
```
GDB will now break in the code that parses the module's configuration.
If this seems to be working fine, continue.

To debug a request, open a second terminal, find the pid of the worker
process, then attach to it in a new gdb session:
```
$ ps aux | grep 'nginx: worker
    output follows, read the pid from it, e.g. 12345
$ gdb /opt/nginx/bin/nginx
$ break ngx_http_proxy_cache_purge_handler
$ attach 12345 /* the pid you found with ps */
$ continue
```

Now open a third terminal and make a PURGE requests:
```
$ curl -X PURGE http://127.0.0.1:8080/info.php
```
The worker process will now be stopped in gdb, allowing you to debug it.

