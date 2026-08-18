#!/usr/bin/env bash

# Curated relationships used by `ror need`. This is intentionally deterministic:
# it connects known resources without trying to infer a diagnosis from a keyword.

ror_need_topics() {
  printf '%s\n' ssh tls dns network systemd storage nfs performance java tomcat kubernetes ansible containers terraform github git
}

ror_need_canonical_topic() {
  case "${1,,}" in
    ssh|sshd|sftp) printf 'ssh\n' ;;
    tls|ssl|cert|certs|certificate|certificates|openssl) printf 'tls\n' ;;
    dns|resolver|resolution) printf 'dns\n' ;;
    network|networking|connectivity|route|routing) printf 'network\n' ;;
    systemd|systemctl|service|services|journal|journalctl) printf 'systemd\n' ;;
    storage|disk|disks|filesystem|filesystems|fs|lvm) printf 'storage\n' ;;
    nfs|nfs4|nfsv4) printf 'nfs\n' ;;
    performance|perf|load|cpu|memory|swap|pressure) printf 'performance\n' ;;
    java|jvm|pkix|truststore|truststores|keystore|keystores) printf 'java\n' ;;
    tomcat|catalina) printf 'tomcat\n' ;;
    kubernetes|k8s|kubectl) printf 'kubernetes\n' ;;
    ansible) printf 'ansible\n' ;;
    container|containers|docker|compose|podman) printf 'containers\n' ;;
    terraform|tf|iac) printf 'terraform\n' ;;
    github|gha|actions|workflow|workflows) printf 'github\n' ;;
    git) printf 'git\n' ;;
    list|topics) printf 'list\n' ;;
    *) return 1 ;;
  esac
}

ror_need_description() {
  case "$1" in
    ssh) printf 'SSH/SFTP connectivity, authentication, daemon state, and crypto negotiation.\n' ;;
    tls) printf 'TLS handshakes, certificate names, expiry, chain verification, and trust troubleshooting.\n' ;;
    dns) printf 'Resolver configuration, name resolution, DNS responses, and lookup troubleshooting.\n' ;;
    network) printf 'Host networking, routes, listeners, DNS context, and general connectivity.\n' ;;
    systemd) printf 'systemd service state, unit configuration, exit status, and journal troubleshooting.\n' ;;
    storage) printf 'Filesystem capacity, mounts, LVM, inodes, large paths, deleted-open files, and safe capacity growth.\n' ;;
    nfs) printf 'NFSv4 server exports, client mounts, persistence, permissions, and connectivity.\n' ;;
    performance) printf 'Linux load, CPU, memory, swap, blocked tasks, and evidence-driven performance triage.\n' ;;
    java) printf 'Java/JVM process inspection, keystores, PKIX trust failures, and runtime context.\n' ;;
    tomcat) printf 'Tomcat startup, service/process/log inspection, Java, and PKIX follow-through.\n' ;;
    kubernetes) printf 'kubectl workflows and reusable Kubernetes workload/network/storage starting points.\n' ;;
    ansible) printf 'Ansible execution reference plus inventory, playbook, rolling-change, and audit starting points.\n' ;;
    containers) printf 'Docker/Compose workflows and reusable container build/runtime starting points.\n' ;;
    terraform) printf 'Portable Terraform module starting points and infrastructure-as-code discovery.\n' ;;
    github) printf 'Reusable GitHub Actions workflows and pull-request review scaffolding.\n' ;;
    git) printf 'Everyday Git reference, snippets, and portable Git configuration.\n' ;;
  esac
}

ror_need_commands() {
  case "$1" in
    ssh)
      printf '%s\n' 'ror diagnose ssh' 'ror collect ssh' 'ror find --type runbook ssh'
      ;;
    tls)
      printf '%s\n' 'ror diagnose tls host.example.com:443' 'ror collect tls host.example.com:443' 'ror find --type runbook certificate'
      ;;
    dns)
      printf '%s\n' 'ror diagnose dns host.example.com' 'ror find --type runbook dns' 'ror need network'
      ;;
    network)
      printf '%s\n' 'ror diagnose network' 'ror collect network' 'ror find --type runbook network'
      ;;
    systemd)
      printf '%s\n' 'ror diagnose systemd <service>' 'ror collect systemd <service>' 'ror find --type runbook systemd'
      ;;
    storage)
      printf '%s\n' 'ror diagnose storage' 'ror collect storage' 'ror find --type runbook lvm'
      ;;
    nfs)
      printf '%s\n' 'ror find --type runbook nfs' 'ror diagnose network' 'ror diagnose storage'
      ;;
    performance)
      printf '%s\n' 'ror doctor' 'ror diagnose system' 'ror diagnose storage' 'ror find --type runbook load'
      ;;
    java)
      printf '%s\n' 'ror diagnose java [pid]' 'ror collect java <pid>' 'ror find --type runbook java'
      ;;
    tomcat)
      printf '%s\n' 'ror diagnose tomcat [service]' 'ror find --type runbook tomcat' 'ror need java'
      ;;
    kubernetes)
      printf '%s\n' 'ror cheat kubernetes' 'ror find --type template k8s' 'ror pkg suggest kubernetes'
      ;;
    ansible)
      printf '%s\n' 'ror cheat ansible' 'ror find --type template ansible' 'ror pkg suggest ansible'
      ;;
    containers)
      printf '%s\n' 'ror cheat docker' 'ror find --type template docker' 'ror pkg suggest containers'
      ;;
    terraform)
      printf '%s\n' 'ror find --type template terraform' 'ror new terraform/module.tf ./main.tf' 'ror find terraform'
      ;;
    github)
      printf '%s\n' 'ror find --type template github' 'ror new github/workflow-shellcheck.yml ./.github/workflows/shellcheck.yml' 'ror new github/pull_request_template.md ./.github/pull_request_template.md'
      ;;
    git)
      printf '%s\n' 'ror cheat git' 'ror find --type snippet git' 'ror dotfiles diff git'
      ;;
  esac
}

