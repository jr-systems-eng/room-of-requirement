#!/usr/bin/env bash

# Curated relationships used by `ror need`. This is intentionally deterministic:
# it connects known resources without trying to infer a diagnosis from a keyword.

ror_need_topics() {
  printf '%s\n' ssh tls dns network systemd storage java tomcat kubernetes ansible containers git
}

ror_need_canonical_topic() {
  case "${1,,}" in
    ssh|sshd|sftp) printf 'ssh\n' ;;
    tls|ssl|cert|certs|certificate|certificates|openssl) printf 'tls\n' ;;
    dns|resolver|resolution) printf 'dns\n' ;;
    network|networking|connectivity|route|routing) printf 'network\n' ;;
    systemd|systemctl|service|services|journal|journalctl) printf 'systemd\n' ;;
    storage|disk|disks|filesystem|filesystems|fs|lvm|nfs) printf 'storage\n' ;;
    java|jvm|pkix|truststore|truststores|keystore|keystores) printf 'java\n' ;;
    tomcat|catalina) printf 'tomcat\n' ;;
    kubernetes|k8s|kubectl) printf 'kubernetes\n' ;;
    ansible) printf 'ansible\n' ;;
    container|containers|docker|compose|podman) printf 'containers\n' ;;
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
    storage) printf 'Filesystem capacity, mounts, NFS, LVM, inodes, large paths, and deleted-open files.\n' ;;
    java) printf 'Java/JVM process inspection, keystores, PKIX trust failures, and runtime context.\n' ;;
    tomcat) printf 'Tomcat service/process/log inspection with Java and PKIX follow-through.\n' ;;
    kubernetes) printf 'kubectl workflows and reusable Kubernetes deployment/service starting points.\n' ;;
    ansible) printf 'Ansible execution reference and reusable playbook starting points.\n' ;;
    containers) printf 'Docker Compose/container workflows and reusable Compose starting points.\n' ;;
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
      printf '%s\n' 'ror diagnose dns host.example.com' 'ror collect network' 'ror find --type runbook dns'
      ;;
    network)
      printf '%s\n' 'ror diagnose network' 'ror collect network' 'ror find --type runbook network'
      ;;
    systemd)
      printf '%s\n' 'ror diagnose systemd <service>' 'ror collect systemd <service>' 'ror find --type runbook systemd'
      ;;
    storage)
      printf '%s\n' 'ror diagnose storage' 'ror collect storage' 'ror find --type runbook nfs'
      ;;
    java)
      printf '%s\n' 'ror diagnose java [pid]' 'ror collect java <pid>' 'ror find --type runbook java'
      ;;
    tomcat)
      printf '%s\n' 'ror diagnose tomcat [service]' 'ror collect tomcat [service]' 'ror need java'
      ;;
    kubernetes)
      printf '%s\n' 'ror cheat kubernetes' 'ror find --type template kubernetes' 'ror pkg suggest kubernetes'
      ;;
    ansible)
      printf '%s\n' 'ror cheat ansible' 'ror find --type template ansible' 'ror pkg suggest ansible'
      ;;
    containers)
      printf '%s\n' 'ror cheat docker' 'ror find --type template docker' 'ror pkg suggest containers'
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
        'Runbook|docs/runbooks/troubleshoot-network-connectivity.md|Connectivity decision flow including DNS' \
        'Snippet|snippets/networking.md|Reusable DNS/network checks'
      ;;
    network)
      printf '%s\n' \
        'Reference|cheat-sheets/networking/linux-network-troubleshooting.md|Linux network troubleshooting reference' \
        'Reference|cheat-sheets/networking/subnetting.md|Subnetting reference' \
        'Diagnostic|scripts/diagnostics/network-info.sh|Addresses, routes, resolver state, and listeners' \
        'Runbook|docs/runbooks/troubleshoot-network-connectivity.md|Layered network troubleshooting procedure' \
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
        'Runbook|docs/runbooks/configure-nfs-share.md|NFSv4 server export and client mount procedure' \
        'Snippet|snippets/one-liners.md|Reusable storage/admin one-liners'
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
        'Runbook|docs/runbooks/troubleshoot-systemd-service.md|Service-level troubleshooting procedure' \
        'Runbook|docs/runbooks/troubleshoot-java-pkix.md|PKIX/truststore procedure when certificate errors appear' \
        'Reference|cheat-sheets/java/java-keystores.md|Java keystore/truststore reference'
      ;;
    kubernetes)
      printf '%s\n' \
        'Reference|cheat-sheets/containers/kubernetes-kubectl.md|kubectl and Kubernetes reference' \
        'Template|templates/kubernetes/deployment.yaml|Deployment starting point' \
        'Template|templates/kubernetes/service.yaml|Service starting point'
      ;;
    ansible)
      printf '%s\n' \
        'Reference|cheat-sheets/automation/ansible.md|Ansible command/playbook reference' \
        'Template|templates/ansible/playbook.yml|Playbook starting point'
      ;;
    containers)
      printf '%s\n' \
        'Reference|cheat-sheets/containers/docker-compose.md|Docker Compose reference' \
        'Template|templates/docker/compose.yaml|Compose starting point'
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
