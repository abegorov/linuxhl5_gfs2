# iscsi

Пример настройки:

```yaml
iscsi_initiator_name: iqn.2025-03.ru.abegorov:gfs2:{{ inventory_hostname }}
iscsi_config_override:
  node.session.auth.username: '{{ target_node_acl.chap_userid }}'
  node.session.auth.password: '{{ target_node_acl.chap_password }}'
  node.session.auth.username_in: '{{ target_node_acl.chap_mutual_userid }}'
  node.session.auth.password_in: '{{ target_node_acl.chap_mutual_password }}'
  discovery.sendtargets.auth.username: '{{ target_discovery_userid }}'
  discovery.sendtargets.auth.password: '{{ target_discovery_password }}'
  discovery.sendtargets.auth.username_in: '{{
    target_discovery_mutual_userid }}'
  discovery.sendtargets.auth.password_in: '{{
    target_discovery_mutual_password }}'
iscsi_portals:
  - '{{ hostvars["iscsi-01"].ip_address_iscsi1 }}'
  - '{{ hostvars["iscsi-01"].ip_address_iscsi2 }}'
iscsi_targets:
  - target: '{{ hostvars["iscsi-01"].target_wwn }}'
    node_user: '{{ target_node_acl.chap_userid }}'
    node_pass: '{{ target_node_acl.chap_password }}'
    node_user_in: '{{ target_node_acl.chap_mutual_userid }}'
    node_pass_in: '{{ target_node_acl.chap_mutual_password }}'
```
