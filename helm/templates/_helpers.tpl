{{- define "nginx-helm.name" -}}
nginx-helm
{{- end -}}

{{- define "nginx-helm.fullname" -}}
{{ include "nginx-helm.name" . }}
{{- end -}}

