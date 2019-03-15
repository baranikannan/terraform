{% set appname = "testapp-service" %}  

monitor-packages:
  pkg.installed:
    - pkgs:
      - perl-Switch
      - perl-DateTime
      - perl-Sys-Syslog
      - perl-LWP-Protocol-https

application-log-directory:
  file.directory:
    - name: /var/log/{{ appname }}
    - user: root
    - group: root
    - dir_mode: 755
    - file_mode: 755

application-jar:
  file.managed:
    - name: /opt/{{ appname }}/{{ appname }}.jar
    - source: salt://files/{{ appname }}.jar
    - user: root
    - group: root
    - mode: '755'
    - makedirs: True

application-job-define:
  file.symlink:
    - name: /etc/init.d/{{ appname }}
    - target: /opt/{{ appname }}/{{ appname }}.jar
    - user: root
    - group: root

application-job-add:
  cmd.run:
    - name: chkconfig --add {{ appname }}
    - runas: root

application-job-enable:
  cmd.run:
    - name: chkconfig {{ appname }} on
    - runas: root



