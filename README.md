# Deploying Kubeflow with Argo CD

This repository contains Kustomize manifests that point to the upstream
manifest of each Kubeflow component and provides an easy way for people
to change their deployment according to their need.
Argo CD application manifests for each componenet will be used to
deploy Kubeflow. The intended usage is for people to fork this
repository, make their desired kustomizations, run a script to
change the Argo CD application specs to point to their fork
of this repository, and finally apply a master Argo CD application
that will deploy all other applications.

To run the below script [yq](https://github.com/mikefarah/yq)
version 4 must be installed

* Overview of the steps:
  - Fork this repo
  - Modify the kustomizations for your purpose
  - Run `./setup_repo.py -c ./examples/setup.conf`
  - Commit and push your changes
  - Install Argo CD in your Kubernetes cluster
  - Run `kubectl apply -f distribution/kubeflow.yaml`

## Prerequisites

* [yq](https://github.com/mikefarah/yq)
* [kubeseal](https://github.com/bitnami-labs/sealed-secrets)
* Python `3.8+`
* Python libraries: `pip install bcrypt passlib`

### Root files

* [kustomization.yaml](./distribution/kustomization.yaml):
  - Kustomization file that references the
    Argo CD application files in
    [argocd-applications](./distribution/argocd-applications)
* [kubeflow.yaml](./distribution/kubeflow.yaml):
  - Argo CD application that deploys the
    Argo CD applications referenced in
    [kustomization.yaml](./distribution/kustomization.yaml)

## Installing Argo CD

For this installation the HA version of Argo CD is used.
Due to Pod Tolerations, 3 nodes will be required for this installation.
If you do not wish to use a HA installation of Argo CD,
edit this [kustomization.yaml](./distribution/argocd/base/kustomization.yaml)
and remove `/ha` from the URI.

1. Next, to install Argo CD execute the following command:

  ```bash
  kubectl apply -k distribution/argocd/base/
  ```

2. Install the Argo CD CLI tool from
   [here](https://argo-cd.readthedocs.io/en/stable/cli_installation/)

> **Note**: Argo CD needs to be able access your repository
  to deploy applications. If the fork of this repository that
  you are planning to use with Argo CD is private you will
  need to add credentials so it can access the repository.
  Please see the instructions provided by Argo CD
  [here](https://argo-cd.readthedocs.io/en/stable/user-guide/private-repositories/).

## Installing Kubeflow

* The purpose of this repository is to make it easy for people
  to customize their Kubeflow deployment and have it managed
  through a GitOps tool like Argo CD.
  - First, fork this repository and clone your fork locally.
  - Next, apply any customization you require in the kustomize
    folders of the Kubeflow applications.
  - Next will follow a set of recommended changes that
    we encourage everybody to make.

### Ingress and Certificate

By default the Istio Ingress Gateway is setup to use a
LoadBalancer and to redirect HTTP traffic to HTTPS.

If you do not wish to use a LoadBalancer, change the `spec.type` in
[gateway-service.yaml](./distribution/istio/gateway-service.yaml)
to `NodePort`.

To provide HTTPS out-of-the-box, the `kubeflow-self-signing-issuer`
used by internal Kubeflow applications is setup to provide a
certificate for the Istio Ingress Gateway.

To use a different certificate for the Ingress Gateway,
change the `spec.issuerRef.name` to the cert-manager
ClusterIssuer you would like to use in
[ingress-certificate.yaml](./distribution/istio/ingress-certificate.yaml)
and set the `spec.commonName` and `spec.dnsNames[0]` to your Kubeflow domain.

If you would like to use LetsEncrypt, a ClusterIssuer template if provided in
[lets-encrypt-dns-01](./distribution/cert-manager/overlays/lets-encrypt-dns-01).

### Change Argo CD application specs and commit

To simplify the process of telling Argo CD to use your fork
of this repo, a script is provided that updates the
`spec.source.repoURL` and `spec.source.targetRevision` of
all the Argo CD application specs.

```bash
./setup_repo.py -c ./examples/setup.conf
```

To change what Kubeflow or third-party componenets are
included in the deployment, edit the
[root kustomization.yaml](./distribution/kustomization.yaml)
and comment or uncomment the components you do or don't want.

Next, commit your changes and push them to your repository.

### Deploying Kubeflow

Once you've commited and pushed your changes to your repository,
you can either choose to deploy componenet individually or
deploy them all at once.

To deploy everything specified in the root
[kustomization.yaml](./distribution/kustomization.yaml), execute:

```bash
kubectl apply -f distribution/kubeflow.yaml
```

After this, you should start seeing applications being deployed in
the Argo CD UI and what the resources each application create.

### Generate credentials

```bash
email=test@demo.me username=test password=test ./setup_credentials.sh
```

### Updating the deployment

By default, all the Argo CD application specs included here are
setup to automatically sync with the specified repoURL.
If you would like to change something about your deployment,
simply make the change, commit it and push it to your fork
of this repo. Argo CD will automatically detect the changes
and update the necessary resources in your cluster.

### Customizing the Jupyter Web App

To customize the list of images presented in the Jupyter Web App
and other related setting such as allowing custom images, edit the
[spawner_ui_config.yaml](./distribution/kubeflow/notebooks/jupyter-web-app/spawner_ui_config.yaml) file.

### Accessing the Argo CD UI

1. Access the Argo CD UI by exposing it through a
   LoadBalander, Ingress or by port-fowarding using

  ```bash
  kubectl port-forward svc/argocd-server -n argocd 8080:443
  ```

2. Login to the Argo CD CLI. First get the default password
   for the `admin` user:

  ```bash
  kubectl get secret argocd-initial-admin-secret \
    -n argocd \
    -o jsonpath="{.data.password}" | base64 -d
  ```

  - Next, login with the following command:

    ```bash
    argocd login <ARGOCD_SERVER>  # e.g. localhost:8080 or argocd.example.com
    ```

  - Finally, update the account password with:

    ```bash
    argocd account update-password
    ```

3. You can now login to the Argo CD UI with your new password.
   This UI will be handy to keep track of the created resources
   while deploying Kubeflow.
