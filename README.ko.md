# BarCode

[English](README.md) · 한국어

macOS 메뉴바에서 바로 쓰는 TOTP(2FA) 앱입니다. 키 아이콘만 누르면 필요한 코드가 바로 보여요

<img width="293" height="412" alt="image" src="https://github.com/user-attachments/assets/faabdcbf-415f-4ec2-9494-2baa17ad6891" />

## 왜 만들었나요

30초마다 바뀌는 6자리 코드를 입력하려고 매번 폰을 꺼내고, Apple 암호 앱을 열고, 항목을 찾는 과정이 은근히 번거롭습니다.

BarCode는 그 코드를 지금 쓰는 Mac의 메뉴바에 올려둡니다. macOS Keychain에 저장하고, 원하면 Touch ID로 잠그고, 폰 잠금 해제나 앱 전환 없이 바로 확인할 수 있어요

## 기능

- 메뉴바에서 바로 접근, Dock 아이콘은 기본적으로 숨김
- TOTP(RFC 6238): 6자리, 30초 주기, SHA-1
- 코드마다 30초 카운트다운 링과 자동 갱신
- 코드를 클릭하면 클립보드에 복사되고 15초 뒤 자동으로 비움
- Touch ID 잠금은 선택 사항, 기본값은 꺼짐
- Base32 시드, `otpauth://` URL, QR 이미지, Google Authenticator `otpauth-migration://` 일괄 가져오기 지원
- 삭제 전 확인
- 로컬 전용, 네트워크 요청·분석·클라우드 동기화 없음

## 시스템 요구 사항

- macOS 13 Ventura 이상
- Apple Silicon / Intel 모두 지원하는 universal 빌드

## 설치

### Homebrew 권장

```bash
brew tap yim2627/tap
brew install --cask barcode
```

이게 전부입니다. cask가 설치할 때 Gatekeeper quarantine 속성을 제거해줘서 별도 경고 없이 바로 실행됩니다.

메뉴바에 나타나는 🔑 아이콘을 누르고 `+`로 계정을 추가하세요

### 수동 설치 DMG

1. **[최신 릴리스](../../releases/latest)** 페이지에서 `BarCode.dmg` 다운로드
2. DMG를 열고 `BarCode.app`을 `/Applications`로 드래그
3. ad-hoc 서명이라 macOS Sequoia 15 이상에서는 첫 실행이 차단될 수 있습니다. 아래 방법으로 한 번만 우회하면 됩니다:
   - **시스템 설정 → 개인정보 보호 및 보안**으로 이동한 뒤 아래쪽 **보안** 섹션 확인
   - *"BarCode" 사용이 차단되었습니다…* 옆 **그래도 열기** 클릭
   - 인증 후 BarCode를 다시 실행하고, 뜨는 창에서 **열기** 클릭
   - 터미널을 써도 됩니다: `xattr -d com.apple.quarantine /Applications/BarCode.app`
4. 메뉴바의 🔑 아이콘을 누르고 `+`로 계정 추가

> 첫 계정을 추가할 때 macOS가 키체인 비밀번호를 한 번 물어봅니다. **항상 허용**을 누르면 이후에는 다시 묻지 않습니다

## 코드 추가하는 법

필요한 건 **setup key**입니다. `JBSWY3DPEHPK3PXP` 같은 Base32 문자열이나 전체 `otpauth://` URL을 쓰면 됩니다

### 옵션 1: 사이트의 2FA 설정 화면에서 직접

사이트에서 QR 코드와 함께 "스캔할 수 없나요? 이 코드를 입력하세요" 같은 문구를 보여주면, 그 키를 BarCode의 **Seed key** 필드에 붙여넣으면 됩니다

### 옵션 2: Apple 암호 앱에서

1. **Passwords.app**을 열고 확인 코드가 있는 항목 찾기
2. 코드 우클릭 후 **설정 코드 복사**
   또는 QR을 보고 `otpauth://...` URL 복사
3. BarCode에서 `+`를 누르고 붙여넣기

URL 형식이면 발급처와 이름이 자동으로 채워집니다

### 옵션 3: `otpauth://` URL 붙여넣기

URL은 자동으로 파싱됩니다. 형식은 아래와 같습니다

```text
otpauth://totp/Issuer:account?secret=BASE32SECRET&issuer=Issuer&algorithm=SHA1&digits=6&period=30
```

`secret`만 필수이고 나머지는 선택입니다

### 옵션 4: 이미지에서 QR 읽기

`+`를 누른 뒤 **Read QR from image…**를 클릭하세요. QR이 들어 있는 스크린샷이나 저장된 이미지를 고르면 Apple Vision 프레임워크로 로컬에서 디코딩하고 시드 필드를 자동으로 채웁니다

단일 계정 QR이면 이름과 발급처도 같이 채워지고, Authenticator 마이그레이션 QR이면 바로 일괄 가져오기 미리보기로 넘어갑니다

### 옵션 5: Google Authenticator에서 일괄 가져오기

이미 폰의 Google Authenticator에 계정이 있다면 한 번에 옮길 수 있습니다

