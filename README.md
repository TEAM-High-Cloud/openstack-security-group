# OpenStack Security Group Automation (IaC)

OpenStack 프라이빗 클라우드 환경에서 가상 머신들의 네트워크 보안 정책을 표준화하고 자동화하기 위한 Terraform 기반의 IaC repository

보안 그룹 템플릿 아키텍처를 설계하고 코드 기반으로 안정적으로 형상 관리합니다.

## 📂 Repository Structure

```text
openstack-security-group/
├── .gitignore          
├── provider.tf         # OpenStack API 연동 및 로그인 설정 (환경변수 방식)
├── security_groups.tf  
└── README.md           
```
## 🚀 개요 및 도입 배경
기존 방식의 문제점: 새로운 프로젝트 생성 시마다 Bash 스크립트로 default 보안 그룹을 강제 수정하여 관리용 포트(SSH, Ping)를 일괄 오픈했습니다. 이는 인프라의 형상 관리가 불가능하고, 사용자별로 정밀한 보안 정책을 제공하기 어려웠습니다.

개선 방향 (IaC 도입): Terraform을 도입하여 독립된 인프라 레포지토리를 구성했습니다. 순수한 default 상태는 보존하되, 플랫폼 사용자가 직관적으로 이해할 수 있는 Description이 포함된 3종의 전역 공유(Shared) 보안 그룹 템플릿을 코드로 선언하여 플랫폼 완성도와 보안성을 고도화했습니다.

## 🛡️ 보안 그룹 아키텍처 (Security Group Architecture)
사용자가 스카이라인(Skyline) 웹 포털에서 VM을 생성할 때, 목적에 맞게 적용할 수 있도록 3가지 공유 보안 그룹을 제공합니다.

1. common-mgmt-sg (기본 관리용 필수 그룹)
- 목적: 인프라 관리자 및 유저가 VM에 원격 접속하고 네트워크 상태를 점검하기 위한 에센셜 그룹입니다.

- 허용 규칙 (Inbound):

    - TCP 22: SSH 원격 보안 접속 허용 (0.0.0.0/0)

    - ICMP: Ping 네트워크 확인 트래픽 허용 (0.0.0.0/0)

2. web-traffic-sg (웹 서비스 전용 그룹)
- 목적: 유저가 웹 서버 또는 외부 API 백엔드 서비스를 구동하는 VM에 장착하는 그룹입니다.

- 허용 규칙 (Inbound):

    - TCP 80: 일반 HTTP 웹 트래픽 허용 (0.0.0.0/0)

    - TCP 443: 보안 HTTPS 웹 트래픽 허용 (0.0.0.0/0)

3. db-access-sg (데이터베이스 전용 보안 그룹)
- 목적: MariaDB, MySQL 등 핵심 데이터 db를 해커의 외부 무차별 대입 공격(Brute Force)으로부터 보호합니다.

- 보안 그룹 체이닝 (Chaining) 적용:

    - 외부 인터넷 전체(0.0.0.0/0)에 3306 포트를 개방하지 않고, 오직 web-traffic-sg를 장착한 백엔드 VM으로부터 오는 트래픽만 DB 접속을 허용하도록 동적 인프라 연동 정책을 수립했습니다.

- 허용 규칙 (Inbound):

    - TCP 3306: 오직 web-traffic-sg 리소스 ID 기반 필터링 허용

## 🛠️ 실행 방법 (How to Run)
오픈스택 제어 권한을 가진 터미널 환경에서 아래 순서대로 수행합니다.
```bash
# 0. 오픈스택 서버 터미널에서 git clone or pull
# (최초 실행 시)
git clone [https://github.com/본인_깃허브_ID/openstack-security-group.git](https://github.com/본인_깃허브_ID/openstack-security-group.git)
cd openstack-security-group
# (코드가 수정되었을 시)
git pull origin main

# 1. Kolla 가상환경 진입 및 오픈스택 어드민 환경변수 로드 (로그인 정보 탑재)
source /path/to/kolla-venv/bin/activate
source ~/highcloud-admin-openrc.sh

# 2. 테라폼 초기화 (오픈스택 공식 프로바이더 플러그인 자동 다운로드)
terraform init

# 3. 인프라 설계도 검증 및 생성될 리소스 미리보기
terraform plan

# 4. 설계도대로 오픈스택 API를 호출하여 3대 전역 공유 보안 그룹 실물 배포
terraform apply -auto-approve
```