# Rows are TYPE|PATH|NOTE. Paths are relative to ROR_HOME.
ror_need_resources() {
  case "$1" in
    ssh)
      printf '%s\n' \
        'Reference|cheat-sheets/networking/ssh-sftp.md|SSH/SFTP client, server, and negotiation reference' \
        'Diagnostic|scripts/diagnostics/ssh-server.sh|Daemon, listener, effective config, and recent log inspection' \
        'Runbook|docs/runbooks/troubleshoot-ssh-connection.md|Stepwise SSH/SFTP troubleshooting procedure' \
        'Snippet|snippets/networking.md|Reusable networking checks'
      ;;
    tls)
      printf '%s\n' \
        'Reference|cheat-sheets/security/openssl-certificates.md|OpenSSL and certificate reference' \
        'Diagnostic|scripts/diagnostics/tls-endpoint.sh|Handshake, leaf certificate, SAN, expiry, and verify checks' \
        'Runbook|docs/runbooks/troubleshoot-tls-certificate.md|TLS/certificate troubleshooting procedure' \
        'Snippet|snippets/networking.md|Reusable endpoint/network checks'
      ;;
    dns)
      printf '%s\n' \
        'Reference|cheat-sheets/networking/dns.md|DNS lookup and resolver reference' \
        'Diagnostic|scripts/diagnostics/dns.sh|Resolver config/status and optional name lookup' \
        'Runbook|docs/runbooks/troubleshoot-dns-resolution.md|DNS-specific resolver and lookup decision path' \
        'Runbook|docs/runbooks/investigate-network-connectivity.md|Broader layered connectivity procedure' \
        'Snippet|snippets/networking.md|Reusable DNS/network checks'
      ;;
    network)
      printf '%s\n' \
        'Reference|cheat-sheets/networking/linux-network-troubleshooting.md|Linux network troubleshooting reference' \
        'Reference|cheat-sheets/networking/subnetting.md|Subnetting reference' \
        'Diagnostic|scripts/diagnostics/network-info.sh|Addresses, routes, resolver state, and listeners' \
        'Runbook|docs/runbooks/investigate-network-connectivity.md|Layered network troubleshooting procedure' \
        'Snippet|snippets/networking.md|Reusable network checks'
      ;;
    systemd)
      printf '%s\n' \
        'Reference|cheat-sheets/linux/systemd-journalctl.md|systemd and journalctl reference' \
        'Diagnostic|scripts/diagnostics/systemd-service.sh|Service state, unit, properties, logs, and summary' \
        'Runbook|docs/runbooks/troubleshoot-systemd-service.md|Service troubleshooting procedure' \
        'Template|templates/systemd/service.service|Known-good service unit starting point' \
        'Template|templates/systemd/timer.timer|Known-good timer unit starting point'
      ;;
    storage)
      printf '%s\n' \
        'Reference|cheat-sheets/linux/storage-filesystems.md|Block device, filesystem, mount, and LVM reference' \
        'Diagnostic|scripts/diagnostics/storage.sh|Capacity, inode, mount, LVM, large-path, and open-file checks' \
        'Runbook|docs/runbooks/troubleshoot-full-filesystem.md|Full-filesystem troubleshooting procedure' \
        'Runbook|docs/runbooks/extend-lvm-filesystem.md|Safe LV and filesystem growth procedure' \
        'Snippet|snippets/one-liners.md|Reusable storage/admin one-liners'
      ;;
    nfs)
      printf '%s\n' \
        'Runbook|docs/runbooks/configure-nfs-share.md|NFSv4 server export and client mount procedure' \
        'Diagnostic|scripts/diagnostics/network-info.sh|Route, resolver, listener, and network context' \
        'Diagnostic|scripts/diagnostics/storage.sh|Mount/filesystem/LVM context' \
        'Reference|cheat-sheets/linux/storage-filesystems.md|Mount and filesystem reference' \
        'Snippet|snippets/networking.md|Reusable reachability checks'
      ;;
    performance)
      printf '%s\n' \
        'Diagnostic|scripts/diagnostics/system-info.sh|CPU, memory, uptime, and system context' \
        'Diagnostic|scripts/diagnostics/storage.sh|Filesystem and storage context for blocked/I/O waits' \
        'Runbook|docs/runbooks/investigate-high-load.md|CPU/load/blocked-task investigation procedure' \
        'Runbook|docs/runbooks/investigate-memory-pressure.md|Memory/swap/OOM investigation procedure' \
        'Snippet|snippets/one-liners.md|Reusable process/system one-liners'
      ;;
    java)
      printf '%s\n' \
        'Reference|cheat-sheets/java/java-keystores.md|Java keystore/truststore reference' \
        'Diagnostic|scripts/diagnostics/java-process.sh|Java runtime/process/JVM inspection' \
        'Runbook|docs/runbooks/troubleshoot-java-pkix.md|Java certificate trust/PKIX troubleshooting procedure' \
        'Reference|cheat-sheets/security/openssl-certificates.md|Certificate-chain inspection reference'
      ;;
    tomcat)
      printf '%s\n' \
        'Diagnostic|scripts/diagnostics/tomcat.sh|Tomcat service/process/log inspection' \
        'Diagnostic|scripts/diagnostics/java-process.sh|JVM follow-through for a Tomcat PID' \
        'Runbook|docs/runbooks/troubleshoot-tomcat-startup.md|Tomcat startup/failure decision path' \
        'Runbook|docs/runbooks/troubleshoot-systemd-service.md|Service-level troubleshooting procedure' \
        'Runbook|docs/runbooks/troubleshoot-java-pkix.md|PKIX/truststore procedure when certificate errors appear' \
        'Reference|cheat-sheets/java/java-keystores.md|Java keystore/truststore reference'
      ;;
    kubernetes)
      printf '%s\n' \
        'Reference|cheat-sheets/containers/kubernetes-kubectl.md|kubectl and Kubernetes reference' \
        'Template|templates/k8s/deployment.yaml|Deployment starting point' \
        'Template|templates/k8s/service.yaml|Service starting point' \
        'Template|templates/k8s/namespace.yaml|Namespace starting point' \
        'Template|templates/k8s/configmap.yaml|Non-secret application configuration' \
        'Template|templates/k8s/ingress.yaml|Ingress starting point' \
        'Template|templates/k8s/persistent-volume-claim.yaml|Persistent storage claim starting point'
      ;;
    ansible)
      printf '%s\n' \
        'Reference|cheat-sheets/automation/ansible.md|Ansible command/playbook reference' \
        'Template|templates/ansible/playbook.yml|General playbook starting point' \
        'Template|templates/ansible/inventory.ini|INI inventory starting point' \
        'Template|templates/ansible/rolling-change.yml|Serial/rolling change playbook starting point' \
        'Template|templates/ansible/audit-playbook.yml|Read-only evidence collection starting point'
      ;;
    containers)
      printf '%s\n' \
        'Reference|cheat-sheets/containers/docker-compose.md|Docker Compose reference' \
        'Template|templates/docker/compose.yaml|Compose starting point' \
        'Template|templates/docker/Dockerfile|Container image starting point'
      ;;
    terraform)
      printf '%s\n' \
        'Template|templates/terraform/module.tf|Single-file portable Terraform module starting point' \
        'Guide|docs/resource-authoring.md|Repository safety and placeholder conventions'
      ;;
    github)
      printf '%s\n' \
        'Template|templates/github/workflow-shellcheck.yml|Bash/ShellCheck workflow starting point' \
        'Template|templates/github/workflow-ansible-lint.yml|Ansible lint workflow starting point' \
        'Template|templates/github/pull_request_template.md|Pull-request review checklist starting point' \
        'Guide|docs/resource-authoring.md|Repository authoring/validation contract'
      ;;
    git)
      printf '%s\n' \
        'Reference|cheat-sheets/development/git.md|Git command/workflow reference' \
        'Snippet|snippets/git.md|Reusable Git fragments' \
        'Dotfile|dotfiles/git/gitconfig|Portable managed Git defaults' \
        'Dotfile|dotfiles/git/gitignore_global|Portable global ignore defaults'
      ;;
  esac
}

ror_need_print() {
  local requested="${1:-}" topic type path note current_type=''
  [ -n "$requested" ] || {
    printf 'Curated topics:\n'
    ror_need_topics | sed 's/^/  /'
    return 0
  }

  topic="$(ror_need_canonical_topic "$requested")" || return 2
  if [ "$topic" = 'list' ]; then
    printf 'Curated topics:\n'
    ror_need_topics | sed 's/^/  /'
    return 0
  fi

  printf 'Room of Requirement: %s\n' "$topic"
  printf 'Purpose: %s' "$(ror_need_description "$topic")"
  printf '\nQuick actions:\n'
  ror_need_commands "$topic" | sed 's/^/  /'

  printf '\nResources:\n'
  while IFS='|' read -r type path note; do
    [ -n "$path" ] || continue
    [ -e "$ROR_HOME/$path" ] || continue
    if [ "$type" != "$current_type" ]; then
      printf '  %s\n' "$type"
      current_type="$type"
    fi
    printf '    %-52s %s\n' "$path" "$note"
  done < <(ror_need_resources "$topic")
}
