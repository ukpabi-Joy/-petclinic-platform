{{/*
Helper templates for petclinic-service.
*/}}

{{/*
Workload name. Honours fullnameOverride, then nameOverride, then the release
name. The per-service values files set nameOverride to the canonical service
name (e.g. "customers-service") so the rendered objects match k8s/base/.
*/}}
{{- define "petclinic-service.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else if .Values.nameOverride -}}
{{- .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{- define "petclinic-service.name" -}}
{{- include "petclinic-service.fullname" . -}}
{{- end -}}

{{/*
Selector labels — the stable identity used by the Service, PDB and Deployment
selector. Matches the base manifests' app.kubernetes.io/name selector exactly.
*/}}
{{- define "petclinic-service.selectorLabels" -}}
app.kubernetes.io/name: {{ include "petclinic-service.fullname" . }}
{{- end -}}

{{/*
Common labels applied to every object.
*/}}
{{- define "petclinic-service.labels" -}}
app.kubernetes.io/name: {{ include "petclinic-service.fullname" . }}
app.kubernetes.io/component: {{ include "petclinic-service.fullname" . }}
app.kubernetes.io/part-of: petclinic
app.kubernetes.io/managed-by: {{ .Release.Service }}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end -}}

{{/*
ServiceAccount name.
*/}}
{{- define "petclinic-service.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
{{- default (include "petclinic-service.fullname" .) .Values.serviceAccount.name -}}
{{- else -}}
{{- default "default" .Values.serviceAccount.name -}}
{{- end -}}
{{- end -}}
