#!/bin/bash

# --------------------------------------------
# Options that must be configured by app owner
# --------------------------------------------
APP_NAME="sources"  # name of app-sre "application" folder this component lives in
COMPONENT_NAME="sources-monitor"  # name of app-sre "resourceTemplate" in deploy.yaml for this component
IMAGE="quay.io/cloudservices/sources-monitor"

IQE_PLUGINS="sources"
IQE_MARKER_EXPRESSION="sources_smoke"
IQE_FILTER_EXPRESSION=""


# Install bonfire repo/initialize
CICD_URL=https://raw.githubusercontent.com/RedHatInsights/bonfire/master/cicd
curl -s $CICD_URL/bootstrap.sh -o bootstrap.sh
source bootstrap.sh  # checks out bonfire and changes to "cicd" dir...

source build.sh
source deploy_ephemeral_env.sh
source smoke_test.sh
