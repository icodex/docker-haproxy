#!/bin/bash
set -x

if [ $WEB_HOST ]; then
BACKEND_TMP=/tmp/_backend.conf

echo -e ${WEB_HOST}|tr ';' '\n' > ${BACKEND_TMP}

cat /usr/local/etc/haproxy/_global.cfg > /usr/local/etc/haproxy/haproxy.cfg
cat /usr/local/etc/haproxy/_frontend.cfg >> /usr/local/etc/haproxy/haproxy.cfg

cat >> /usr/local/etc/haproxy/haproxy.cfg <<END
#-----------------------------------------------------------------------------
# default backend - parking
#-----------------------------------------------------------------------------

backend bk-default
    mode   http
    option forwardfor
    option http-pretend-keepalive
    dynamic-cookie-key MYKEY
    cookie SRVID insert dynamic
    http-request set-header X-Forwarded-Port %[dst_port]
    http-request add-header X-Forwarded-Proto https if { ssl_fc }
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
