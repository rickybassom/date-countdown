# date-countdown
[![Build Status](https://travis-ci.org/rickybassom/date-countdown.svg?branch=master)](https://travis-ci.org/rickybassom/date-countdown)

[![Get it on AppCenter](https://appcenter.elementary.io/badge.svg)](https://appcenter.elementary.io/com.github.rickybassom.date-countdown)

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
git clone https://github.com/rickybassom/date-countdown.git
cd date-countdown
meson build
cd build
ninja
```

## Installation

```sh
sudo ninja install
./com.github.rickybassom.date-countdown
```

## Debain build

```sh
dpkg-buildpackage -us -uc
sudo dpkg -i com.github.rickybassom.date-countdown_0.2.0_amd64.deb (or the equivalent)
```

## Flatpak
(currently without a repo)

### Build

```sh
flatpak-builder build-dir com.github.rickybassom.date-countdown.json
```

### Run

```sh
flatpak-builder --run build-dir com.github.rickybassom.date-countdown.json com.github.rickybassom.date-countdown
```
