## on W12R2SUS run
Get-WmiObject -Namespace root\webadministration -List 
## on W8R2STD01 run
Get-WmiObject -Namespace root\webadministration -List -ComputerName W12R2SUS
## on server02 run
Get-WmiObject -Namespace root\webadministration -List -ComputerName W12R2SUS
## 
## changed in WMF 5
## but before that some namespaces (eg IIS & Cluster) required DCOM authentication
##  - actually encryption level
## on W8R2STD01 run
Get-WmiObject -Namespace root\webadministration -List -ComputerName W12R2SUS -Authentication PacketPrivacy
Get-WmiObject -Namespace root\webadministration -List -ComputerName W12R2SUS -Authentication 6
##
Get-WmiObject -Namespace root\webadministration -Class Server -ComputerName W12R2SUS -Authentication 6
##
## CIM cmdlets don't have the problem
Get-CimInstance -Namespace root\webadministration -ClassName Server -ComputerName W12R2SUS