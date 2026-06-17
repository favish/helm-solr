# Apache Solr Chart

This chart provides a StatefulSet and persistent volume to run Apache Solr.

## Using with Drupal (search_api_solr)

The stock `solr:9.x` image creates the core with Solr's `_default` schema, which
`search_api_solr` rejects (every query fails with `undefined field ...`). For a
Drupal project, point the chart at the shared image that bakes the Drupal
config set, and set `execArgs` to its config path:

```yaml
image: "favish/solr-9-drupal-10:1.0"
execArgs: ["solr-precreate", "drupal", "/opt/solr-conf"]
```

That image (built from `favish/docker-images` `solr-9/drupal-10`) also bakes the
required Solr modules (`extraction,langid,analysis-extras,ltr`), so no extra
`SOLR_OPTS` is needed for the schema to load.

The baked schema is generated for a specific Drupal / `search_api_solr` version,
so the Drupal image is opt-in; the chart default stays on stock Solr to avoid
breaking non-Drupal or other-version consumers.
