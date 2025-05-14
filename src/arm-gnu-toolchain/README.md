# ARM GNU Toolchain Feature

ARM GNU Toolchain은 ARM 아키텍처를 위한 공식 GNU 컴파일러 도구 모음입니다. 이 feature는 개발 컨테이너에 ARM GNU Toolchain을 설치하여 ARM 기반 프로젝트 개발을 지원합니다.

## 사용 방법

`devcontainer.json`에 다음과 같이 추가하세요:

```json
{
    "features": {
        "ghcr.io/congealer/devcon-features/arm-gnu-toolchain": {}
    }
}
```

### 옵션

다음과 같이 옵션을 지정할 수 있습니다:

```json
{
    "features": {
        "ghcr.io/congealer/devcon-features/arm-gnu-toolchain": {
            "version": "14.2.rel1",
            "target": "aarch64-none-elf"
        }
    }
}
```

사용 가능한 옵션:
- `version`: 설치할 ARM GNU Toolchain의 버전 (기본값: "14.2.rel1")
- `target`: 툴체인의 대상 아키텍처 (기본값: "aarch64-none-elf")

## 개발 및 테스트

### 테스트 실행

### 기본 테스트만 실행 (`--skip-scenarios` 사용)
```bash
devcontainer features test --features arm-gnu-toolchain --base-image mcr.microsoft.com/devcontainers/base:ubuntu --skip-scenarios .
```

## 모든 시나리오 테스트 실행 (`--skip-scenarios` 미사용)
```bash
devcontainer features test --features arm-gnu-toolchain --base-image mcr.microsoft.com/devcontainers/base:ubuntu .
```
시나리오별 옵션은 `test/arm-gnu-toolchain/scenarios.json`에서 관리합니다.

### Feature 푸시
```bash
devcontainer features publish --registry ghcr.io --namespace congealer/devcon-features ./src/arm-gnu-toolchain
``` 