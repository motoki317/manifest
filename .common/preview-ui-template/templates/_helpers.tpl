{{/* ns-preview.trapti.tech のようなホスト名から trapti-tech という名前を構築 */}}
{{- define "auth.middleware.baseName" }}
{{- $host := .Values.host.base }}
{{- $parts := split $host "." }}
{{- $n := len $parts }}
{{- $lastTwo := slice $parts (sub $n 2) $n }}
{{- join $lastTwo "-" }}
{{- end }}
