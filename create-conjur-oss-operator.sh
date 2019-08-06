# prereqs 
# TODO: Find out which of these commands can be put into the operator
#	I think if the operator has ClusterRole permissions it will be able to (look into this though)

source bootstrap.env
. utils.sh

# Add conjur service account
oc create serviceaccount $CONJUR_SERVICEACCOUNT_NAME -n $CONJUR_NAMESPACE_NAME

# Add docker-registry secret
oc create secret docker-registry $SECRET_NAME --docker-server=$DOCKER_REGISTRY_PATH --docker-username=_ --docker-password=$(oc whoami -t) --docker-email=_

# delete and re-create the clusterrole
oc delete --ignore-not-found clusterrole conjur-authenticator-$CONJUR_NAMESPACE_NAME
sed -e "s#{{ CONJUR_NAMESPACE_NAME }}#$CONJUR_NAMESPACE_NAME#g" ./conjur-authenticator-role.yaml | oc apply -f -

# allow pods to run as root
oc adm policy add-scc-to-user anyuid "system:serviceaccount:$CONJUR_NAMESPACE_NAME:$CONJUR_SERVICEACCOUNT_NAME"

# Create image pull secret
oc policy add-role-to-user system:image-puller "system:serviceaccount:$CONJUR_NAMESPACE_NAME:$CONJUR_SERVICEACCOUNT_NAME" -n=default
oc policy add-role-to-user system:image-puller "system:serviceaccount:$CONJUR_NAMESPACE_NAME:$CONJUR_SERVICEACCOUNT_NAME" -n=$CONJUR_NAMESPACE_NAME


# Get image tags
conjur_image=$(platform_image "conjur")
nginx_image=$(platform_image "nginx")

# Log into docker
sudo docker login --username=admin --password=$(oc whoami -t) $DOCKER_REGISTRY_PATH

# Push conjur image to openshift repo
sudo docker pull cyberark/conjur
imageId=$(sudo docker images | grep "docker.io/cyberark/conjur " | awk '{print $3}')
sudo docker tag $imageId $conjur_image
sudo docker push $conjur_image
echo "Pushed conjur image: $conjur_image"

# Push nginx image to openshift repo
cd nginx_base
sed -e "s#{{ CONJUR_NAMESPACE_NAME }}#$CONJUR_NAMESPACE_NAME#g" proxy/ssl.conf.template > proxy/ssl.conf
sudo docker build -t $nginx_image .
sudo docker push $nginx_image
cd ..
echo "Pushed nginx image: $nginx_image"

# Create resources
oc adm policy add-scc-to-user anyuid -z default # TODO: check why
oc adm policy add-scc-to-user anyuid -z conjur-cluster # TODO: check why

# The operator section
oc create -f deploy/crds/cache_v1alpha1_conjur_crd.yaml
operator-sdk build conjur-oss-operator:v0.0.1

# create project if one is not made: oc new-project tutorial
# these commands will bring up out operator pod
oc create -f deploy/service_account.yaml
oc create -f deploy/role.yaml
oc create -f deploy/role_binding.yaml
oc create -f deploy/operator.yaml

# This will deploy the pods for the specific cr
oc create -f deploy/crds/cache_v1alpha1_conjur_cr.yaml
