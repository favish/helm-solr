{{/*
Create a default fully qualified app name for solr.
We truncate at 24 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "solr.fullname" -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- printf "solr-%s-%s" .Release.Name $name | trunc 24 | trimSuffix "-" -}}
{{- end -}}