1. 폰의 **Google Authenticator**에서 메뉴(`⋮`) → **계정 전송** → **계정 내보내기** 선택, 인증 후 옮길 계정 선택
2. 앱이 **QR 코드**를 한 개 또는 여러 개 보여줍니다. 각 QR에는 `otpauth-migration://offline?data=…` URL이 들어 있고, 그 안에 여러 계정이 인코딩되어 있습니다
3. 스크린샷을 찍거나 AirDrop / 연속성 카메라로 Mac에 보내서 이미지 파일로 만들기
4. BarCode에서 `+` → **Read QR from image…** → 스크린샷 선택
5. BarCode가 그 QR에 든 모든 계정을 미리보기로 보여줍니다. **Import N**을 누르면 키체인에 일괄 저장
6. Google Authenticator가 계정을 여러 QR로 나눴다면 각각 반복

> 마이그레이션 URL에는 모든 시드가 평문으로 들어 있습니다. BarCode는 로컬에서만 파싱하니, 외부 사이트에 붙여넣거나 스크린샷을 공유하지 마세요. 미리보기에서 **Back**을 누르면 BarCode가 시드 필드의 URL을 자동으로 비워줍니다

## 보안 & 프라이버시

- **네트워크 접근 없음**: 외부 요청을 보내지 않습니다. 텔레메트리, 분석, 에러 리포팅도 없음
- **로컬 저장만**: 시드(TOTP secret)는 **macOS 로그인 키체인**에 암호화되어 저장됩니다. 계정 이름과 발급처는 일반 UserDefaults에 저장
- **클라우드 동기화 없음**: Mac마다 독립적으로 저장됩니다. 의도적인 선택입니다. 움직이는 부분이 적을수록 공격면도 작아집니다
- **Touch ID 잠금은 선택**: 기본값은 꺼짐입니다. Mac을 공유한다면 설정에서 켜세요. 화면 잠금이나 잠자기 상태에 들어가면 자동으로 잠깁니다
- **오픈 소스**: 누구나 코드를 확인할 수 있습니다. 빌드 파이프라인은 `.github/workflows/release.yml`에 있습니다

### 신뢰 경계

이 앱의 보안은 결국 **macOS 로그인 비밀번호**에 기대고 있습니다. Mac이 잠금 해제된 상태라면 물리적으로 접근할 수 있는 사람은 코드를 볼 수 있습니다. Touch ID는 접근에 한 단계를 더할 뿐이에요

Mac을 잠금 해제한 채 자리를 비우지 마세요

## ⚠️ 주의사항

> TOTP 시드는 **비밀번호와 동급**입니다. 똑같이 다뤄주세요

- **`otpauth://` URL을 절대 공유하지 마세요**: 시드가 들어 있습니다. 채팅, 이메일, GitHub 이슈, 스크린샷에 붙여넣지 말고 시드가 담긴 QR도 공개하지 마세요
- **시드는 별도로 백업하세요**: iCloud 동기화도, 내보내기 기능도 없습니다. Mac을 잃어버리거나 초기화하면 모든 2FA 접근을 잃을 수 있습니다. 사이트에서 2FA를 설정할 때 BarCode뿐 아니라 1Password 같은 비밀번호 관리자에도 시드를 함께 저장해두세요
- **DMG 출처를 확인하세요**: 이 저장소의 Releases에서만 받거나 직접 빌드하세요. 신뢰할 수 없는 DMG는 시드를 빼돌리도록 변조됐을 수 있습니다
- **회사 계정이나 중요한 2FA에는 감사할 수 없는 미서명 앱을 쓰지 마세요**: 업무 계정은 회사 정책을 따르세요

시드가 유출된 것 같다면 해당 사이트에서 2FA를 즉시 재설정하고 BarCode에서도 예전 항목을 삭제하세요

## FAQ

**왜 라이브 카메라 QR 스캐너가 없나요?**  
앱을 가볍게 유지하고 카메라 권한을 요구하지 않기 위해서입니다. QR이 화면에 있다면 스크린샷을 찍고 **Read QR from image…**로 로컬에서 디코딩하세요. 대부분의 설정 페이지는 QR 옆에 원본 키도 함께 보여줍니다

**그냥 Passwords.app 쓰면 안 되나요?**  
써도 됩니다. Passwords.app도 TOTP를 지원합니다. BarCode는 메뉴바에서 빠르게 보는 방법을 하나 더해줄 뿐이라 둘이 같이 써도 괜찮습니다

**재부팅해도 코드가 유지되나요?**  
네, 키체인은 재시작해도 유지됩니다

**JSON / Aegis 백업을 가져올 수 있나요?**  
아직은 안 됩니다. 지금은 한 번에 하나씩 수동으로 추가해주세요

**Apple과 관련이 있나요?**  
없습니다. "BarCode"는 "menu **Bar** + 2FA **Code**"를 합친 이름입니다

## 라이선스

MIT, 자세한 내용은 [LICENSE](LICENSE)를 참고하세요
