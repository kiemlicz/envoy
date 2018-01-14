FROM redis

RUN mkdir -p /usr/local/etc/redis/ && \
    touch /usr/local/etc/redis/redis.conf && \
    chown -R redis.redis /usr/local/etc/redis/

COPY redis.conf /usr/local/etc/redis/

CMD [ "redis-server", "/usr/local/etc/redis/redis.conf" ]
