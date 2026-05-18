FROM ubuntu:26.04

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
      ca-certificates curl git build-essential sudo \
      gnupg unzip locales \
      ripgrep fd-find jq zsh vim tmux stow \
      openssh-server \
 && rm -rf /var/lib/apt/lists/* \
 && locale-gen en_US.UTF-8

ENV LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8

RUN userdel -r ubuntu 2>/dev/null || true \
 && groupadd --gid 1000 dev \
 && useradd --uid 1000 --gid 1000 -m -s /bin/zsh dev \
 && echo 'dev ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/dev \
 && chmod 0440 /etc/sudoers.d/dev

USER dev
WORKDIR /home/dev

RUN curl https://mise.run | sh
ENV PATH=/home/dev/.local/share/mise/shims:/home/dev/.local/bin:${PATH}
RUN echo 'eval "$(mise activate zsh)"' >> ~/.zshrc \
 && echo 'export PROMPT="%m:%2~ $ "' >> ~/.zshrc \
 && echo 'eval "$(mise activate bash)"' >> ~/.bashrc

COPY --chown=dev:dev mise.toml /home/dev/.config/mise/config.toml
RUN mise trust ~/.config/mise/config.toml && mise install -y

# renovate: datasource=npm depName=@anthropic-ai/claude-code
ARG CLAUDE_CODE_VERSION=2.1.123
# renovate: datasource=npm depName=@openai/codex
ARG CODEX_VERSION=0.130.0
# renovate: datasource=npm depName=opencode-ai
ARG OPENCODE_VERSION=1.15.4
RUN npm install -g \
      @anthropic-ai/claude-code@${CLAUDE_CODE_VERSION} \
      @openai/codex@${CODEX_VERSION} \
      opencode-ai@${OPENCODE_VERSION} \
 && mise reshim

ARG DOTFILES_REF=main
ADD https://api.github.com/repos/kt3k/dotfiles/commits/${DOTFILES_REF} /tmp/dotfiles-version.json
RUN git clone --depth=1 --branch ${DOTFILES_REF} \
      https://github.com/kt3k/dotfiles.git /home/dev/dotfiles \
 && cd /home/dev/dotfiles \
 && stow -t /home/dev */

CMD ["zsh", "-l"]
