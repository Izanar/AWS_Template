# AWS_Template

A hands-on infrastructure template that deploys the [AI_Nginx](https://github.com/Izanar/AI_Nginx)
demo application (custom nginx site with the Kyiv Skyline static + audio page)
through four different setups using **Terraform**, **Terragrunt**, **Ansible**
and **Kubernetes**. Every scenario ends with the same app running: nginx
installed and configured, the AI_Nginx content served and a smoke test passed.

| Scenario | Infrastructure | Where |
|---|---|---|
| `ec2` | AWS Spot EC2 + nginx (Ansible) | Cloud (AWS) |
| `eks-fargate` | AWS EKS cluster (Fargate profiles) | Cloud (AWS) |
| `eks-ec2-s3` | AWS EKS + S3 + CloudFront (OAC) | Cloud (AWS) |
| `local-wsl` | k3s on WSL2 | Local |

## Repository layout

```text
├── root.hcl                  Shared settings + generated provider.tf
├── envs/                     One Terragrunt unit per scenario
├── src/                      Self-contained Terraform roots
├── ansible/                  Playbooks and roles (nginx, deploy_site, eks)
├── kubernetes/               Manifests (base/ for EKS, local/ for k3s)
├── scripts/                  deploy.sh, destroy.sh, WSL helpers
├── docs/                     Full documentation
└── .github/workflows/        validate.yml (CI) + deploy.yml (manual)
```

## Проверенный статус и безопасность затрат (2026-09-17)

- Бесплатные проверки: `make test`, Terraform/Terragrunt validate для всех четырёх сценариев,
  `local-wsl init → validate → plan`, HCL formatting и actionlint прошли.
- **AWS apply не выполнялся.** Работа не создала AWS-ресурсов. Проверить ранее
  созданные ресурсы и баланс аккаунта без AWS-доступа невозможно.
- Живой local-wsl E2E заблокирован: текущий WSL запущен без systemd; sudo требует пароль.
  Скрипт останавливается до создания ресурсов. Это не подтверждённый production-релиз.
- По умолчанию скрипты и Makefile выбирают `local-wsl`. Для облачного `make apply`
  требуется `CONFIRM_COSTS=yes`; бюджетное уведомление **не ограничивает расходы**.
- Локальный state хранится в `envs/<scenario>/terraform.tfstate`, вне кэша.
  **Если вы уже делали apply старой версией, сначала сохраните state из старого кэша
  и выполните `terragrunt init -migrate-state` в той же среде. Не очищайте кэш до миграции.**
- GitHub Deploy управляет **только инфраструктурой**, не приложением. Для него обязательны
  существующий S3 backend и DynamoDB lock table: repository variables `TF_STATE_BUCKET`,
  `TF_STATE_REGION`, `TF_LOCK_TABLE`. Шаблон их не создаёт. Backend сам может иметь стоимость.
- `local-wsl` запускается на вашем WSL2, не на временном GitHub runner.
  Kubeconfig: `~/.kube/aws-template-k3s.yaml`. Существующий kubeconfig не перезаписывается.
- EKS использует заранее опубликованный доступный GHCR-образ с приложением и curl.
  Копирования файлов в живые поды больше нет. S3/CloudFront создаются, но загрузка аудио
  и привязка URL к приложению пока не автоматизированы.

Подробности очистки и границ проверки: [docs/completion.md](docs/completion.md).

## Quick start

Requirements: Terraform >= 1.9, Terragrunt >= 0.68, Ansible, `aws` CLI for
cloud scenarios. `make install-tools` installs everything into your home
directory.

```bash
# 1. Install tools (Terraform, Terragrunt, Ansible, Python deps)
make install-tools

# 2. Validate everything compiles (static checks, no resources created)
make validate

# 3. Deploy a scenario
./scripts/deploy.sh <scenario>

# 4. Destroy when done
./scripts/destroy.sh <scenario>
```

### Доступные сценарии

| Сценарий | Команда | Облачные ресурсы? | Что нужно |
|---|---|---|---|
| `ec2` | `./scripts/deploy.sh ec2` | Да (EC2 Spot) | AWS creds, `aws` CLI, SSH-ключи |
| `eks-fargate` | `./scripts/deploy.sh eks-fargate` | Да (EKS) | AWS creds, `aws` CLI, `kubectl` |
| `eks-ec2-s3` | `./scripts/deploy.sh eks-ec2-s3` | Да (EKS + S3 + CloudFront) | AWS creds, `aws` CLI, `kubectl` |
| `local-wsl` | `./scripts/deploy.sh local-wsl` | **Нет** | WSL2, `kubectl` |

> **Локальный сценарий (`local-wsl`)** — единственный, который не требует облачных ресурсов и не создаёт расходов. Его можно полностью протестировать локально на WSL2. Подробная пошаговая инструкция с командами для проверки каждого шага есть в [docs/usage.md](docs/usage.md#4-local-wsl--k3s-on-wsl2-no-cloud).

See [docs/usage.md](docs/usage.md) for the complete guide, including the
manual GitHub Actions deployment and required secrets.

### Команды Makefile

```bash
make help                          # показать все доступные команды
make validate                      # статические проверки (Terraform, Ansible, K8s, Shell)
make install-tools                 # установить Terraform, Terragrunt, Ansible и Python-инструменты
make init ENV=<scenario>          # terragrunt init для выбранного сценария
make plan ENV=<scenario>          # terragrunt plan
make apply ENV=<scenario>         # terragrunt apply (создаёт ресурсы!)
make output ENV=<scenario>        # показать выходные данные Terraform
make destroy ENV=<scenario>       # terragrunt destroy
make fmt                           # отформатировать Terraform-код
make precommit                     # запустить pre-commit хуки
```

Поддерживаемые значения `ENV`: `ec2`, `eks-fargate`, `eks-ec2-s3`, `local-wsl`.
По умолчанию: `local-wsl`.

## Cloud credentials

The manual **Deploy** workflow uses GitHub OIDC through the `AWS_ROLE_ARN`
secret. The EC2 Ansible step additionally needs `AWS_SSH_PRIVATE_KEY` and
`AWS_SSH_PUBLIC_KEY` secrets. Set `BUDGET_EMAIL` (locally or as a secret) to
enable the optional monthly AWS budget alert.

## Documentation

- [docs/README.md](docs/README.md) - overview
- [docs/architecture.md](docs/architecture.md) - layout and data flow
- [docs/usage.md](docs/usage.md) - local control and CI/CD
- [docs/development.md](docs/development.md) - validation and contribution

> This template creates real, billable resources in AWS. Use the manual
> `destroy` action or `./scripts/destroy.sh` after testing.
