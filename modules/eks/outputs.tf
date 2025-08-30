##### Esto no se usa, se está usando un modulo ya creado para EKS, pero lo dejo aquí como referencia #####

output "cluster_name"     { value = aws_eks_cluster.this.name }
output "cluster_arn"      { value = aws_eks_cluster.this.arn }
output "cluster_endpoint" { value = aws_eks_cluster.this.endpoint }
output "cluster_ca"       { value = aws_eks_cluster.this.certificate_authority[0].data }
output "cluster_version"  { value = aws_eks_cluster.this.version }

output "node_role_arn"    { value = aws_iam_role.node.arn }
output "irsa_provider_arn"{ value = aws_iam_openid_connect_provider.irsa.arn }