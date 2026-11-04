# Example infrastructure-live for Stategraph

This repository describes a small stateful serverless service (an AWS Lambda function, a DynamoDB table, and an IAM role) to two environments, `non-prod` and `prod`. It is plain OpenTofu. [Stategraph Orchestration](https://stategraph.com/docs/orchestration) plans and applies it from pull requests, and [Stategraph](https://stategraph.com/docs/infrastructure-as-a-database) keeps the state.

> [!IMPORTANT]
> This is a demo version. The modules do not create AWS resources. Each module has a `terraform_data` resource in place of the AWS resource, and its outputs have the same shape as the outputs of the real resource. Thus you do not need an AWS account or AWS credentials, and OpenTofu downloads no providers.

The repository started as Gruntwork's [terragrunt-infrastructure-live-stacks-example](https://github.com/gruntwork-io/terragrunt-infrastructure-live-stacks-example). It was ported from Terragrunt Stacks to plain OpenTofu and a `.stategraph/config.yml` file. [Terragrunt to Stategraph](#terragrunt-to-stategraph) shows where each Terragrunt feature went.

> [!NOTE]
> This code is for demonstration only. It is not production-ready.

## Repository contents

```tree
.stategraph/config.yml                  Orchestration configuration: engine, environments, order, packaging
.github/workflows/terrateam.yml         The workflow that Orchestration starts on GitHub Actions
environments/
  non-prod/                             Root module: the complete non-prod environment
  prod/                                 Root module: the complete prod environment
modules/stateful-lambda-service/        Local modules, one per component. Demo stand-ins for the catalog modules.
  db/                                   DynamoDB table
  role/                                 IAM role that the function uses to read and write the table
  service/                              Lambda function, and its handler source in src/
scripts/package-lambda.py               Packages the handler source into handler.zip
```

**One root module per environment.** Root modules separate only the environments. Each environment root module calls the three component modules and wires them together directly (`module.role` gets `module.db.arn`, and so on), so OpenTofu orders them in one plan. The two environment root modules differ only in the resource names. Their account ID and region come from `.stategraph/config.yml`.

A large root module is not a problem with Stategraph. Stategraph plans only the resources that a change reaches, so a change to one component does not plan the full environment.

The Terragrunt version used the OpenTofu modules of the [terragrunt-infrastructure-catalog-example](https://github.com/gruntwork-io/terragrunt-infrastructure-catalog-example) repository. In this demo, the modules in `modules/stateful-lambda-service/` have `terraform_data` stand-ins for them. Each stand-in keeps the same inputs and outputs, so you can put the catalog module back without a change to the environment root modules.

## How Orchestration runs this repository

When a pull request changes an environment, a module, the handler source, or the packaging script, Orchestration plans the affected environments and comments the plan on the pull request.

- **Environments.** Each environment is a stack in `.stategraph/config.yml`. The stack sets the account ID and the region as `TF_VAR_*` environment variables for the runs of that environment. The demo modules use them only to make the ARNs.
- **prod after non-prod.** When a pull request changes both environments, prod applies only after non-prod is applied. The Terragrunt version did not have this order.
- **State.** The `stategraph` engine runs `stategraph tf plan` and `stategraph tf apply`, which run OpenTofu and keep the state in Stategraph. There is no S3 bucket and no backend block.
- **Modules.** The indexer is on in `.stategraph/config.yml`. It reads the `module` blocks of the environment root modules. A change to a `*.tf` file in `modules/` thus plans each environment, and the module directory itself never plans. The indexer adds only `*.tf` files. Thus `file_patterns` lists the handler source and the packaging script.
- **Packaging.** Before each plan and apply, a `run` step makes `handler.zip` from `modules/stateful-lambda-service/service/src`. The zip is the same for the same source, so the plan and the apply, which run in different CI jobs, use the same bytes. The demo function keeps the hash of the zip, so a change to the handler source shows in the plan.

To plan again, comment `stategraph plan`. To apply, comment `stategraph apply`. To limit a command to one environment, add a tag query, for example `stategraph plan dir:environments/non-prod`.

## Setup

1. Connect the repository to Stategraph Orchestration, on [Stategraph Cloud](https://stategraph.com/docs/get-started/quickstart/cloud) or a [self-hosted](https://stategraph.com/docs/get-started/quickstart/self-hosted) server. Put `.github/workflows/terrateam.yml` on the default branch before you open the first pull request.

2. Optional: change the account IDs in the `stacks` section of `.stategraph/config.yml`. The demo uses them only in the ARNs of the demo resources.

3. Install the [Stategraph CLI](https://stategraph.com/docs/infrastructure-as-a-database/setup), and export `STATEGRAPH_API_BASE`, `STATEGRAPH_API_KEY`, and `STATEGRAPH_TENANT_ID`.

4. Create a Stategraph state for each environment, and attach the Lambda package to it. Stategraph must know that the function reads `handler.zip`, so that a changed handler is part of the plan:

   ```bash
   for env in non-prod prod; do
     (cd "environments/$env" &&
       stategraph states create --name "stateful-lambda-service-$env" &&
       stategraph config files attach --workspace default --address 'module.lambda_service.*' handler.zip)
   done
   ```

   Commit the two `environments/<env>/stategraph.json` files that these commands write. The `stategraph` engine stops a run when an environment has no `stategraph.json`.

5. Add these GitHub Actions secrets:

   | Secret | Value |
   | --- | --- |
   | `STATEGRAPH_API_BASE` | The URL of your Stategraph server |
   | `STATEGRAPH_API_KEY` | An API key that can plan and apply the two states |
   | `STATEGRAPH_TENANT_ID` | Your tenant ID (`stategraph info` shows it) |

6. Optional: to add a prefix to all resource names, set the GitHub Actions variable `TF_VAR_APP_PREFIX`. The runner gives it to OpenTofu as the `app_prefix` variable. (This was the `EX_APP_PREFIX` environment variable in the Terragrunt version.)

7. Open a pull request that changes the infrastructure, and read the plan comment.

## Reading the outputs

Each environment has three outputs, `db`, `role`, and `lambda_service`, with the outputs of each component. This is the same shape as `terragrunt stack output`. Stategraph keeps them in the `outputs` table. To read them:

```bash
cd environments/non-prod
stategraph sql query "SELECT name, value FROM outputs WHERE state_id = '$(stategraph states resolve)'"
```

The `function_url` key of the `lambda_service` output has the form of a real Lambda function URL, but no function is behind it.

## Terragrunt to Stategraph

| Terragrunt | Here |
| --- | --- |
| `terragrunt.stack.hcl`, one per environment | One root module per environment, `environments/<env>/` |
| `unit` blocks, generated into `.terragrunt-stack/` | `module` blocks in the environment root module |
| Catalog `units/*` (`terragrunt.hcl`) | Local modules in `modules/stateful-lambda-service/`, with `terraform_data` stand-ins for the catalog modules (demo) |
| `values` and unit `inputs` | Module arguments |
| `autoinclude { dependency { ... } }` and `mock_outputs` | Direct references between modules in one root module (`module.db.arn`). OpenTofu orders them. |
| `account.hcl`, `region.hcl`, `find_in_parent_folders` | One stack per environment in `.stategraph/config.yml`, with `TF_VAR_*` variables |
| `generate "provider"` | Not needed. The demo modules use no provider. |
| `remote_state` (S3) and `--backend-bootstrap` | The `stategraph` engine and `stategraph.json`. No bucket. |
| `before_hook "package"` and `mark_glob_as_read` | A `run` step with `scripts/package-lambda.py`, `file_patterns` that include `src/**`, and an attached file in `stategraph.json` |
| `terragrunt run --all plan` / `apply` | Pull request plans, and the `stategraph plan` / `stategraph apply` comments |
| `terragrunt stack output` | The `db`, `role`, and `lambda_service` outputs, read with `stategraph sql query` |
| `catalog` block and `terragrunt catalog` | Not ported |
| `mise.toml` `opentofu` version | `engine.tf_version` in `.stategraph/config.yml` (also kept in `mise.toml` for local use) |

The Terragrunt version declared its `dependency` blocks but did not give their outputs to the units: the role had no `policy`, and the function had no `iam_role_arn` and no `DYNAMODB_TABLE`. This port gives those values, as the catalog's own example stack does.

## What to do with `.terraform.lock.hcl` files

The demo modules use no provider, so OpenTofu does not create `.terraform.lock.hcl` files. When you use real providers, commit these files in your own repositories. They make sure that the same provider versions are used each time.

## Local tools

To install the pinned OpenTofu version, install [mise](https://mise.jdx.dev/) and run:

```bash
mise install
```
