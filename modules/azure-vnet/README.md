# azure-vnet

Network foundation for an Azure deployment of Presponsieve.

Creates a VNet with three purpose-built subnets: one for AKS nodes, one
delegated to the Postgres Flexible Server, and one dedicated to the Application
Gateway.

## The gateway subnet must be empty

Azure requires the Application Gateway to occupy a subnet with nothing else in
it. This module reserves a `/24` for that purpose. Do not put anything else
there.

## Private DNS ordering

Azure will not create a Flexible Server with private access unless the private
DNS zone already exists and is linked to the VNet. This module creates and links
it, and the database module takes it as an input, which produces the right
ordering without an explicit `depends_on`.

## Service endpoints

The node subnet carries service endpoints for Key Vault and Storage. Traffic to
those services stays on the Azure backbone instead of traversing a public
endpoint, which is both faster and much easier to explain in a security review.
