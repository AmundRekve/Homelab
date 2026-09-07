# Redeploy

Rolling out manifest changes without losing data.

## Before you start

Snapshot the persistent volumes. Longhorn's default reclaim policy deletes the
underlying volume when a PVC is removed, so a redeploy is `apply` plus
`rollout restart`, never `delete` plus `apply`.

Database passwords are read from the environment only when a data directory is
first initialised. Updating a Secret does not change the password inside an
existing database, so the two have to be brought into step deliberately.

## Order

1. Create or update the Secrets the workloads reference
2. Apply the manifests
3. Restart the database Deployments and wait for them to become ready
4. Restart the application Deployments

```sh
kubectl apply -R -f kubernetes/

kubectl -n <ns> rollout restart deploy/postgres
kubectl -n <ns> rollout status  deploy/postgres --timeout=180s
kubectl -n <ns> rollout restart deploy/<app>
kubectl -n <ns> rollout status  deploy/<app> --timeout=300s
```

Workloads backed by a ReadWriteOnce volume use `strategy: Recreate`, so the old
pod terminates fully before the new one starts. Expect a few seconds of downtime
per service.

Secret templates are named `*-secret.yaml.example` on purpose. A directory walk
only reads `.yaml`, `.yml` and `.json`, so a template cannot be applied by
accident.

## Verify

```sh
kubectl get pods -A --field-selector=status.phase!=Running
kubectl -n <ns> logs deploy/<app> --tail=30
```

If a pod reports `CreateContainerConfigError`, a referenced Secret or one of its
keys is missing. If it stays in `ContainerCreating` with a volume error, the
previous pod still holds the ReadWriteOnce claim; wait for it to terminate.
