CLUSTERS := "arrove-staging arrove-production"

[private]
default:
  @just --list

# CRDのセットアップ
setup:
  .scripts/setup-crd.sh

# ビルド
build +dirs:
  .scripts/build.sh {{dirs}}

build-all:
  for cluster in {{CLUSTERS}}; do \
    just build ./$cluster/*; \
  done

# 文法チェック
check +dirs:
  #!/usr/bin/env bash
  set -euo pipefail
  .scripts/build.sh {{dirs}} | .scripts/check.sh

check-all:
  #!/usr/bin/env bash
  set -euo pipefail
  for cluster in {{CLUSTERS}}; do \
    just check ./$cluster/*; \
  done

# ビルド結果のdiffを見る TARGET 環境変数（デフォルト: main）で比較対象を設定
diff +dirs:
  .scripts/diff-to-old.sh {{dirs}}

diff-all:
  #!/usr/bin/env bash
  set -euo pipefail
  for cluster in {{CLUSTERS}}; do \
    just diff ./$cluster/*; \
  done
