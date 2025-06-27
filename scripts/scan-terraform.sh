#!/usr/bin/env bash
set -euo pipefail
source "${GITHUB_ACTION_PATH}/scripts/functions.sh"

WORKDIR="$GITHUB_WORKSPACE"

if ! find "$WORKDIR" -name '*.tf' -print -quit | grep -q .; then
  echo "Nenhum arquivo .tf encontrado - pulando verificações Terraform"
  exit 0
fi

########### SCAN TERRASCAN ##############
set +e
terrascan scan \
  -i terraform \
  -t aws \
  --iac-dir "$WORKDIR" \
  -o json > /tmp/terrascan.json
ts_exit=$?

jq -c '.results.violations[]?' /tmp/terrascan.json | while read -r vio; do
  rule=$(jq -r .rule_name <<<"$vio")
  title="Terrascan: $rule"
  mark_problem || true
  issue_info=$(find_issue "$title" || true)
  if [[ -z "$issue_info" ]]; then
    create_issue "$title" "```json\n$vio\n```" "terraform-security" || true
  else
    num=${issue_info%%:*}
    state=${issue_info##*:}
    if [[ "$state" == "closed" ]]; then
      reopen_issue "$num" || true
    fi
  fi
done

########### SCAN TRIVY ##############
trivy config \
  --format json \
  --severity HIGH,CRITICAL \
  --skip-files Dockerfile \
  -o /tmp/trivy_tf.json \
  "$WORKDIR" || true

mis_count=$(jq '[(.Results // [])[]?.Misconfigurations[]?] | length' /tmp/trivy_tf.json 2>/dev/null || echo 0)
if (( mis_count > 0 )); then
  set +e
  jq -c '(.Results // [])[]?.Misconfigurations[]?' /tmp/trivy_tf.json | while read -r mis; do
    id=$(jq -r .ID <<<"$mis")
    title="Trivy Terraform: $id"
    mark_problem || true
    issue_info=$(find_issue "$title" || true)
    if [[ -z "$issue_info" ]]; then
      create_issue "$title" "```json\n$mis\n```" "terraform-security" || true
    else
      num=${issue_info%%:*}
      state=${issue_info##*:}
      if [[ "$state" == "closed" ]]; then
        reopen_issue "$num" || true
      fi
    fi
  done
  set -e
else
  echo "::warning:: Trivy config não gerou /tmp/trivy_tf.json ou não encontrou problemas nos arquivos"
fi