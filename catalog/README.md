# Vendored catalog

The units that this repository uses, copied from
[terragrunt-infrastructure-catalog-example](https://github.com/gruntwork-io/terragrunt-infrastructure-catalog-example)
at commit `719b4d2c7a46c9f859e5d11321d35d137310542a`. `LICENSE.txt` is the license of that repository. The stack files
use the units with a local source, `../../../catalog//units/<unit>`.

DEMO: these changes were made to the copy, so that the repository runs with no AWS account:

- The modules of the catalog are moved to `modules/stateful-lambda-service/` (`dynamodb-table` to `db`, `iam-role` to
  `role`, `lambda-service` to `service`). Each one has a `terraform_data` stand-in in place of the AWS resources.
- The handler source is moved from `units/js-lambda-stateful-service/src` to
  `modules/stateful-lambda-service/service/src`.
- The units find the modules and the handler source through the location of `root.hcl`.

With all of the code that the Terragrunt version runs in this repository, the next commit shows the complete change
from Terragrunt to plain OpenTofu and Stategraph Orchestration.
