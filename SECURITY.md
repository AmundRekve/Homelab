# Security

No credentials are committed to this repository. Secrets are supplied at deploy
time through Kubernetes Secrets, and only redacted templates are tracked here.

Three layers keep it that way:

- `.gitignore` rules covering credential files
- A local pre-commit hook that blocks credential-shaped content before it lands
- Automated secret scanning in CI on every push

Install the hook after cloning:

```sh
./scripts/install-git-hooks.sh
```

## Reporting

If you spot something, please open an issue or reach out directly rather than
posting details publicly.
