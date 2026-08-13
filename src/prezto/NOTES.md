## 동작

`$_REMOTE_USER_HOME/.zprezto`에 prezto를 clone하고, `runcoms` 아래 파일들을 홈 디렉토리에 심볼릭 링크로 겁니다. 기존 `.zshrc` 등이 있으면 `.prezto_backup`으로 백업합니다.

upstream `zpreztorc`는 `zpreztorc_org`로 보관하고 이 feature가 들고 있는 [zpreztorc](zpreztorc)로 교체합니다. 설정을 바꾸려면 그 파일을 고치면 됩니다.

이미 `~/.zprezto`가 있으면 아무것도 하지 않습니다.

## 개발 및 테스트

```bash
make test-prezto    # test.sh + duplicate.sh
make unit-prezto    # test.sh만
```

옵션이 없어 `scenarios.json`은 두지 않았습니다. 테스트 실행 방법과 작성 규칙은 저장소 루트의 [README](../../README.md#testing-features)를 참조하세요.

## 배포

`src` 아래 feature 전체는 [release 워크플로우](../../.github/workflows/release.yaml)를 수동 실행하면 배포됩니다. 이것 하나만 올릴 때는:

```bash
devcontainer features publish --registry ghcr.io --namespace congealer/devcon-features ./src/prezto
```
