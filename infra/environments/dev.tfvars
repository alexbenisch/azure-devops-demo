project            = "devops"
environment        = "dev"
location           = "westeurope"
kubernetes_version = "1.35"
vnet_address_space = ["10.20.0.0/16"]
aks_subnet_prefix  = "10.20.1.0/24"

# Quota-Anpassung für die Demo-Subscription (Total Regional vCPUs = 10,
# DSv5-Family-Quota = 0, B-Serie v1 nicht freigeschaltet). Referenz-Design nutzt
# Standard_D2s_v5; hier D2s_v3 (in der Sub erlaubt, DSv3-Quota = 10) mit kleinen
# Node-Counts, damit der Cluster ins 10-vCPU-Kontingent passt (max. 3 × 2 = 6 vCPU).
aks_vm_size         = "Standard_D2s_v3"
aks_system_node_min = 1
aks_system_node_max = 1
aks_user_node_min   = 1
aks_user_node_max   = 2

# In der Demo leer lassen — sonst objectId einer echten AAD-Gruppe eintragen.
deployer_group_object_id = ""
admin_group_object_ids   = []

tags = {
  cost_center = "demo"
  owner       = "alex.benisch"
}
