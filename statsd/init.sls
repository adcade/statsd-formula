{% set branch          = salt['pillar.get']("statsd:branch", "master") -%}
{% set service_account = salt['pillar.get']("statsd:service_account", "statsd") -%}
{% set config_path     = salt['pillar.get']("statsd:config_path", "/etc/statsd.conf") -%}
{% set install_path    = salt['pillar.get']("statsd:install_path", "/opt/statsd") -%}
{% set log_path        = salt['pillar.get']("statsd:log_path", "/var/log/statsd") -%}
{% set config          = salt['pillar.get']("statsd:config", {"graphitePort": "localhost", "graphitePort":"2003", "port":"8125"}) -%}

{% set log_file = log_path ~ '/statsd.log' %}
{% set bin_path = install_path ~ '/bin/statsd' %}

statsd:
  service.running:
    - watch:
      - file: {{ config_path }}
    - require:
        - file: {{ log_path }}
        - file: statsd_upstart
        - pkg: statsd_requirements
        - user: statsd_service_account

statsd_requirements:
  pkg.installed:
    - pkgs:
      - node
      - npm
      - git

statsd_repository:
  git.latest:
    - name: https://github.com/etsy/statsd.git
    - rev: {{ branch }}
    - target: {{ install_path }}

statsd_service_account:
  user.present:
    - name: {{ service_account }}
    - shell: /bin/sh

statsd_log_path:
  file.directory:
    - name: {{ log_path }}
    - user: {{ service_account }}
    - group: {{ service_account }}
    - mode: 755
    - makedirs: True
    - require:
      - user: {{ service_account }}

statsd_config:
  file.managed:
    - name: {{ config_path }}
    - user: root
    - group: root
    - mode: 644
    - template: jinja
    - source: salt://statsd/templates/statsd.conf.jinja
    - context:
        config: {{ config }}
    - require:
      - user: {{ service_account }}

statsd_upstart:
  file.managed:
    - name: /etc/init/statsd.conf
    - user: root
    - group: root
    - mode: 644
    - template: jinja
    - source: salt://statsd/templates/statsd_upstart.jinja
    - context:
        log_file: {{ log_file }}
        service_account: {{ service_account }}
        config_path: {{ config_path }}
        bin_path: {{ bin_path }}
    - require:
      - user: {{ service_account }}
