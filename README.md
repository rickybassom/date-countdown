# date-countdown
[![Build Status](https://travis-ci.org/rickybas/date-countdown.svg?branch=master)](https://travis-ci.org/rickybas/date-countdown)

[![Get it on AppCenter](https://appcenter.elementary.io/badge.svg)](https://appcenter.elementary.io/com.github.rickybas.date-countdown)

A date countdown applet

![Screenshot](data/screenshot.png)

## Dependencies
These dependencies must be present before building

- `valac>= 0.22`
- `meson>=0.40.1`
- `gtk+-3.0`
- `granite`

## Build

```sh
git clone https://github.com/rickybas/date-countdown.git
cd date-countdown
meson build
cd build
ninja
```

## Installation

```sh
sudo ninja install
./com.github.rickybas.date-countdown
```

## Debain build

```sh
dpkg-buildpackage -us -uc
sudo dpkg -i com.github.rickybas.date-countdown_0.1.8_amd64.deb (or the equivalent)
```

## Flatpak
(currently without a repo)

### Build

```sh
flatpak-builder build-dir com.github.rickybas.date-countdown.json
```

### Run

```sh
flatpak-builder --run build-dir com.github.rickybas.date-countdown.json com.github.rickybas.date-countdown
```
