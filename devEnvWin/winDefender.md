  1. DisableDefender.ps1 - 메인 스크립트 (옵션 2 & 3 선택 가능)
  2. RestoreDefender.ps1 - 복구 스크립트
  3. README.txt - 상세한 사용 가이드

  옵션 비교

  Option 2 - 영구 비활성화 (권장)
  - 레지스트리 + 서비스 비활성화
  - 안전하고 쉽게 복구 가능
  - 일반 개발 환경에 적합

  Option 3 - 완전 제거 (강력)
  - Option 2 + 파일 시스템 수준 제거
  - Defender 폴더 이름 변경으로 실행 완전 차단
  - 최대 성능, 재활성화 거의 불가능

  사용 방법

  # 1. PowerShell 관리자 권한으로 실행

  # 2. 실행 정책 변경
  Set-ExecutionPolicy Bypass -Scope Process -Force

  # 3. 스크립트 실행
  .\DisableDefender.ps1

  # 4. 옵션 선택 (2 또는 3)
  # 5. "YES" 입력하여 확인
  # 6. 재부팅

  복구 방법

  .\RestoreDefender.ps1

  주의: 개발/테스트 환경 전용입니다. 시스템이 보안 위협에 노출되므로 신중하게 사용하세요