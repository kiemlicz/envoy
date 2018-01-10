FROM redis
RUN mkdir -p /usr/local/etc/redis/ && touch /usr/local/etc/redis/redis.conf
RUN echo "cluster-enabled yes" > /usr/local/etc/redis/redis.conf && \
    echo "cluster-config-file nodes.conf" >> /usr/local/etc/redis/redis.conf
CMD [ "redis-server", "/usr/local/etc/redis/redis.conf" ]
