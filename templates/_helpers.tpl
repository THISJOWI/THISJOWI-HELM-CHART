{{/*
Generar secretos seguros automáticamente
*/}}
{{- define "thisjowi.generateSecret" -}}
{{- if . -}}
  {{- . -}}
{{- else -}}
  {{- randAlphaNum 32 | b64enc -}}
{{- end -}}
{{- end -}}

{{/*
Validar que un secreto sea seguro para producción
*/}}
{{- define "thisjowi.validateSecretLength" -}}
{{- if . -}}
  {{- if lt (len .) 32 -}}
    {{- fail "Error: El secreto debe tener mínimo 32 caracteres para seguridad" -}}
  {{- else -}}
    {{- . -}}
  {{- end -}}
{{- else -}}
  {{- randAlphaNum 32 -}}
{{- end -}}
{{- end -}}

{{/*
Nombre del chart
*/}}
{{- define "thisjowi.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Chart labels
*/}}
{{- define "thisjowi.labels" -}}
helm.sh/chart: {{ include "thisjowi.chart" . }}
{{ include "thisjowi.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "thisjowi.selectorLabels" -}}
app.kubernetes.io/name: {{ include "thisjowi.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Chart
*/}}
{{- define "thisjowi.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Detectar IP del nodo para Ingress
*/}}
{{- define "thisjowi.ingressHost" -}}
{{- if .Values.ingress.host }}
  {{- .Values.ingress.host -}}
{{- else if and .Values.ingress.autoDetectNodeIP -}}
  {{- $nodes := lookup "v1" "Node" "" "" -}}
  {{- if $nodes -}}
    {{- $nodeIP := (first $nodes.items).status.addresses | map(select(.type == "ExternalIP" or .type == "InternalIP")) | first | .address -}}
    {{- if .Values.ingress.useNipIO -}}
      {{- printf "%s.nip.io" $nodeIP -}}
    {{- else -}}
      {{- $nodeIP -}}
    {{- end -}}
  {{- else -}}
    localhost
  {{- end -}}
{{- else -}}
  localhost
{{- end -}}
{{- end }}
