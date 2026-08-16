# Dev Container Features

이 repo는 custom devcontainer features를 공유하기 위한 것입니다.
[Devcontainer 공식 feature 저장소](https://containers.dev/features)에 없는 기능을 구현하기 위해 만들어졌습니다.
대부분의 feature는 Debian/Ubuntu와 같이 apt package manager system 위에서 작동하지만, `arm-gnu-toolchain`처럼 apt를 사용하지 않는 것들도 있습니다.

## Features

| Feature | 설명 |
|---|---|
| [prezto](src/prezto/) | zsh 설정 프레임워크 [prezto](https://github.com/sorin-ionescu/prezto)를 설치하고 로그인 셸을 zsh로 바꿉니다 |
| [arm-gnu-toolchain](src/arm-gnu-toolchain/) | ARM 애플리케이션을 빌드하기 위한 arm-gnu-toolchain을 설치합니다 |
| [color](src/color/) | 좋아하는 색을 알려줍니다 |
| [hello](src/hello/) | hello world |

**옵션과 동작은 각 feature의 링크를 보세요.** 이 표에는 요약만 둡니다.

## Devcontainer에 feature 추가 방법

추가하려는 `.devcontainer/devcontainer.json`의 `features` 항목에 필요한 feature의 URL과 옵션을 지정합니다. 아래는 `prezto` feature를 사용하는 예시입니다.

```jsonc
{
    "image": "mcr.microsoft.com/devcontainers/base:ubuntu",
    "features": {
        "ghcr.io/congealer/devcon-features/prezto:1": {
            "extraZshrc": "(( $+commands[fzf] )) && source <(fzf --zsh)"
        }
    }
}
```

편집기에서 feature 위에 마우스를 올리면 이름과 설명, 그리고 그 feature의 문서로 가는 링크가 뜹니다.

### 버전 고정

`:1`은 메이저 버전 태그입니다. publish하면 `1`, `1.0`, `1.0.0`, `latest`가 함께 올라가므로, 소비자는 `:1`로 호환되는 업데이트를 계속 받거나 `:1.0.0`으로 완전히 고정할 수 있습니다.

## 개발

테스트 실행, 문서 생성, 배포 등 이 저장소를 고칠 때 필요한 내용은 [CONTRIBUTING.md](CONTRIBUTING.md)에 있습니다.
