# spin-polyglot

Lean [Spin](https://spinframework.dev/) HTTP application with one component per language: **Rust**, **Go**, **Python**, and **TypeScript**.

## Routes

| Route | Component | Language |
| --- | --- | --- |
| `/rust/...` | `rust` | Rust |
| `/go/...` | `go` | Go |
| `/python/...` | `python` | Python |
| `/typescript/...` | `typescript` | TypeScript |

Each handler returns JSON:

```json
{"component":"rust","message":"Hello from Spin","path":"/"}
```

## Prerequisites

- [Spin CLI](https://spinframework.dev/v4/install) **4.x**
- **Rust** **1.93+** with `wasm32-wasip2` (`rustup target add wasm32-wasip2`)
- **Go** **1.25.5+** (for `componentize-go` via `go tool`)
- **Python** **3.10+** and `pip install -r python/requirements.txt`
- **Node.js** **18+** (for the TypeScript component)

## Quick start

```bash
# One-time language tooling
rustup target add wasm32-wasip2
pip install -r python/requirements.txt
(cd typescript && npm install)

# Build all components, then run
spin build
spin up
```

Then try:

```bash
curl -s localhost:3000/rust/
curl -s localhost:3000/go/
curl -s localhost:3000/python/
curl -s localhost:3000/typescript/
```

For iterative development:

```bash
spin watch
```

## Project layout

```text
spin.toml          # application manifest + routes
rust/              # Rust HTTP component
go/                # Go HTTP component
python/            # Python HTTP component
typescript/        # TypeScript HTTP component
.github/workflows/ # CI + Akamai deploy
```

## Adding a component

```bash
spin add -t http-rust <name>
# or: http-go | http-py | http-ts
```

Then set a unique `[[trigger.http]]` route in `spin.toml`.

## IDE (Cursor / VS Code)

Workspace configs live in `.vscode/`:

| Action | How |
| --- | --- |
| Build | `Cmd/Ctrl+Shift+B` → **spin: build** |
| Run | Run and Debug → **Spin: Up** (builds first) |
| Live reload | Run and Debug → **Spin: Watch** |
| Debug TypeScript | Install **StarlingMonkey Debugger**, then F5 → **Debug: TypeScript** |
| Hit all routes | Terminal → Run Task → **spin: request all routes** |
| Deploy Akamai | Terminal → Run Task → **spin: aka deploy** (after `spin aka login`) |

Recommended extensions are listed in `.vscode/extensions.json` (Spin, StarlingMonkey, rust-analyzer, Go, Python).

## Deploy to Akamai Functions

Hosted edge deploy via the [`aka`](https://techdocs.akamai.com/akamai-functions/docs/aka-command-reference) Spin plugin.

### One-time setup

```bash
spin plugins update
spin plugins install aka -y
spin aka login
spin aka auth token create --name github-actions --expiration-days 90
```

Add the printed token as a GitHub Actions secret named **`SPIN_AKA_ACCESS_TOKEN`**:

```bash
gh secret set SPIN_AKA_ACCESS_TOKEN
```

After the first successful deploy, copy the app id from the CLI output (or `spin aka app list`) into an optional secret **`SPIN_AKA_APP_ID`** so later CI runs update the same app:

```bash
gh secret set SPIN_AKA_APP_ID
```

### Local deploy

```bash
spin build
spin aka deploy --no-confirm --create-name spin-polyglot
```

### CI deploy

On every push to `main`/`master`, [`.github/workflows/deploy-akamai.yml`](.github/workflows/deploy-akamai.yml) builds the app and runs `spin aka deploy` when `SPIN_AKA_ACCESS_TOKEN` is set. You can also run it manually from the Actions tab (**workflow_dispatch**).

> **Note:** Akamai Functions requires an allow-listed account. If you are not allow-listed yet, use the GCP path below.

## Deploy on Google Cloud (GKE + SpinKube)

Infrastructure lives in a sibling repo: [`spin-polyglot-infra`](https://github.com/koolkoda/spin-polyglot-infra) (Pulumi, region **`europe-west2`**).

```bash
cd ../spin-polyglot-infra
pulumi config set gcp:project YOUR_GCP_PROJECT_ID
pulumi up
./scripts/deploy-app.sh
```
