# target

Пример настройки сервера:

```yaml
target_fabric_modules:
  - name: iscsi
    discovery_enable_auth: true
    discovery_userid: '{{ target_discovery_userid }}'
    discovery_password: '{{ target_discovery_password }}'
    discovery_mutual_userid: '{{ target_discovery_mutual_userid }}'
    discovery_mutual_password: '{{ target_discovery_mutual_password }}'

target_storage_objects:
  - dev: /dev/disk/by-partlabel/{{ target_disk01_label }}
    name: '{{ target_disk01_label }}'
    plugin: block
    readonly: false
    write_back: false
    wwn: '{{ lookup("ansible.builtin.password",
      "secrets/target_{{ inventory_hostname }}_disk01_wwn.txt") |
      ansible.builtin.to_uuid }}'

target_targets:
  - wwn: iqn.2025-03.ru.abegorov:gfs2:{{ inventory_hostname }}
    tpgs:
      - luns:
          - alias: '{{ lookup("ansible.builtin.password",
              "secrets/target_{{ inventory_hostname }}_tpg1_lun1.txt",
              chars="01234567890abcdef", length=10) }}'
            storage_object: /backstores/block/{{ target_disk01_label }}
        node_acls: '{{ groups["gfs"] | map("ansible.builtin.extract",
          hostvars, "target_node_acl") }}'
        portals:
          - ip_address: '{{ ip_address_iscsi1 }}'
          - ip_address: '{{ ip_address_iscsi2 }}'
```

Настройка ACL для клиентов:

```yaml
target_node_acl:
  chap_userid: initiator
  chap_password: '{{ lookup("ansible.builtin.password",
    "secrets/target_{{ inventory_hostname }}_password.txt", length=26) }}'
  chap_mutual_userid: initiator_mutual
  chap_mutual_password: '{{ lookup("ansible.builtin.password",
    "secrets/target_{{ inventory_hostname }}_mutual_password.txt",
    length=26) }}'
  mapped_luns:
    - alias: '{{ lookup("ansible.builtin.password",
        "secrets/target_{{ inventory_hostname }}_tpg1_lun1.txt",
        chars="01234567890abcdef", length=10) }}'
  node_wwn: iqn.2025-03.ru.abegorov:gfs2:{{ inventory_hostname }}
```
