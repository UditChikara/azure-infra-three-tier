module "resource_group" {
    source = "../../module/resource_group"
    resource_group = var.resource_group
}

module "virtual_network" {
    depends_on = [module.resource_group]
    source = "../../module/azure_virtual_network"
    virtual_network = var.virtual_network
}

module "subnet" {
    depends_on = [module.virtual_network]
    source  = "../../module/azure_subnet"
    subnets = var.subnets
}

module "vm" {
    depends_on = [module.subnet]
    source  = "../../module/azure_vm"
    vm = var.vm
}