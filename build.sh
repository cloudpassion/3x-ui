#!/bin/bash
#
          x-ui stop

          cd ../REALITY
          git pull
          #go mod download

          cd ../Xray-core
          git pull
          #go mod download
          rm xray
          CGO_ENABLED=0 go build -o xray -trimpath -buildvcs=false -ldflags="-s -w -buildid=" -v ./main
          if [ $? -ne 0 ]; then
                  echo exit:xray-core
                  exit
          fi

          echo ex:$?

          cd ../3x-ui
          git pull
          #go mod download

          export CGO_ENABLED=1
          export GOOS=linux
          export GOARCH=amd64
          #${{ matrix.platform }}
          # Use Bootlin prebuilt cross-toolchains (musl 1.2.5 in stable series)
          #case "${{ matrix.platform }}" in
          #  amd64)
          BOOTLIN_ARCH="x86-64"
          #  arm64) BOOTLIN_ARCH="aarch64" ;;
          #  armv7) BOOTLIN_ARCH="armv7-eabihf"; export GOARCH=arm GOARM=7 ;;
          #  armv6) BOOTLIN_ARCH="armv6-eabihf"; export GOARCH=arm GOARM=6 ;;
          #  armv5) BOOTLIN_ARCH="armv5-eabi"; export GOARCH=arm GOARM=5 ;;
          #  386) BOOTLIN_ARCH="x86-i686" ;;
          #  s390x) BOOTLIN_ARCH="s390x-z13" ;;
          #esac
          TARBALL_BASE="https://toolchains.bootlin.com/downloads/releases/toolchains/$BOOTLIN_ARCH/tarballs/"
          TARBALL_URL=$(curl -fsSL "$TARBALL_BASE" | grep -oE "${BOOTLIN_ARCH}--musl--stable-[^\"]+\\.tar\\.xz" | sort -r | head -n1)
          echo ch:"$(basename "$TARBALL_URL")"
          #ls
          #ls "$(basename "$TARBALL_URL")"
          if [ 1 -eq 2 ]; then #[[ ! -d "$(basename "$TARBALL_URL")" ]]; then
          echo "Resolving Bootlin musl toolchain for arch=$BOOTLIN_ARCH (platform=${GOARCH})"
          [ -z "$TARBALL_URL" ] && { echo "Failed to locate Bootlin musl toolchain for arch=$BOOTLIN_ARCH" >&2; exit 1; }
          echo "Downloading: $TARBALL_URL"
          #cd /tmp
          curl -fL -sS -o "$(basename "$TARBALL_URL")" "$TARBALL_BASE/$TARBALL_URL"
          tar -xf "$(basename "$TARBALL_URL")"

          #cd -
          fi

          TOOLCHAIN_DIR=$(find . -type d -name "${BOOTLIN_ARCH}--musl--stable-*" | head -n1)
          export PATH="$(realpath "$TOOLCHAIN_DIR")/bin:$PATH"
          export CC=$(realpath "$(find "$TOOLCHAIN_DIR/bin" -name '*-gcc.br_real' -type f -executable | head -n1)")
          [ -z "$CC" ] && { echo "No gcc.br_real found in $TOOLCHAIN_DIR/bin" >&2; exit 1; }

          rm xui-release
          go build -ldflags "-w -s -linkmode external -extldflags '-static'" -o xui-release -v main.go
          if [ $? -ne 0 ]; then
                  echo exit:3x
                  exit
          fi

          echo ex:$?

          file xui-release
          ldd xui-release || echo "Static binary confirmed"

          mkdir -p x-ui
          cp xui-release x-ui/
          cp x-ui.service.debian x-ui/
          cp x-ui.service.arch x-ui/
          cp x-ui.service.rhel x-ui/
          cp x-ui.sh x-ui/
          mv x-ui/xui-release x-ui/x-ui
          mkdir -p x-ui/bin
          cd x-ui/bin

          rm -f geoip.dat geosite.dat
          wget -q https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geoip.dat
          wget -q https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geosite.dat
          wget -q -O geoip_IR.dat https://github.com/chocolate4u/Iran-v2ray-rules/releases/latest/download/geoip.dat
          wget -q -O geosite_IR.dat https://github.com/chocolate4u/Iran-v2ray-rules/releases/latest/download/geosite.dat
          wget -q -O geoip_RU.dat https://github.com/runetfreedom/russia-v2ray-rules-dat/releases/latest/download/geoip.dat
          wget -q -O geosite_RU.dat https://github.com/runetfreedom/russia-v2ray-rules-dat/releases/latest/download/geosite.dat

          #mv xray xray-linux-${GOARCH}
          pwd
          cp ../../../Xray-core/xray xray-linux-${GOARCH}

          cd ../..

          x-ui start

