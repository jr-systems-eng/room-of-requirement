# Ansible

Quick-reference for inventory, ad-hoc commands, playbook execution, variables, facts, debugging, and common enterprise-Linux workflows.

## Inventory

```bash
ansible-inventory -i inventory.ini --graph
ansible-inventory -i inventory.ini --list
ansible-inventory -i inventory.ini --host HOST
```

Test connectivity:

```bash
ansible all -i inventory.ini -m ping
ansible GROUP -i inventory.ini -m ping
```

## Ad-hoc commands

```bash
ansible all -i inventory.ini -a 'uname -r'
ansible all -i inventory.ini -b -a 'id'
ansible all -i inventory.ini -b -m shell -a 'systemctl status sshd --no-pager'
ansible all -i inventory.ini -b -m command -a 'rpm -q openssh-server'
```

Prefer `command` unless shell features (`|`, `>`, globbing, variables) are required.

## Run a playbook

```bash
ansible-playbook -i inventory.ini playbook.yml
ansible-playbook -i inventory.ini playbook.yml --check
ansible-playbook -i inventory.ini playbook.yml --check --diff
ansible-playbook -i inventory.ini playbook.yml --limit HOST
ansible-playbook -i inventory.ini playbook.yml --limit GROUP
ansible-playbook -i inventory.ini playbook.yml --tags TAG
ansible-playbook -i inventory.ini playbook.yml --skip-tags TAG
ansible-playbook -i inventory.ini playbook.yml -vvv
```

## Syntax and parsing

```bash
ansible-playbook playbook.yml --syntax-check
ansible-inventory -i inventory.ini --graph
```

## Variables

```bash
ansible-playbook ... -e 'var=value'
ansible-playbook ... -e '@vars.yml'
```

Useful built-ins:

```yaml
{{ inventory_hostname }}
{{ ansible_facts.default_ipv4.address }}
{{ ansible_facts.os_family }}
{{ ansible_facts.distribution }}
{{ ansible_facts.distribution_major_version }}
```

## Gather facts

```bash
ansible HOST -i inventory.ini -m setup
ansible HOST -i inventory.ini -m setup -a 'filter=ansible_distribution*'
```

## Debugging

```yaml
- debug:
    var: variable_name

- debug:
    msg: "Host {{ inventory_hostname }} = {{ ansible_facts.default_ipv4.address }}"
```

## Register output

```yaml
- name: Run command
  ansible.builtin.command: uname -r
  register: kernel
  changed_when: false

- ansible.builtin.debug:
    var: kernel.stdout
```

## Failure / change controls

```yaml
changed_when: false
failed_when: result.rc not in [0, 1]
ignore_errors: true        # use sparingly
```

## Become

```yaml
become: true
become_user: root
```

CLI:

```bash
ansible-playbook ... -b
ansible-playbook ... -K     # Ask for become password
```

## Copy / template / file

```yaml
- ansible.builtin.copy:
    src: files/config.conf
    dest: /etc/app/config.conf
    owner: root
    group: root
    mode: '0644'

- ansible.builtin.template:
    src: config.j2
    dest: /etc/app/config.conf

- ansible.builtin.file:
    path: /opt/app
    state: directory
    mode: '0755'
```

## Package and service

```yaml
- ansible.builtin.package:
    name: vim
    state: present

- ansible.builtin.service:
    name: sshd
    state: restarted
    enabled: true
```

## Handlers

```yaml
notify: Restart app

handlers:
  - name: Restart app
    ansible.builtin.service:
      name: app
      state: restarted
```

## Conditional distro logic

```yaml
when:
  - ansible_facts.os_family == 'RedHat'
  - ansible_facts.distribution_major_version | int >= 9
```

## Loops

```yaml
loop:
  - one
  - two

# current item is {{ item }}
```

## Common diagnostics

```bash
ansible --version
ansible-config dump --only-changed
ansible-config view
ansible-galaxy collection list
```

## Safer workflow

```text
1. --syntax-check
2. --check --diff where meaningful
3. --limit one test host
4. run on test host
5. verify service/output
6. expand to group/fleet
```
