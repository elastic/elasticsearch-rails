#!/bin/bash

curl https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-${ELASTICSEARCH_VERSION}-linux-x86_64.tar.gz | tar xz -C /tmp

echo "Starting elasticsearch on port ${TEST_CLUSTER_PORT}"
/tmp/elasticsearch-${ELASTICSEARCH_VERSION}/bin/elasticsearch -E http.port=${TEST_CLUSTER_PORT} &> /dev/null &
