resource "azurerm_resource_group" "rgs" {
    for_each = var.resource_group
    name = each.value.name
    location = each.value.location
}