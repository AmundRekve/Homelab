# Redeploy runbook

How to roll out manifest changes and rotate credentials without losing data.
Run everything from the controller node (`K8s-ctrl`), from a clone of this repo.

---

## Read this first

**Two things will bite you if you just restart everything.**

**1. Database passwords are init-only.** `POSTGRES_PASSWORD` is read by the
Postgres image *only when the data directory is empty*, i.e. on first ever
start. The password is then stored inside the volume. So if you create a Secret
with a new password and restart, the app gets the new password from the Secret,
Postgres still expects the old one, and the app fails authentication. The
password must be changed **inside the running database** with `ALTER USER`.
The same applies to `NEXTCLOUD_ADMIN_PASSWORD` (use `occ` instead) and
`SPLUNK_PASSWORD`.

**2. Never `kubectl delete -f` a `*-storage.yaml`.** Those files contain the
PersistentVolumeClaims. Longhorn's default reclaim policy is `Delete`, so
removing a PVC destroys the volume — every Nextcloud file, both databases.
Redeploying means `apply` + `rollout restart`, never `delete` + `apply`.

---

## Step 0 — snapshot first

In the Longhorn UI (`:30772`) → Volume → select → **Take Snapshot** for:

| Namespace | PVC |
|---|---|
| nextcloud | `postgres-pvc`, `nextcloud-pvc` |
| wger | `wger-postgres-pvc`, `wger-media-pvc` |
| splunk | `splunk-etc-pvc`, `splunk-var-pvc` |

```sh
kubectl get pvc -A                       # confirm all Bound before touching anything
kubectl get pods -A --field-selector=status.phase!=Running
```

## Step 1 — generate and store the new passwords

```sh
NC_DB=$(openssl rand -base64 24)
NC_ADMIN=$(openssl rand -base64 24)
WG_DB=$(openssl rand -base64 24)
WG_KEY=$(openssl rand -base64 50)
printf 'nextcloud db : %s\nnextcloud adm: %s\nwger db      : %s\nwger key     : %s\n' \
  "$NC_DB" "$NC_ADMIN" "$WG_DB" "$WG_KEY"
```

**Put these in your password manager now.** Once the shell closes they are gone,
and the Nextcloud admin password cannot be read back out of the cluster.

## Step 2 — create the Secrets

`--dry-run=client | kubectl apply` makes this idempotent — it works whether or
not the Secret already exists, and is re-runnable.

```sh
kubectl -n nextcloud create secret generic nextcloud-secret \
  --from-literal=POSTGRES_PASSWORD="$NC_DB" \
  --from-literal=NEXTCLOUD_ADMIN_PASSWORD="$NC_ADMIN" \
  --dry-run=client -o yaml | kubectl apply -f -

kubectl -n wger create secret generic wger-secret \
  --from-literal=POSTGRES_PASSWORD="$WG_DB" \
  --from-literal=SECRET_KEY="$WG_KEY" \
  --dry-run=client -o yaml | kubectl apply -f -

# splunk-secret already exists — leave it alone unless you also plan to reset
# the Splunk admin password inside Splunk itself (see Step 6).
kubectl -n splunk get secret splunk-secret
```

## Step 3 — change the password inside each database

Passed on stdin rather than as an argument, so it does not appear in the pod's
process list.

```sh
kubectl -n nextcloud exec -i deploy/postgres -- psql -U nextcloud -d nextcloud <<SQL
ALTER USER nextcloud WITH PASSWORD '$NC_DB';
SQL

kubectl -n wger exec -i deploy/postgres -- psql -U wger -d wger <<SQL
ALTER USER wger WITH PASSWORD '$WG_DB';
SQL
```

(The local unix socket is `trust` in the official Postgres image, so no password
is needed to get in.)

From this moment the running apps cannot open **new** database connections —
their pods still hold the old password. Continue straight to Step 4.

## Step 4 — apply the manifests

```sh
kubectl apply -R -f kubernetes/
```

Safe to run against the whole tree: the Secret templates are named
`*-secret.yaml.example`, and a directory walk only reads `.yaml`, `.yml` and
`.json`.

## Step 5 — restart, database first

The Postgres and Nextcloud Deployments use `strategy: Recreate`, so the old pod
terminates fully before the new one starts — required, since their Longhorn PVCs
are `ReadWriteOnce`. Expect a few seconds of downtime per service.

```sh
# nextcloud
kubectl -n nextcloud rollout restart deploy/postgres
kubectl -n nextcloud rollout status  deploy/postgres --timeout=180s
kubectl -n nextcloud rollout restart deploy/nextcloud
kubectl -n nextcloud rollout status  deploy/nextcloud --timeout=300s

# wger
kubectl -n wger rollout restart deploy/postgres
kubectl -n wger rollout status  deploy/postgres --timeout=180s
kubectl -n wger rollout restart deploy/redis deploy/wger deploy/celery
kubectl -n wger rollout status  deploy/wger --timeout=300s

# homepage (config change only)
kubectl -n homepage rollout restart deploy/homepage
```

Setting `SECRET_KEY` invalidates every existing wger session — everyone is
logged out once. That is expected.

## Step 6 — reset the application-level admin passwords

```sh
# Nextcloud: the env var is init-only, occ is the real path. Prompts for input.
kubectl -n nextcloud exec -it deploy/nextcloud -- \
  su -s /bin/sh www-data -c "php occ user:resetpassword admin"

# Splunk, only if you rotated splunk-secret:
kubectl -n splunk exec -it deploy/splunk -- \
  /opt/splunk/bin/splunk edit user admin -password 'NEW' -auth admin:OLD
```

## Step 7 — verify

```sh
# nothing stuck
kubectl get pods -A --field-selector=status.phase!=Running

# no plaintext credentials left in any running pod spec
kubectl get deploy -A -o json | grep -iE '"value": *"(admin|wger|nextcloud)"' \
  && echo "STILL PLAINTEXT" || echo "clean"

# debug mode is off
kubectl -n wger get deploy wger \
  -o jsonpath='{.spec.template.spec.containers[0].env[?(@.name=="DJANGO_DEBUG")].value}{"\n"}'

# management port is no longer on a LoadBalancer IP
kubectl -n splunk get svc            # splunk -> 8000,8088 only; splunk-mgmt -> ClusterIP

# apps actually reached their databases
kubectl -n wger      logs deploy/wger      --tail=30
kubectl -n nextcloud logs deploy/nextcloud --tail=30
```

Then open each service from Homepage and log in with the new credentials.

## If something breaks

```sh
kubectl -n <ns> describe pod -l app=<app>     # events: mount, image pull, probes
kubectl -n <ns> logs deploy/<app> --previous  # logs from the crashed instance
```

- `password authentication failed` → the Secret and the database disagree.
  Re-run Step 3 with the value that is actually in the Secret:
  `kubectl -n <ns> get secret <name> -o jsonpath='{.data.POSTGRES_PASSWORD}' | base64 -d`
- `CreateContainerConfigError` → the Secret or one of its keys is missing.
  `kubectl -n <ns> get secret <name> -o jsonpath='{.data}'`
- Pod stuck `ContainerCreating` with a volume error → the old pod still holds the
  ReadWriteOnce PVC. Wait for it to terminate; check `kubectl get volumeattachment`.
- Worst case, restore the Longhorn snapshot from Step 0.
