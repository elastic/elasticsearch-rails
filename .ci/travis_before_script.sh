#!/bin/bash

if [ "$ELASTICSEARCH_VERSION" == "6.7.1" ]
then
    url="https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-${ELASTICSEARCH_VERSION}.tar.gz"
else
    url="https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-${ELASTICSEARCH_VERSION}-linux-x86_64.tar.gz"
fi

echo "Downloading elasticsearch from $url"
curl $url | tar xz -C /tmp

echo "Starting elasticsearch on port ${TEST_CLUSTER_PORT}"
/tmp/elasticsearch-${ELASTICSEARCH_VERSION}/bin/elasticsearch-keystore create
/tmp/elasticsearch-${ELASTICSEARCH_VERSION}/bin/elasticsearch -E http.port=${TEST_CLUSTER_PORT} &> /dev/null &
