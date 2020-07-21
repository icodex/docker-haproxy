#!/bin/bash
set -x

if [ $BACKEND ]; then
BACKEND_TMP=/tmp/_backend.conf

echo -e ${BACKEND}|tr ';' '\n' > ${BACKEND_TMP}

cat /usr/local/etc/haproxy/_global.cfg > /usr/local/etc/haproxy/haproxy.cfg
cat /usr/local/etc/haproxy/_frontend.cfg >> /usr/local/etc/haproxy/haproxy.cfg

cat >> /usr/local/etc/haproxy/haproxy.cfg <<END
#-----------------------------------------------------------------------------
# default backend - parking
#-----------------------------------------------------------------------------

backend bk-default
    mode   http
    option httpchk
    http-check send meth HEAD uri / ver HTTP/1.1 hdr Host localhost
    option http-pretend-keepalive
    option http-use-htx
    option forwardfor
    compression algo gzip
    compression type text/html text/plain text/css
    retry-on all-retryable-errors
    http-request disable-l7-retry if METH_POST
    acl cloudy src 103.21.244.0/22 103.22.200.0/22 103.31.4.0/22 104.16.0.0/12 108.162.192.0/18 131.0.72.0/22 141.101.64.0/18 162.158.0.0/15 172.64.0.0/13 173.245.48.0/20 188.114.96.0/20 190.93.240.0/20 197.234.240.0/22 198.41.128.0/17 2400:cb00::/32 2405:b500::/32 2606:4700::/32 2803:f800::/32 2c0f:f248::/32 2a06:98c0::/29
    http-request set-header X-Client-IP %[req.hdr(CF-Connecting-IP)] if cloudy
    http-request set-header X-Client-IP %[src] if !cloudy
    http-request set-header X-Forwarded-Port %[dst_port]
    http-request set-header X-Forwarded-Proto https if { ssl_fc }
    http-request set-header X-Forwarded-For %[src]
    http-request set-header X-Client-IP %[src]
    dynamic-cookie-key MYKEY
    cookie ICID insert dynamic httponly
END

ORDER=1
while read LINE
do
cat >> /usr/local/etc/haproxy/haproxy.cfg <<END
    server default ${LINE} check
END
ORDER=$(($ORDER+1))
done < ${BACKEND_TMP}

cat /usr/local/etc/haproxy/_end.cfg >> /usr/local/etc/haproxy/haproxy.cfg
fi

# first arg is `-f` or `--some-option`
if [ "${1#-}" != "$1" ]; then
		set -- haproxy "$@"
	fi

	if [ "$1" = 'haproxy' ]; then
		shift # "haproxy"
		#if the user wants "haproxy", let's add a couple useful flags
		#   -W  -- "master-worker mode" (similar to the old "haproxy-systemd-wrapper"; allows for reload via "SIGUSR2")
		#   -db -- disables background mode
		set -- haproxy -W -db "$@"
	fi

exec "$@"
