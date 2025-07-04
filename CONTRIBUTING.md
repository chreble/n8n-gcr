# Contributing to n8n-gcr

First off, thanks for taking the time to contribute!  This project follows the [AI Coding Agent Policy](docs/delivery/backlog.md) — please read it if you plan to work on PBIs or tasks.

## 📜 Code of Conduct
We expect everyone to follow the [Contributor Covenant](https://www.contributor-covenant.org/version/2/0/code_of_conduct/). Be respectful and constructive.

## ✨ Ways to Contribute
1. **Bug reports** – open an issue with clear steps to reproduce.
2. **Feature requests** – open an issue and describe the problem / use-case.
3. **Pull requests** – improvements to docs, Terraform modules, GitHub actions, etc.

> **Note:** All code changes must reference an *agreed* task ID (e.g. `1-2`).  Unscoped PRs will be closed.

## 🛠️ Local Development
```bash
# Clone fork
 git clone https://github.com/<your-username>/n8n-gcr.git
 cd n8n-gcr

# Install tools
brew install opentofu cloudflint tfsec

# Validate Terraform before committing
 tofum fmt -recursive
 tofum validate
```

## ✔️ Commit Message Format
```
<task-id> <short description>

Longer description (wrap at 72 cols)
```
Example:
```
1-3 Fix IAP service-agent race by adding time_sleep
```

## 📄 Pull Request Checklist
- [ ] The PR title starts with `[<task-id>]`.
- [ ] `terraform fmt` passes.
- [ ] `tofu validate` passes for every changed module.
- [ ] Documentation updated (README / docs/*) if behaviour changes.

## 💬 Need help?
Open a discussion or ping @project-maintainers.  You can also reach out to the original author (Julian Harris) on X/Twitter.  Happy automating! 😊 