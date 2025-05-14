# Prezto Feature

Prezto는 Zsh를 위한 프레임워크로, Zsh의 기능을 확장하고 사용자 경험을 향상시킵니다.

## 사용 방법

`devcontainer.json`에 다음과 같이 추가하세요:

```json
{
    "features": {
        "ghcr.io/congealer/devcon-features/prezto": {}
    }
}
```

## 개발 및 테스트

### 테스트 실행
기본 테스트만 구현되어 있습니다 (`--skip-scenarios` 사용).

```bash
devcontainer features test --features prezto --base-image mcr.microsoft.com/devcontainers/base:ubuntu --skip-scenarios .
```

### Feature 푸시
```bash
devcontainer features publish --registry ghcr.io --namespace congealer/devcon-features ./src/prezto
```
