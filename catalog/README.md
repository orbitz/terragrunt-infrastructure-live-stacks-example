# Vendored catalog

The units and modules that this repository uses, copied from
[terragrunt-infrastructure-catalog-example](https://github.com/gruntwork-io/terragrunt-infrastructure-catalog-example)
at commit `719b4d2c7a46c9f859e5d11321d35d137310542a`. The files are not changed. `LICENSE.txt` is the license of that
repository.

The stack files use them with a local source, `../../../catalog//units/<unit>`. The `//` marks the root of the
catalog, so the relative module source in each unit (`../..//modules/<module>`) resolves inside `catalog/`.

The copy makes all of the code that the Terragrunt version runs visible in this repository. Thus the next commits show
the complete change from Terragrunt to plain OpenTofu and Stategraph Orchestration.
