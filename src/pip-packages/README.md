
# pip-packages (pip-packages)

Install pip packages with the Python interpreter already in the container (from the Python feature or a Python image), into its system site-packages rather than a venv or pipx. Also registers libpython with the dynamic linker when it cannot be found, so programs embedding Python (e.g. simulators loading cocotb) can load it.

## Example Usage

```json
"features": {
    "ghcr.io/congealer/devcon-features/pip-packages:1": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| packages | pip requirement specifiers, comma- or space-separated, e.g. 'cocotb==1.6.2,doit'. Empty installs nothing. | string | - |

## 동작

컨테이너에 이미 설치된 Python 인터프리터로 `pip install`을 실행해서, `packages`에 적은 패키지를 그 인터프리터의 system site-packages에 설치합니다. venv나 pipx는 쓰지 않습니다. 이 feature는 Python을 설치하지 않으므로, Python이 없으면 빌드가 실패합니다.

설치는 다음 순서로 진행됩니다.

1. **인터프리터 찾기**: Python feature가 설치한 `/usr/local/python/current/bin/python3`를 먼저 찾습니다. 없으면 PATH에 있는 `python3`를 씁니다.
2. **libpython 등록**: 링커가 그 인터프리터의 libpython(`.so`)을 찾지 못하면, 라이브러리 경로를 `/etc/ld.so.conf.d/python.conf`에 적고 `ldconfig`를 실행합니다. 이미 찾을 수 있으면 아무것도 하지 않습니다. Python이 shared libpython 없이 빌드되어 있으면 빌드 로그에 경고만 남기고 넘어갑니다.
3. **패키지 설치**: `packages`의 패키지를 pip로 설치합니다. `packages`가 비어 있으면 여기서 끝납니다.
4. **권한 맞추기**: pip가 새로 만든 파일의 소유자와 그룹을, 그 파일이 들어간 디렉터리(site-packages, `bin`)와 같게 맞춥니다. 디렉터리에 그룹 쓰기 권한이 있으면 새 파일에도 줍니다.

## 사용 예

### Python feature와 함께 쓰기

```jsonc
{
    "image": "mcr.microsoft.com/devcontainers/base:ubuntu",
    "features": {
        "ghcr.io/devcontainers/features/python:1": {
            "version": "3.12",
            "installTools": false,
            "enableShared": true
        },
        "ghcr.io/congealer/devcon-features/pip-packages:1": {
            "packages": "cocotb,pytest"
        }
    }
}
```

- Python feature의 `version`은 반드시 지정하세요. 지정하지 않으면 배포판 Python(`os-provided`)이 설치되는데, 최근 Debian과 Ubuntu의 배포판 Python은 pip 설치를 막아 두었습니다(PEP 668). 이 경우 빌드가 pip 오류로 실패합니다.
- `installTools: false`로 두면 Python feature가 pipx로 개발 도구(flake8, black 등)를 설치하지 않습니다.
- cocotb처럼 시뮬레이터 같은 다른 프로그램이 Python을 불러다 쓰는 경우에는 `enableShared: true`가 필요합니다. 이 옵션을 켜지 않으면 shared libpython이 만들어지지 않아서, 그런 프로그램이 Python을 불러오지 못합니다.
- 설치된 패키지는 Python feature가 정해 둔 권한을 따릅니다. 컨테이너 사용자와 `python` 그룹이 수정할 수 있습니다.

### Python 이미지에서 쓰기

```jsonc
{
    "image": "mcr.microsoft.com/devcontainers/python:3.12",
    "features": {
        "ghcr.io/congealer/devcon-features/pip-packages:1": {
            "packages": "cocotb,pytest"
        }
    }
}
```

- 이미지에 들어 있는 Python(`/usr/local/bin/python3`)에 설치합니다. Python 버전은 이미지 태그로 고릅니다.
- 이 이미지의 Python은 shared libpython이 이미 링커에 등록되어 있어서 따로 설정할 것이 없습니다.
- 설치된 패키지는 root 소유로 남습니다. 컨테이너 안에서 사용자가 `pip install`을 하면 `~/.local`에 설치됩니다.
- 이 이미지 위에 Python feature를 함께 쓰면, 이미지의 Python이 아니라 Python feature의 Python에 설치합니다.

### 패키지를 바꿀 때

이 feature는 컨테이너를 만들 때 패키지를 설치해 두는 용도입니다. 패키지를 추가하거나 바꾸려면 컨테이너 안에서 `pip install`을 하지 말고, `packages`를 고친 뒤 컨테이너를 다시 빌드하세요.

## 개발 및 테스트

```bash
make test-pip-packages    # test.sh + 시나리오 + duplicate.sh
make unit-pip-packages    # test.sh + duplicate.sh
```

이 feature는 Python을 설치하지 않으므로, 기본 테스트(`test.sh`, `duplicate.sh`)는 Python이 들어 있는 `mcr.microsoft.com/devcontainers/python` 이미지에서 돌립니다. Python feature와 함께 쓰는 경우는 시나리오로 확인합니다. 시나리오는 [test/pip-packages/scenarios.json](../../test/pip-packages/scenarios.json)에서 관리합니다. 테스트 실행 방법과 작성 규칙은 저장소 루트의 [CONTRIBUTING](../../CONTRIBUTING.md#testing-features)를 참조하세요.

## 배포

`src` 아래 feature 전체는 [release 워크플로우](../../.github/workflows/release.yaml)를 수동 실행하면 배포됩니다. 이것 하나만 올릴 때는:

```bash
devcontainer features publish --registry ghcr.io --namespace congealer/devcon-features ./src/pip-packages
```


---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/congealer/devcon-features/blob/main/src/pip-packages/devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
