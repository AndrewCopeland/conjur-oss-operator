# clean up the operator
oc delete -f deploy/crds/cache_v1alpha1_conjur_cr.yaml --as system:admin

oc delete -f deploy/service_account.yaml
oc delete -f deploy/role.yaml
oc delete -f deploy/role_binding.yaml
oc delete -f deploy/operator.yaml
oc delete -f deploy/crds/cache_v1alpha1_conjur_crd.yaml --as system:admin
