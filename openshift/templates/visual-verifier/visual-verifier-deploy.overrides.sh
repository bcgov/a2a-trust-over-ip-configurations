#!/bin/bash
_includeFile=$(type -p overrides.inc)
_ocFunctions=$(type -p ocFunctions.inc)
if [ ! -z ${_includeFile} ]; then
  . ${_ocFunctions}
  . ${_includeFile}
else
  _red='\033[0;31m'; _yellow='\033[1;33m'; _nc='\033[0m'; echo -e \\n"${_red}overrides.inc could not be found on the path.${_nc}\n${_yellow}Please ensure the openshift-developer-tools are installed on and registered on your path.${_nc}\n${_yellow}https://github.com/BCDevOps/openshift-developer-tools${_nc}"; exit 1;
fi

OUTPUT_FORMAT=json


# Generate application config map
# - To include all of the files in the application instance's profile directory.
# Injected by genDepls.sh
# - APP_CONFIG_MAP_NAME
# - SUFFIX
# - DEPLOYMENT_ENV_NAME

# Combine the profile's default config files with its environment specific config files before generating the config map ...
profileRoot=$( dirname "$0" )/config/${PROFILE}
profileEnv=${profileRoot}/${DEPLOYMENT_ENV_NAME}
profileTmp=$( dirname "$0" )/config/${PROFILE}/tmp
mkdir -p ${profileTmp}
cp -f ${profileRoot}/* ${profileTmp} 2>/dev/null
cp -f ${profileEnv}/* ${profileTmp} 2>/dev/null

# Generate the config map ...
APPCONFIG_SOURCE_PATH=${profileTmp}
APPCONFIG_OUTPUT_FILE=${APP_CONFIG_MAP_NAME}-configmap_DeploymentConfig.json
printStatusMsg "Generating ConfigMap; ${APP_CONFIG_MAP_NAME} ..."
generateConfigMap "${APP_CONFIG_MAP_NAME}${SUFFIX}" "${APPCONFIG_SOURCE_PATH}" "${OUTPUT_FORMAT}" "${APPCONFIG_OUTPUT_FILE}"

# Remove temporary configuration directory and files ....
rm -rf ${profileTmp}
unset SPECIALDEPLOYPARMS

# ================================================================================================================
# Special deployment parameters needed for injecting a user supplied settings into the deployment configuration
# ----------------------------------------------------------------------------------------------------------------
if createOperation; then
  # Ask the user to supply the sensitive parameters ...
  readParameter "OIDC_RP_PROVIDER_ENDPOINT - Please provide the URL for your VC OIDC Identty Provider.  The value may not be blank:" OIDC_RP_PROVIDER_ENDPOINT "" "false"
  readParameter "OIDC_RP_CLIENT_ID - Please provide your OIDC Identty Provider client id. This value must match the client id in your Identity Provider.  The value may not be blank:" OIDC_RP_CLIENT_ID "" "false"
  readParameter "OIDC_RP_CLIENT_SECRET - Please provide your OIDC Identty Provider client secret. This value must match the client secret in your Identity Provider.  If left blank, a 32 character long base64 encoded value will be randomly generated using openssl:" OIDC_RP_CLIENT_SECRET $(generateKey 32) "false"
  readParameter "VC_AUTHN_PRES_REQ_CONF_ID - Please provide the presentation request configuration id to be used when authenticating.  The value may not be blank:" VC_AUTHN_PRES_REQ_CONF_ID "" "false"
  readParameter "OIDC_CLAIMS_REQUIRED - Please provide the list of claims to be checked by the verifier as a comma-separated list of values.    The value may not be blank:" OIDC_CLAIMS_REQUIRED "" "false"
else
  # Secrets are removed from the configurations during update operations ...
  printStatusMsg "Update operation detected ...\nSkipping the prompts for OIDC_RP_PROVIDER_ENDPOINT, OIDC_RP_CLIENT_ID, OIDC_RP_CLIENT_SECRET, VC_AUTHN_PRES_REQ_CONF_ID, and OIDC_CLAIMS_REQUIRED secrets ... \n"
  writeParameter "OIDC_RP_PROVIDER_ENDPOINT" "prompt_skipped" "false"
  writeParameter "OIDC_RP_CLIENT_ID" "prompt_skipped" "false"
  writeParameter "OIDC_RP_CLIENT_SECRET" "prompt_skipped" "false"
  writeParameter "VC_AUTHN_PRES_REQ_CONF_ID" "prompt_skipped" "false"
  writeParameter "OIDC_CLAIMS_REQUIRED" "prompt_skipped" "false"
fi

SPECIALDEPLOYPARMS="--param-file=${_overrideParamFile}"
echo ${SPECIALDEPLOYPARMS}