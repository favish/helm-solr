# helm-solr

Helm chart for running Apache Solr on Kubernetes as a single-node StatefulSet
with a persistent volume. Used by favish Drupal projects as the search backend
for `search_api_solr`, and consumable by any project that needs a barebones Solr.

Published to `https://favish.github.io/helm-solr` and consumed as a chart
dependency. Shared, public chart: the default stays on stock Solr so non-Drupal
and other-version consumers are unaffected; the Drupal config set is opt-in.

## Contents

- [What it deploys](#what-it-deploys)
- [Layout](#layout)
- [Usage](#usage)
- [Using it with Drupal](#using-it-with-drupal)
- [Key values](#key-values)
- [Releasing](#releasing)
- [Local checks](#local-checks)
- [Conventions (agents & contributors)](#conventions-agents--contributors)
- [Pending improvements](#pending-improvements)

## What it deploys

A `StatefulSet` (single replica) backed by a `volumeClaimTemplates` PVC, fronted
by a headless `Service` named `solr`. The container command raises the open-file
and process ulimits to 65000 (clamped to the host hard limit) before exec'ing the
Solr entrypoint, then `solr-precreate` creates the core on first start.

Chart-level usage detail lives in [`solr/README.md`](solr/README.md).

## Layout

```
solr/                            # the chart
├── Chart.yaml                   # metadata (version injected at release time)
├── values.yaml                  # defaults, documented inline
├── README.md                    # chart usage + Drupal opt-in
└── templates/
    ├── statefulset.yaml         # Solr pod + PVC + probes
    ├── service.yaml             # headless Service `solr`
    └── _helpers.tpl             # fullname helper
.github/workflows/release.yml    # tag -> publish chart
CHANGELOG.md
```

## Usage

Declare the dependency in the consuming umbrella chart:

```yaml
dependencies:
  - name: solr
    repository: https://favish.github.io/helm-solr
    version: 2.2.0
    condition: solr.enabled
```

```bash
helm dependency update ./your-umbrella-chart
```

Default install runs stock `solr:9.10.1`.

## Using it with Drupal

Stock Solr creates the core with Solr's `_default` schema, which
`search_api_solr` rejects — every query fails with `undefined field …`. For a
Drupal project, point the image and `execArgs` at the shared image that bakes the
Drupal config set (built from `favish/docker-images`, `solr-9/drupal-10`):

```yaml
solr:
  image: "favish/solr-9-drupal-10:1.0"
  execArgs: ["solr-precreate", "drupal", "/opt/solr-conf"]
```

That image also bakes the required Solr modules
(`extraction,langid,analysis-extras,ltr`), so no extra `SOLR_OPTS` is needed for
the schema to load. The baked schema is generated for a specific Drupal /
`search_api_solr` version, which is why it is opt-in rather than the chart
default.

## Key values

| Value | Default | Meaning |
|-------|---------|---------|
| `image` | `solr:9.10.1` | Solr image. Override for the Drupal-baked image. |
| `execArgs` | `["solr-precreate","drupal"]` | Entrypoint args; point at `/opt/solr-conf` for the Drupal config set. |
| `storage` | `1Gi` | PVC size (immutable on an existing StatefulSet). |
| `storageClassName` | `""` (cluster default) | Optional PVC storage class. |
| `resources` | req 512Mi / limit 1Gi | Container resources. **Keep heap inside the limit.** |
| `env.SOLR_JAVA_MEM` | `-Xms512m -Xmx512m` | JVM heap; size with the memory request/limit. |
| `command` | ulimit wrapper | Raises ulimits, then exec's the Solr entrypoint. |

Full commented reference: `solr/values.yaml`. The StatefulSet ships a
`startupProbe` (slow-JVM cold start), `livenessProbe` and `readinessProbe`
(`/solr/admin/info/system`).

## Releasing

GitHub Actions (`.github/workflows/release.yml`). Merge to `master`, update
`CHANGELOG.md`, then tag:

```bash
git tag 2.3.0 && git push origin 2.3.0
```

The workflow packages the chart (stamping the tag as the chart version) and
publishes to the `gh-pages` Helm repo. `workflow_dispatch` runs a dry-run.

Migrated from CircleCI to remove the SSH-deploy-key dependency;
`actions/checkout` uses the built-in `GITHUB_TOKEN`.

## Local checks

```bash
helm lint ./solr

cp solr/Chart.yaml /tmp/c.bak
printf '\nversion: 0.0.0-test\n' >> solr/Chart.yaml
helm template t ./solr
helm template t ./solr --set storageClassName=fast-ssd   # verify gated values
cp /tmp/c.bak solr/Chart.yaml
```

## Conventions (agents & contributors)

- Default stays stock Solr; the Drupal image is opt-in (its schema is
  version-specific). Do not make it the default — it would break other
  consumers.
- Chart `version` is injected from the git tag at release; not in `Chart.yaml`.
  Local renders need a temporary version stamp (above).
- `spec.serviceName` and the `solr` Service name are load-bearing: consumers
  connect to host `solr`. Do not rename without auditing every consumer.
- Heap (`SOLR_JAVA_MEM`) must fit inside the memory limit with headroom for
  Lucene's off-heap mmap. Size heap and resources together.

## Pending improvements

- `spec.serviceName` resolves to the chart fullname while the Service is named
  `solr`, so per-pod StatefulSet DNS does not resolve. Harmless at one replica
  (clients hit the `solr` Service directly), but fix before scaling >1 — and note
  `serviceName` is immutable on an existing StatefulSet.
- No `runAsNonRoot` / `runAsUser` in the pod security context (only `fsGroup`).
  Add for Pod Security Standards `restricted`, but gate it so root-based image
  consumers are not broken.
- `replicas` is hardcoded to 1; this is a non-SolrCloud single-core chart, so
  scaling >1 needs ZooKeeper/SolrCloud, not just a replica bump.
