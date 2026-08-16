
# Prezto (prezto)

Install prezto, a configuration framework for zsh, in the remote user's home directory. Installs zsh and git when the base image does not already carry them.

## Example Usage

```json
"features": {
    "ghcr.io/congealer/devcon-features/prezto:1": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| setZshAsDefault | Change the remote user's login shell to zsh? | boolean | true |
| extraZshrc | Extra lines to run at the end of ~/.zshrc, for shell integrations such as 'source <(fzf --zsh)'. | string | - |

## 동작

[prezto](https://github.com/sorin-ionescu/prezto)의 [공식 설치 절차](https://github.com/sorin-ionescu/prezto#installation)를 그대로 따릅니다 — clone, `runcoms` 심볼릭 링크, `chsh`.

추가로 하는 일:

- 심볼릭 링크 자리에 있던 기존 파일은 `.prezto_backup`을 붙여 백업합니다. 공식 절차는 그냥 실패합니다
- `zpreztorc`는 upstream 것 대신 이 feature가 들고 있는 [zpreztorc](zpreztorc)를 씁니다. 로드할 모듈이나 테마를 바꾸려면 그 파일을 고치면 됩니다
- `~/.zprezto`가 이미 있으면 clone과 링크는 건너뜁니다. 로그인 셸 설정은 그대로 적용됩니다

## 개발 및 테스트

```bash
make test-prezto    # test.sh + 시나리오 + duplicate.sh
make unit-prezto    # test.sh만
```

테스트 실행 방법과 작성 규칙은 저장소 루트의 [CONTRIBUTING](../../CONTRIBUTING.md#testing-features)를 참조하세요.

## 배포

`src` 아래 feature 전체는 [release 워크플로우](../../.github/workflows/release.yaml)를 수동 실행하면 배포됩니다. 이것 하나만 올릴 때는:

```bash
devcontainer features publish --registry ghcr.io --namespace congealer/devcon-features ./src/prezto
```


---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/congealer/devcon-features/blob/main/src/prezto/devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
