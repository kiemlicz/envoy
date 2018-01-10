FROM redis
RUN mkdir -p /usr/local/etc/redis/ && touch /usr/local/etc/redis/redis.conf && \
    chown -R redis.redis /usr/local/etc/redis/ && \
    mkdir -p /var/lib/redis/ && chown -R /var/lib/redis/

RUN echo "daemonize yes" > /usr/local/etc/redis/redis.conf && \
    echo "dir /var/lib/redis/" >> /usr/local/etc/redis/redis.conf && \
    echo "pidfile redis.pid" >> /usr/local/etc/redis/redis.conf && \
    echo "dbfilename dump.rdb" >> /usr/local/etc/redis/redis.conf && \
    echo "appendonly no" >> /usr/local/etc/redis/redis.conf && \
    echo "appendfilename appendonly.aof" >> /usr/local/etc/redis/redis.conf && \
    echo "cluster-enabled yes" >> /usr/local/etc/redis/redis.conf && \
    echo "cluster-config-file nodes.conf" >> /usr/local/etc/redis/redis.conf
CMD [ "redis-server", "/usr/local/etc/redis/redis.conf" ]
