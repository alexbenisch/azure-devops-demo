project            = "devops"
environment        = "dev"
location           = "westeurope"
kubernetes_version = "1.29"
vnet_address_space = ["10.20.0.0/16"]
aks_subnet_prefix  = "10.20.1.0/24"

# In der Demo leer lassen — sonst objectId einer echten AAD-Gruppe eintragen.
deployer_group_object_id = ""
admin_group_object_ids   = []

tags = {
  cost_center = "demo"
  owner       = "alex.benisch"
}
