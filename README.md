# GFS2 хранилище в VirtualBox

## Задание

1. Развернуть в **VirtualBox** конфигурацию для общего хранилища с **GFS2**.
2. Настроить базовую конфигурацию **GFS2** для совместного использования диска между виртуальными машинами.
3. Настроить **fencing**.

## Реализация

Задание сделано так, чтобы его можно было запустить как в **Vagrant**, так и в **Yandex Cloud**. После запуска происходит развёртывание следующих виртуальных машин:

- **gfs-iscsi-01** - первый сервер **iSCSI target**;
- **gfs-iscsi-02** - второй сервер **iSCSI target**;
- **gfs-01** - первый клиент файловой системы **GFS2**;
- **gfs-02** - второй клиент файловой системы **GFS2**;
- **gfs-03** - третий клиент файловой системы **GFS2**.

Реализована следующая схема отказоустойчивого общего хранилища:

![Схема хранилища](images/scheme.png)

1. На двух узлах (**gfs-iscsi-01** и **gfs-iscsi-02**) по **iSCSI** расшариваются общие диски на двух разных сетевых интерфейсах в сетях **gfs-iscsi01** и **gfs-iscsi02**.
2. Расшаренные диски подключаются с использованием обоюдной аутентификации на узлах **gfs-01**, **gfs-02**, **gfs-03**.
3. Поскольку диски расшариваются через два разных сетевых интерфейсах, то настраивается **multipath**. Также для каждого узла в `multipath.conf` настраивается **reservation_key** для последующей настройки агента **fence_mpath** в **pacemaker**.
4. Расшаренные узлах **gfs-01**, **gfs-02**, **gfs-03** объединяются в общий массив **RAID1** с использованием технолгии [MD Cluster](https://docs.kernel.org/driver-api/md/md-cluster.html).
5. Полученный массиве **/dev/md/cluster-md** добавляется в **LVM Shared Volume Group** с именем **cluster-vg** и на ней создаётся и активируется общий логический том **cluster-lv**.
6. Логический том **cluster-lv** форматируется в **GFS2** и монтируется на узлах **gfs-01**, **gfs-02**, **gfs-03**.

Для выполнения **fencing** (используется агент **fence_mpath**) и автоматического поднятия файловой системы после перезагрузки используется **pacemaker**. Обмен сообщениями между узлами кластера поддерживается с помощью **corosync** (настроена отказоустойчивая конфигурация с использованием трёх колец). В качестве распределённого менеджера блокировок используется **dlm**, который в свою очередь используется **MD Cluster**, **lvmlockd** и **gfs2** для блокировок доступа к ресурсам между узлами кластера.

В независимости от того, как созданы виртуальные машины, для их настройки запускается **Ansible Playbook** [provision.yml](provision.yml) который последовательно запускает следующие роли:

- **wait_connection** - ожидает доступность виртуальных машин.
- **apt_sources** - настраивает репозитории для пакетного менеджера **apt** (используется [mirror.yandex.ru](https://mirror.yandex.ru)).
- **chrony** - устанавливает **chrony** для синхронизации времени между узлами.
- **hosts** - прописывает адреса всех узлов в `/etc/hosts`.
- **gen_keys** - генерит `/etc/corosync/authkey` для кластера **corosync**.
- **disk_facts** - собирает информацию о дисках и их сигнатурах (с помощью утилит `lsblk` и `wipefs`).
- **disk_label** - разбивает диски и устанавливает на них **GPT Partition Label** для их дальнейшей идентификации.
- **target** - настраивает сервер **iSCSI Target**.
- **linux_modules** - устанавливает модули ядра (в **Yandex Cloud** стоит **linux-virtual**, который не содержит модулей ядра для работы с **GFS2**).
- **iscsi** - настраивает **iSCSI Initiator**.
- **mpath** - настраивает **multipathd**, в частности прописывает **reservation_key** в `/etc/multipath.conf` для последующего использования в агенте **fence_mpath** для настройки **fencing**'а.
- **corosync** - настраивает кластер **corosync** в несколько колец.
- **dlm** - устанавливает распределённый менеджер блокировок **dlm**.
- **mdadm** - устанавилвает **mdadm** и создаёт **RAID1** массив `/dev/md/cluster-md` (используется технология [MD Cluster](https://docs.kernel.org/driver-api/md/md-cluster.html)).
- **lvm_facts** - с помощью утилит **vgs** и **lvs** собирает информацию о группах и томах **lvm**;
- **lvm** - устанавливает **lvm2**, **lvm2-lockd**, создаёт группы томов, сами логические тома и активирует их.
- **gfs2** - устанавливает **gfs2-utils**.
- **filesystem** - форматирует общий диск в файловую систему **GFS2**.
- **directory** - создаёт пустую директорию `/mnt/cluster-fs`.
- **pacemaker** - устанавливает и настраивается **pacemaker**, который в свою очередь монтирует файловую систему `/dev/cluster-vg/cluster-lv` в `/mnt/cluster-fs`.

Данные роли настраиваются с помощью переменных, определённых в следующих файлах:

- [group_vars/all/ansible.yml](group_vars/all/ansible.yml) - общие переменные **ansible** для всех узлов;
- [group_vars/all/hosts.yml](group_vars/all/hosts.yml) - настройки для роли **hosts** (список узлов, которые нужно добавить в `/etc/hosts`);
- [group_vars/all/iscsi.yml](group_vars/all/iscsi.yml) - общие настройки для **iSCSI Target** и **iSCSI Initiator**;
- [group_vars/iscsi/iscsi.yml](group_vars/all/iscsi.yml) - настройки **iSCSI Target**;
- [group_vars/gfs/iscsi.yml](group_vars/all/iscsi.yml) - настройки **iSCSI Initiator**;
- [group_vars/gfs/corosync.yml](group_vars/gfs/corosync.yml) - настройки **corosync**;
- [group_vars/gfs/gfs2.yml](group_vars/gfs/gfs2.yml) - настройки **MD Cluster**, **LVM**, **GFS2**;
- [host_vars/gfs-01/gfs2.yml](host_vars/gfs-01/gfs2.yml) - настройки создания **MD Cluster**, **LVM**, **GFS2**;
- [host_vars/gfs-01/pacemaker.yml](host_vars/gfs-01/pacemaker.yml) - настройки **pacemaker**.

## Запуск

### Запуск в Yandex Cloud

1. Необходимо установить и настроить утилиту **yc** по инструкции [Начало работы с интерфейсом командной строки](https://yandex.cloud/ru/docs/cli/quickstart).
2. Необходимо установить **Terraform** по инструкции [Начало работы с Terraform](https://yandex.cloud/ru/docs/tutorials/infrastructure-management/terraform-quickstart).
3. Необходимо установить **Ansible**.
4. Необходимо перейти в папку проекта и запустить скрипт [up.sh](up.sh).

### Запуск в Vagrant (VirtualBox)

Необходимо скачать **VagrantBox** для **bento/ubuntu-24.04** версии **202502.21.0** и добавить его в **Vagrant** под именем **bento/ubuntu-24.04/202502.21.0**. Сделать это можно командами:

```shell
curl -OL https://app.vagrantup.com/bento/boxes/ubuntu-24.04/versions/202502.21.0/providers/virtualbox/amd64/vagrant.box
vagrant box add vagrant.box --name "bento/ubuntu-24.04/202502.21.0"
rm vagrant.box
```

После этого нужно сделать **vagrant up** в папке проекта.

## Проверка

Протестировано в **OpenSUSE Tumbleweed**:

- **Vagrant 2.4.3**
- **VirtualBox 7.1.4_SUSE r165100**
- **Ansible 2.18.4**
- **Python 3.13.2**
- **Jinja2 3.1.6**
