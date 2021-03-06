#!/bin/sh

# load config
if [ -f /opt/cloudconductor/config ]; then
  source /opt/cloudconductor/config
fi

if [ -n "${STACK_NAME}" -a -n "${RESOURCE_NAME}" ]; then

  # calculate bootsrap-expect from metadata
  CLUSTER_ADDRESSES=$(cfn-get-metadata -s ${STACK_NAME} -r ${RESOURCE_NAME} --region ${REGION} | jq .ClusterAddresses | sed -e 's/"\([^"]*\)"/\1/')
  FRONTEND=$(cfn-get-metadata -s ${STACK_NAME} -r ${RESOURCE_NAME} --region ${REGION} | jq .Frontend | sed -e 's/"\([^"]*\)"/\1/')

  JOIN_ADDRESSES=""
  BOOTSTRAP_EXPECT=0

  OldIFS=$IFS
  IFS=','
  for JOIN_ADDRESS in $CLUSTER_ADDRESSES;
  do
    BOOTSTRAP_EXPECT=$(expr $BOOTSTRAP_EXPECT + 1)
    JOIN_ADDRESSES="${JOIN_ADDRESSES} -join ${JOIN_ADDRESS}"
  done

  OPTIONS="-server -client 0.0.0.0 ${JOIN_ADDRESSES}"

  if [ -n "$FRONTEND" -a "$FRONTEND" = "true" ]; then
    OPTIONS="$OPTIONS -bootstrap-expect ${BOOTSTRAP_EXPECT}"
  fi

  IFS=$OldIFS

else
  OPTIONS="-server -client 0.0.0.0"
  if [ -n "${BOOTSTRAP_EXPECT}" ]; then
    OPTIONS="$OPTIONS -bootstrap-expect ${BOOTSTRAP_EXPECT}"
  else
    OPTIONS="$OPTIONS -bootstrap"
  fi

  if [ -n "${CLUSTER_ADDRESSES}" ]; then
    JOIN_ADDRESSES=""
    OldIFS=$IFS
    IFS=', '
    for JOIN_ADDRESS in $CLUSTER_ADDRESSES;
    do
      JOIN_ADDRESSES="${JOIN_ADDRESSES} -join ${JOIN_ADDRESS}"
    done
    IFS=$OldIFS

    OPTIONS="$OPTIONS ${JOIN_ADDRESSES}"
  fi
fi

echo OPTIONS=$OPTIONS > /etc/sysconfig/consul-options
