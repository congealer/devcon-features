# Dev Container Features

이 repo는 custom devcontainer features를 공유하기 위한 것입니다.
[Devcontainer 공식 feature 저장소](https://containers.dev/features)에 없는 기능을 구현하기 위해 만들어졌습니다.
대부분의 feature는 Debian/Ubuntu와 같이 apt package manager system 위에서 작동하지만, `arm-gnu-toolchain`처럼 apt를 사용하지 않는 것들도 있습니다.

## Devcontainer에 feature 추가 방법
추가하려는 .devcontainer/devcontainer.json에 `feature` 항목에 필요한 feature의 URL과 옵션을 지정합니다. 아래는 `hello` feature를 사용하는 예시입니다.
각 feature들의 옵션은 `src` 아래 각 feature들의 `README.md`를 참조하세요.
```jsonc
{
    "image": "mcr.microsoft.com/devcontainers/base:ubuntu",
    "features": {
        "ghcr.io/devcontainers/feature-starter/hello:1": {
            "greeting": "Hello"
        }
    }
}
```

## Testing Features
이 항목은 개발자들을 위한 내용입니다. 모든 내용은 이 repo에 정의되어 있는 devcontainer 위에서 실행해야 합니다.

### Running Tests
테스트는 두 가지 방식으로 실행할 수 있습니다:

1. **기본 테스트만 실행 (`--skip-scenarios` 사용)**
```bash
devcontainer features test \
    --features color \
    --remote-user root \
    --skip-scenarios \
    --base-image mcr.microsoft.com/devcontainers/base:ubuntu \
    .
```
- `test.sh` 파일의 기본 테스트만 실행
- 빠르고 간단한 테스트가 필요할 때 사용
- 시나리오 설정이나 의존성을 신경쓰지 않아도 됨

2. **모든 시나리오 테스트 실행 (`--skip-scenarios` 미사용)**
```bash
devcontainer features test \
    --features color \
    --remote-user root \
    --base-image mcr.microsoft.com/devcontainers/base:ubuntu \
    .
```
- `test.sh` 기본 테스트와 함께 `scenarios.json`에 정의된 모든 시나리오를 실행
- 시나리오 예시:
  - `my_favorite_color_is_green`: common-utils 설치, octocat 사용자 설정
  - `gold`: gold 색상 테스트
  - `green`: green 색상 테스트
- 더 포괄적인 테스트가 필요할 때 사용
- 시나리오에 정의된 모든 의존성이 올바르게 설정되어야 함

테스트 파일들은 `test` 디렉토리에 있으며, 각 기능별로 자체 테스트 디렉토리를 가집니다. 예를 들어, `color` 기능의 테스트는 `test/color/test.sh`에 있습니다.

테스트는 devcontainer CLI와 함께 제공되는 테스트 라이브러리를 사용하며, `check`와 `reportResults` 같은 유용한 명령어를 제공합니다. 자세한 내용은 [공식 문서](https://github.com/devcontainers/cli/blob/main/docs/features/test.md)를 참조하세요.
