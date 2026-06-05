terraform {
  required_providers {
    openstack = {
      source  = "terraform-provider-openstack/openstack"
    }
  }
}

# 오픈스택 접속 설정 (환경변수 자동 로드 방식)
provider "openstack" {
  # 비밀번호, IP 주소 등을 여기에 적지 않고 비워둡니다.
  # 테라폼이 터미널의 오픈스택 환경변수를 알아서 읽어옵니다.
}