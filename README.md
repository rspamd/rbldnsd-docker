## Docker image for rbldnsd

### Basic usage

~~~
docker run -v `pwd`/config:/etc/rbldnsd -ti rspamd/rbldnsd -- example.com:generic:/etc/rbldnsd/dummy.zone
~~~

Arguments should be passed as needed to `rbldnsd` on startup as needed; zone files should be stored somewhere, in the example above bind mounts are used.
