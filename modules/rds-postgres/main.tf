resource "random_password" "db" {
  length           = 24
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "aws_db_subnet_group" "this" {
  name       = "dev-appdb"
  subnet_ids = var.subnet_ids
  tags       = var.tags
}

resource "aws_security_group" "db" {
  name        = "dev-appdb-sg"
  description = "Allow Postgres from EKS nodes"
  vpc_id      = var.vpc_id
  tags        = var.tags
}

# Allow inbound 5432 desde los SGs permitidos (node SG de EKS)
resource "aws_security_group_rule" "inbound_pg" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  security_group_id        = aws_security_group.db.id
  source_security_group_id = var.allowed_sg_ids[0]
}

resource "aws_security_group_rule" "egress_all" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = aws_security_group.db.id
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks  = ["::/0"]
}

resource "aws_db_instance" "this" {
  identifier                  = "dev-appdb"
  engine                      = "postgres"
  engine_version              = var.engine_version
  db_name                     = var.db_name
  username                    = "appuser"
  password                    = random_password.db.result
  instance_class              = var.instance_class
  allocated_storage           = var.allocated_storage_gb
  storage_type                = "gp3"
  storage_encrypted           = true                   # KMS administrado por AWS (sin CMK)
  db_subnet_group_name        = aws_db_subnet_group.this.name
  vpc_security_group_ids      = [aws_security_group.db.id]
  multi_az                    = false
  publicly_accessible         = false
  deletion_protection         = false
  backup_retention_period     = var.backup_retention_days
  auto_minor_version_upgrade  = true
  apply_immediately           = true
  skip_final_snapshot         = var.skip_final_snapshot
  copy_tags_to_snapshot       = true
  monitoring_interval         = 0

  tags = var.tags
}
