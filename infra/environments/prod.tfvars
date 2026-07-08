project            = "devops"
environment        = "prod"
location           = "westeurope"
kubernetes_version = "1.29"
vnet_address_space = ["10.30.0.0/16"]
aks_subnet_prefix  = "10.30.1.0/24"

# In Prod immer AAD-Gruppen statt Einzelnutzer.
deployer_group_object_id = "00000000-0000-0000-0000-000000000000"
admin_group_object_ids   = ["00000000-0000-0000-0000-000000000000"]

tags = {
  cost_center = "platform"
  owner       = "platform-team"
  criticality = "high"
}
