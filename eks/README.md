## Voting application on EKS

This directory contains Kubernetes manifests for the voting application, Redis, and PostgreSQL.

### Prerequisites

- An EKS cluster and a configured `kubectl` context for the target namespace.
- A default StorageClass that provisions persistent block storage, or configure the PVC with an appropriate StorageClass before deploying.
- On EKS, EBS-backed PVCs require the AWS EBS CSI driver and its required IAM permissions. The existing claim requests `ReadWriteOnce` storage. With no `storageClassName` set, Kubernetes uses the default StorageClass.
- The `postgres-credentials` Secret described below must exist in the namespace before the PostgreSQL Deployment is created.

Kubernetes Secret objects are not encrypted merely because they are Secrets; values are base64-encoded in the API representation. Restrict access with least-privilege RBAC, and configure encryption at rest (for example, EKS envelope encryption with AWS KMS) when required by your security policy.

### Create the PostgreSQL Secret

Create the values file outside the repository, using a secure local editor. Do not paste a password into a command or commit the file. The file should contain the keys `username` and `password`, each assigned its locally chosen value.

On macOS or Linux:

```sh
umask 077
SECRET_FILE="$(mktemp)"
"${EDITOR:-vi}" "$SECRET_FILE"
# Enter username=... and password=... in the editor, then save and exit.
kubectl create secret generic postgres-credentials \
  --from-env-file="$SECRET_FILE" --dry-run=client -o yaml |
  kubectl apply -f -
rm -f "$SECRET_FILE"
unset SECRET_FILE
```

The local file is created with owner-only permissions by `umask 077`. Remove it after creating the Secret, and ensure shell history or editor backups do not retain sensitive values. The Deployment reads the Secret's `username` and `password` keys as `POSTGRES_USER` and `POSTGRES_PASSWORD`.

### Deploy and verify

Create the Secret first, then apply the manifests:

```sh
kubectl apply -f eks/deployment.yaml
kubectl get pods
kubectl get pvc postgres-pv-claim
kubectl describe pvc postgres-pv-claim
kubectl rollout status deployment/db
kubectl rollout status deployment/redis
```

Check readiness and recent probe or storage errors:

```sh
kubectl get pods -o wide
kubectl describe pod -l app=db
kubectl describe pod -l app=redis
kubectl get events --sort-by=.lastTimestamp
```

The PostgreSQL PVC should reach `Bound`; the PostgreSQL and Redis pods should become `Ready`. If the claim remains `Pending`, check that a suitable default StorageClass and EBS CSI provisioner are available in the cluster.

The PostgreSQL probes call `pg_isready` with the configured `POSTGRES_USER`. Redis probes use `redis-cli ping`. No health probes are added to the application containers.

These instructions describe the intended setup only. The manifest changes have not been applied to a live EKS cluster, and no AWS resources were created or inspected.
