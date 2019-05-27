# addr-plan test configuration

This directory is a Terraform configuration root that can be used to test
the main module in the parent directory.

To use it,
[`terraform-provider-testing`](https://github.com/apparentlymart/terraform-provider-testing)
must be available. At the time of writing this, the `testing` provider is not
available for automatic installation, so it must be built and installed
manually.

Once the `testing` provider is available, you can test the parent directory
module by working in this directory in the usual way:

- `terraform init` to prepare the working directory.
- `terraform apply` to run the tests.

The `testing_assertions` data source is used to check the results of the module.
If the results are not as expected then one or more of these data resources will
produce a test failure error when you run `terraform apply`.

Because the `addr-plan` module works entirely within Terraform, it does not
create anything that would need to be destroyed, and so it is not necessary
to run `terraform destroy`. Instead, you can just discard the `terraform.tfstate`
file when you are finished testing.
