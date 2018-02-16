FROM mongo

RUN mkdir -p /var/run/mongodb && chown -R {{ mongodb.user }}.{{ mongodb.group }} /var/run/mongodb

COPY mongod.conf /etc

CMD ["--config", "/etc/mongod.conf" ]
