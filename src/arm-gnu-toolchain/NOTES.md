## 동작

[developer.arm.com](https://developer.arm.com)에서 `version`과 `target`에 맞는 tarball을 받아 `/opt/gcc-arm`에 풀고, `containerEnv`로 `PATH`에 추가합니다. `curl`과 `xz`가 없는 이미지에서는 먼저 설치합니다.

설치 경로는 `/opt/gcc-arm` 하나로 고정입니다. 요청한 버전이 이미 있으면 건너뛰고, 다른 버전이면 지운 뒤 새로 설치합니다. 따라서 **서로 다른 타깃을 동시에 설치할 수는 없습니다.**

`version`이 10.x 이하이면 URL 형식이 달라지므로(`gnu-a/.../gcc-arm-...`) 그에 맞춰 내려받습니다.

## 개발 및 테스트

```bash
make test-arm-gnu-toolchain    # test.sh + 시나리오 2개 + duplicate.sh
make unit-arm-gnu-toolchain    # test.sh만
```

시나리오별 옵션은 [test/arm-gnu-toolchain/scenarios.json](../../test/arm-gnu-toolchain/scenarios.json)에서 관리합니다. 테스트 실행 방법과 작성 규칙은 저장소 루트의 [CONTRIBUTING](../../CONTRIBUTING.md#testing-features)를 참조하세요.

## 배포

`src` 아래 feature 전체는 [release 워크플로우](../../.github/workflows/release.yaml)를 수동 실행하면 배포됩니다. 이것 하나만 올릴 때는:

```bash
devcontainer features publish --registry ghcr.io --namespace congealer/devcon-features ./src/arm-gnu-toolchain
```
