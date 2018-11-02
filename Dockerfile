FROM haproxy:latest

ADD ./haproxy_conf.tar.gz /usr/local/etc/haproxy/

EXPOSE 80 443

COPY ./docker-entrypoint.sh /
RUN chmod +x /docker-entrypoint.sh

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["haproxy", "-f", "/usr/local/etc/haproxy/haproxy.cfg"]
