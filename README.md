# GFS2 хранилище в VirtualBox

## Задание

1. Развернуть в **VirtualBox** конфигурацию для общего хранилища с **GFS2**.
2. Настроить базовую конфигурацию **GFS2** для совместного использования диска между виртуальными машинами.

## Реализация

Задание сделано на **bento/ubuntu-24.04** версии **202502.21.0**. Для автоматизации процесса написан **Ansible Playbook** [provision.yml](provision.yml) который последовательно запускает следующие роли:

- **wait_connection** - ожидает доступности машин;

Данные роли настраиваются с помощью переменных, определённых в следующих файлах:

- [group_vars/all](group_vars/all.yml] - общие переменные для всех узлов;

## Запуск

Необходимо скачать **VagrantBox** для **bento/ubuntu-24.04** версии **202502.21.0** и добавить его в **Vagrant** под именем **bento/ubuntu-24.04/202502.21.0**. Сделать это можно командами:

```shell
curl -OL https://app.vagrantup.com/bento/boxes/ubuntu-24.04/versions/202502.21.0/providers/virtualbox/amd64/vagrant.box
vagrant box add vagrant.box --name "bento/ubuntu-24.04/202502.21.0"
rm vagrant.box
```

После этого нужно сделать **vagrant up**.

Протестировано в **OpenSUSE Tumbleweed**:

- **Vagrant 2.4.3**
- **VirtualBox 7.1.4_SUSE r165100**
- **Ansible 2.18.3**
- **Python 3.11.11**
- **Jinja2 3.1.4**

## Проверка
