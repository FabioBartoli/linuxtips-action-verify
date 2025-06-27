> [!IMPORTANT] 
> Essa Action foi criada para o curso ["Criando Pipelines e Automações com Github Actions" da LinuxTips](https://linuxtips.io/github-actions/). Fique a vontade para utilizá-lo e, se quiser entender sua construção, venha fazer parte da turma!

Esta GitHub Action nasceu para automatizar **as checagens de segurança e boas-práticas** que todo repositório DevOps deve rodar. Ela escaneia seus Dockerfiles, suas imagens Docker buildadas e seu código Terraform, gerando issues com todos os problemas que precisam ser corrigidos

  

| Fase | Ferramenta | O que analisa | Saída |
|------|------------|---------------|-------|
| **Build** | **Docker** | Constrói a imagem (tag `imagem-verificada`) a partir do contexto definido | Falha se o build quebrar |
| **Lint** | **Hadolint** | Dockerfile(s) | Gera issues para cada vulnerabilidade encontrada |
| **Vuln Scan** | **Trivy** | Image Docker recém-buildada | Issues “Trivy Docker: CVE-9999 em pacote (HIGH)” |
| **IaC Scan** | **Terrascan** | Diretório `infra/` ou qualquer `.tf` | Gera issues para cada vulnerabilidade encontrada “Terrascan: regra-xyz no arquivo.tf” |
| **Vuln Scan IaC** | **Trivy** | Arquivos de Config do Repo | Issues “Trivy Terraform: CVE-1234 em pacote (CRITICAL)” |

  

Inputs:

| Nome | Default | Descrição |
|------|---------|-----------|
| `docker-context` | `.` | Caminho relativo onde está o Dockerfile (pode apontar para `app`, `services/api`, etc.) |

  

Exemplo de uso:
  

```yaml
name: Scan Test

on: 
  workflow_dispatch:
    inputs:
      docker-context:
        default: 'app'
        required: false

permissions: # Permissões necessárias
	issues: write

jobs:
  call-scan:
    runs-on: ubuntu-latest
    steps:
      - uses: FabioBartoli/linuxtips-action-verify@v1.0.0
        with: 
          docker-context: ${{ github.event.inputs.docker-context }}
