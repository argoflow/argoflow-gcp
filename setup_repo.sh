#!/bin/bash

if [ -z "$1" ]
    then
        echo "no repo URL provided, using upstream"
    else
        yq e -i ".spec.source.repoURL = \"$1\"" distribution/kubeflow.yaml
        for filename in ./distribution/argocd-applications/*.yaml; do
            yq e -i ".spec.source.repoURL = \"$1\"" $filename
        done
fi

if [ -z "$2" ]
    then
        echo "no target branch provided, using HEAD"
    else
        yq e -i ".spec.source.targetRevision = \"$2\"" distribution/kubeflow.yaml
        for filename in ./distribution/argocd-applications/*.yaml; do
            yq e -i ".spec.source.targetRevision = \"$2\"" $filename
        done
fi
