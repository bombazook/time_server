# time_server
https://gist.github.com/KELiON/949731e077656ce036fa6114e7b47d2d

Single process single-threaded Ruby Fiber based http time server

To start server run
```bundle install && bundle exec bin/time_server```

By default it binds to localhost:1234

Results on i7 3770T:
```
ab -c 500 -n 50000 -s 5 -r -t 180 http://localhost:1234/time?Kaliningrad,Moscow,Petersburg
Server Software:        
Server Hostname:        localhost
Server Port:            1234

Document Path:          /time?Kaliningrad,Moscow,Petersburg
Document Length:        120 bytes

Concurrency Level:      500
Time taken for tests:   27.358 seconds
Complete requests:      50000
Failed requests:        0
Total transferred:      9300000 bytes
HTML transferred:       6000000 bytes
Requests per second:    1827.61 [#/sec] (mean)
Time per request:       273.582 [ms] (mean)
Time per request:       0.547 [ms] (mean, across all concurrent requests)
Transfer rate:          331.97 [Kbytes/sec] received

Connection Times (ms)
              min  mean[+/-sd] median   max
Connect:        0    5 229.1      0   15252
Processing:     4   59 433.4     47   26312
Waiting:        1   59 433.4     47   26312
Total:         17   64 562.7     47   27332

Percentage of the requests served within a certain time (ms)
  50%     47
  66%     49
  75%     52
  80%     53
  90%     56
  95%     58
  98%     63
  99%     67
 100%  27332 (longest request)
```

# Live demo

[time.kostrov.net](http://time.kostrov.net/time?Kaliningrad,Moscow,New_York)
