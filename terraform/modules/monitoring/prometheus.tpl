global:
  scrape_interval: 15s

rule_files:
  - "/etc/prometheus/rules/alerts.yml"

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  - job_name: 'node'
    static_configs:
      - targets: ['localhost:9100']

%{ if onprem_target != "" }
  - job_name: 'onprem-node'
    static_configs:
      - targets: ['${onprem_target}']
%{ endif }