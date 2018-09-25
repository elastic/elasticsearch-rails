#!/bin/bash

metadata_url="https://artifacts-api.elastic.co/v1/branches/master/builds/latest/projects/elasticsearch/packages/elasticsearch-${ELASTICSEARCH_VERSION}-SNAPSHOT.zip/file"
echo "Getting snapshot location from $metadata_url"

url=$(curl -v $metadata_url 2>&1 | grep -Pio 'location: \K(.*)' | tr -d '\r')

echo "Downloading Elasticsearch from $url"
curl $url -o /tmp/elasticsearch.zip

echo 'Unzipping file'
unzip -q /tmp/elasticsearch.zip

echo "Starting elasticsearch on port ${TEST_CLUSTER_PORT}"
${PWD}/elasticsearch-7.0.0-alpha1-SNAPSHOT/bin/elasticsearch -E http.port=${TEST_CLUSTER_PORT} &> /dev/null &
