# Ansible LXC Cloud Role

Provision LXC containers like cloud instances and manage them in your Ansible inventory.

## Setup

Tested on

- Controller: Ansible 2.18 and above
- Managed node: Debian 12

First configure a system as a hypervisor to run your containers:

```yaml
- hosts: lxc_hypervisor
  roles:
    - role: lxc_cloud
      become: true
```

Then add a group to your inventory and provision containers with:

```yaml
- hosts: lxc
  ignore_unreachable: true
  tasks:
    - ansible.builtin.import_role:
        name: lxc_cloud
        tasks_from: ensure_instance
      delegate_to: lxc_hypervisor
      vars:
        name: test_container
        state: started
        template:
          distro: ubuntu
```

## Role Variables

### Hypervisor Variables

| Name | Description |
| --- | --- |
| `lxc_user` | The user to manage containers as. Defaults to `ansible_user`. |
| `lxc_usernet_bridges` | A list of bridge devices to allow an unprivileged `lxc_user` to attach container interfaces to. |
| `max_container_count` | The maximum number of containers `lxc_user` is allowed to run. This is enforced in the lxc-usernet(5) network interface quotas and delegation of subuid(5), subgid(5) subordinate user ids. |

### Container Variables

| Name | Description |
| --- | --- |
| `path` | The location in which containers are stored. |
| `name` | Name of container under `path`. |
| `state` | One of: "started", "stopped", "updated", or "absent". For a container that already exists, update its config by specifying "updated". |
| `template` | A dictionary that passes the following keys to lxc-create(1) as corresponding arguments to the "download" template: `distro`, `release`, `arch`. |
| `bdev` | A dictionary that passes the following keys to lxc-create(1) as corresponding arguments to `--bdev`: `type`, `root`. |
| `size` | Size of container rootfs, if supported by `bdev.type`. |
| `networks` | A list of dictionaries whose keys are passed to the container configuration file: `type`, `link`, `hwaddr`. These define how the network is virtualized in the container, as explained under the NETWORK section of lxc.container.conf(5). |
| `host_mounts` | A list of dictionaries with keys `path`, `ro`. The former defines the host-side path to mount in the container while the latter controls whether this mount is read only. |
| `user_data` | The [user-data](https://cloudinit.readthedocs.io/en/latest/explanation/format.html) to apply to a newly booted instance. |
| `network_config` | The [network configuration](https://cloudinit.readthedocs.io/en/latest/reference/network-config.html) to apply to a newly booted instance. |
| `instance_id` | A unique instance_id to allocate to a newly booted instance. One will be randomly generated if unspecified. |
| `nocloud_seedfrom` | The NoCloud [configuration source](https://cloudinit.readthedocs.io/en/latest/reference/datasources/nocloud.html#configuration-sources) of an external Instance Metadata Service to be used. Otherwise leave undefined to apply the `user_data` and `network_config` above. |

## Example Playbook

```yaml
# inventory.yaml
# bare_metal:
#   hosts:
#     lxc_hypervisor:
# lxc:
#   hosts:
#     test_container:
#       ansible_host: 192.168.1.12
#       distro: ubuntu
#       release: noble

- name: Configure lxc_cloud hypervisor
  hosts: lxc_hypervisor
  roles:
    - role: lxc_cloud
      become: true
      lxc_usernet_bridges: ["br-lan"]

- name: Provision lxc hosts
  hosts: lxc
  ignore_unreachable: true
  tasks:
    - ansible.builtin.import_role:
        name: lxc_cloud
        tasks_from: ensure_instance
      delegate_to: lxc_hypervisor
      vars:
        name: "{{ inventory_hostname }}"
        state: started
        template:
          distro: "{{ distro }}"
          release: "{{ release }}"
        bdev:
          type: zfs
          root: "pool/lxc"
        size: 5G
        networks:
          - link: br-lan
            hwaddr: '00:11:22:33:44:55'
        host_mounts:
          - path: /mnt/shared
            ro: true
        user_data: |
          #cloud-config
          password: password
          chpasswd:
            expire: False
        network_config: |
          version: 1
          config:
            - type: physical
              name: eth0
              mac_address: '00:11:22:33:44:55'
              subnets:
                - type: static
                  address: {{ ansible_host }}/24
                  gateway: 192.168.1.1
                  dns_nameservers:
                    - 192.168.1.1
```

## License

Apache-2.0
