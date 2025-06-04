<!-- markdownlint-disable MD029 MD032 -->
# IDH - Infrastructure Design Handbook

This is a set of modules aimed to simplify and standardize the usage of terraform modules, providing a catalog of resources that can be created for each environment.

This means that most of the core variables usually required by the v4 modules are already set, and the user only needs to provide the specific variables for each module, thus avoiding common misconfigurations like:

- wrong sku sizing
- wrong replication configuration
- wrong subnet sizing

## Available modules

The modules available at the moment are [listed here](./LIBRARY.md)

This list is going to grow as we add more modules to the library, if you don't find what you are looking for, please as the maintainers to add it.

### How to add a new module

1. Create a new folder in the `IDH` folder with the `<module_name>` name
2. Create a new file named `<module_name>.yml` in the `00_product_configs` folder for each platform/env you want to support
3. Configure the module and the content of the `<module_name>.yml` accordingly, making sure to configure the structural values in the `yml`file and leaving what can/needs to be configured to the input variables
   - In your module use the following resource to read the `yml` file

```hcl
module "idh_loader" {
  source = "../01_idh_loader"

  product_name       = var.product_name
  env          = var.env
  idh_resource = var.idh_resource
  idh_category = "<module_name>"
}
```

You can then access your `yml`content using the following syntax: `module.idh_loader.idh_config.<my_property>`

4. Create a file named `resource_description.info` in the `<module_name>` folder, this file is going to be used to generate the documentation for the module.
   - **NB:** Here you can use placeholder valued from your `yml`file with the following syntax: `{yaml_property_name}`. Use the `_` separator to navigate the `yml` structure (dot-notation like)

5. Add the following section to your module `README.md`: 

```markdown
## IDH resources available

[Here's](./LIBRARY.md) the list of `idh_resource` available for this module
```
