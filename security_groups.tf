# ==========================================
# 1. 기본 관리용 보안 그룹 
# ==========================================
resource "openstack_networking_secgroup_v2" "common_mgmt" {
  name        = "common-mgmt-sg"
  description = "[Essential] Allows SSH(22) and Ping(ICMP) for remote management."
}

# 1-1. SSH (22번 포트) 허용 규칙
resource "openstack_networking_secgroup_rule_v2" "mgmt_ssh" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 22
  remote_ip_prefix  = "0.0.0.0/0" # 모든 IP에서 접속 허용
  security_group_id = openstack_networking_secgroup_v2.common_mgmt.id
}

# 1-2. Ping (ICMP) 허용 규칙
resource "openstack_networking_secgroup_rule_v2" "mgmt_ping" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "icmp"
  remote_ip_prefix  = "0.0.0.0/0" # 모든 IP에서 핑 테스트 허용
  security_group_id = openstack_networking_secgroup_v2.common_mgmt.id
}


# ==========================================
# 2. 웹 서비스 전용 보안 그룹
# ==========================================
resource "openstack_networking_secgroup_v2" "web_traffic" {
  name        = "web-traffic-sg"
  description = "[Web] Open HTTP(80) and HTTPS(443) ports for web servers."
}

# 2-1. HTTP (80번 포트) 허용 규칙
resource "openstack_networking_secgroup_rule_v2" "web_http" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 80
  port_range_max    = 80
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.web_traffic.id
}

# 2-2. HTTPS (443번 포트) 허용 규칙
resource "openstack_networking_secgroup_rule_v2" "web_https" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 443
  port_range_max    = 443
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.web_traffic.id
}


# ==========================================
# 3. 데이터베이스 전용 보안 그룹 
# ==========================================
resource "openstack_networking_secgroup_v2" "db_access" {
  name        = "db-access-sg"
  description = "[DB] Secure MariaDB/MySQL port(3306). Only allows traffic from Web SG."
}

# 3-1. DB (3306번 포트) 허용 규칙
# 외부 세상(0.0.0.0/0)에 열지 않고, 오직 '웹 보안 그룹을 장착한 VM'의 요청만 받도록 체이닝!
resource "openstack_networking_secgroup_rule_v2" "db_mysql" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 3306
  port_range_max    = 3306
  remote_group_id   = openstack_networking_secgroup_v2.web_traffic.id # ★웹 보안 그룹 ID와 연동
  security_group_id = openstack_networking_secgroup_v2.db_access.id
}

# ==========================================
# 4. 보안 그룹 전역 공유 
# ==========================================

# 4-1. 기본 관리용 보안 그룹 공유
resource "openstack_networking_rbac_policy_v2" "share_mgmt" {
  object_type    = "security_group"
  object_id      = openstack_networking_secgroup_v2.common_mgmt.id
  action         = "access_as_shared"
  target_tenant  = "*" # 💡 target_project 대신 target_tenant 로 변경!
}

# 4-2. 웹 서비스 전용 보안 그룹 공유
resource "openstack_networking_rbac_policy_v2" "share_web" {
  object_type    = "security_group"
  object_id      = openstack_networking_secgroup_v2.web_traffic.id
  action         = "access_as_shared"
  target_tenant  = "*" # 💡 target_project 대신 target_tenant 로 변경!
}

# 4-3. 데이터베이스 전용 보안 그룹 공유
resource "openstack_networking_rbac_policy_v2" "share_db" {
  object_type    = "security_group"
  object_id      = openstack_networking_secgroup_v2.db_access.id
  action         = "access_as_shared"
  target_tenant  = "*" # 💡 target_project 대신 target_tenant 로 변경!
}